package POE::Component::Server::AsyncEndpoint;

use warnings;
use strict;
our @EXPORT = ( );
use base qw(Exporter);
use vars qw($VERSION);
$VERSION = '0.10';


use POE;
use POE::Wheel::Run;
use POE::Component::IKC::Server;
use POE::Component::Server::AsyncEndpoint::Config;
use POE::Component::Server::AsyncEndpoint::Endpoints;
use POE::Component::Logger;
use POE::Component::MessageQueue;
use POE::Component::MessageQueue::Storage::DBI;
use POE::Component::MessageQueue::Storage::FileSystem;
use Carp qw(croak);
use Switch;

use constant SHUTDOWN_SIGNALS => ('TERM', 'HUP', 'INT');

autoflush STDOUT;

sub run {
  POE::Kernel->run();
  exit(0);
}

sub new {
  my $package = shift;
  croak "$package requires an even number of parameters" if @_ & 1;
  my %args = @_;
  my $self = bless ({}, $package);

  $args{Alias} = 'AES-Master' unless $args{Alias};

  $self->{CONFIG} = \%args;
  $self->{alias} = $args{Alias};

  # init server configuration
  $self->{config} = POE::Component::Server::AsyncEndpoint::Config->init();

  # get endpoint filenames
  $self->{endpoints} = [POE::Component::Server::AsyncEndpoint::Endpoints->init()];

  # spawn the logger
  POE::Component::Logger->spawn(
    ConfigFile => $self->{config}->aes_log_conf,
    Alias      => 'MAIN-Logger'
  );

  # spawn the MQ Server
  my $mq = POE::Component::MessageQueue->new(
    port     => $self->{config}->aes_port,
    address  => $self->{config}->aes_addr,
    hostname => $self->{config}->aes_host,
    logger_alias => 'MAIN-Logger',
    storage => POE::Component::MessageQueue::Storage::FileSystem->new(
      info_storage =>  POE::Component::MessageQueue::Storage::DBI->new(
        dsn => $self->{config}->mqdb_dsn,
        username => $self->{config}->mqdb_username,
        password => $self->{config}->mqdb_password,
      ),
      data_dir => $self->{config}->mqdb_data_dir,
    ),
  );

  $self->{mq} = $mq;

  # IKC Server
  POE::Component::IKC::Server->spawn(
    address => $self->{config}->aes_ikc_addr,
    port => $self->{config}->aes_ikc_port,
    name => "IKCS",
  );


  # AES main session
  POE::Session->create(
    object_states => [
      $self => {
        _start => '_aes_start',
        shutdown => 'shutdown_start',
        _stop => '_aes_stop',
      },
      $self => [ qw( init_endpoints endpoint_stdout endpoint_stderr
                     child_sig child_dead endpoint_restart
                     endpoint_start endpoint_stop endpoint_wdog
                     shutdown_complete ikc_event) ],
    ],
    (ref $args{options} eq 'HASH' ? (options => $args{options}) : () ),
  );


  POE::Kernel->post('MAIN-Logger', 'alert', "AES Initialize complete, ready to run.\n");
  return $self;

}

# only for debug
sub child_sig {
 $_[KERNEL]->post('MAIN-Logger','debug',"CHLD:".$_[ARG1]."\n");
}


sub _aes_start {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  $kernel->alias_set($self->{alias});
  $kernel->alias_set('AES_SESSION'); # for IKC
  $kernel->sig(CHLD => 'child_sig');
  foreach my $signal ( SHUTDOWN_SIGNALS ){
    $kernel->sig($signal => 'shutdown');
  }
  $kernel->yield('init_endpoints');
  $kernel->post('IKC', 'publish', 'AES_SESSION', ['ikc_event']);
}

sub _aes_stop {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
}


sub init_endpoints {
  my ($kernel, $session, $self) = @_[KERNEL, SESSION, OBJECT];
  $kernel->post('MAIN-Logger', 'alert', "Initializing endpoints...\n");
  my ($name, $pname, $wid, $pid) = undef;
  foreach my $ep (@{$self->{endpoints}}) {
    $name = $ep->{name};
    $pname = $ep->{pname};
    if($ep->{start} == 1){
      $ep->{wheel} = &new_wheel($pname);
      $ep->{stat} = EP_STAT_OK;
      $wid = $ep->{wheel}->ID;
      $pid = $ep->{wheel}->PID;
      $kernel->post('MAIN-Logger', 'alert', 
                    "Started EP: $name in wheel id: $wid and PID: $pid\n");
    }
    else{
      $ep->{stat} = EP_STOPPED;
      $kernel->post('MAIN-Logger', 'alert',
                    "EP: $name not started at AES init per EP config\n");
    }

  }
  # reset watchdog
  $kernel->delay_set('endpoint_wdog', $self->{config}->aes_cwdg);
}


# IKC messaging with Endpoints
# FUTURE: get rid of "Endpoint Protocol" and replace with
# more IKC published methods
sub ikc_event {
  my ($kernel, $self, $input) = @_[KERNEL, OBJECT, ARG0];

  $kernel->post('MAIN-Logger', 'debug', "ikc_event input : $input\n");

  my ($cmd, $pid, $msg) = split /\|/,$input;

  # Simple Endpoint Protocol via IKC
  switch($cmd){
    # status update
    case "CASTAT" {
      my $newstat = EP_STAT_FA;
      if ($msg eq "OK") {
        $kernel->post(
          'MAIN-Logger',
          'notice',
          "Enpoint with PID $pid is OK\n"
        );
        $newstat = EP_STAT_OK;
      }
      if ($msg eq "FAIL") {
        $kernel->post(
          'MAIN-Logger',
          'notice',
          "Enpoint with PID $pid is alive but in FAIL state\n"
        );
      }
      # update endpoint status
      foreach my $ep (@{$self->{endpoints}}) {
        next if $ep->{stat} == EP_STOPPED;
        my $wheel = $ep->{wheel};
        if ($wheel->PID == $pid) {
          $ep->{stat} = $newstat;
          $ep->{retries} = 0;
        }
      }
    }
    # log to main logger
    case "LOGIT" {
      my ($log_alias, $log_level, $log_msg) = split /\;;/,$msg;
      $kernel->post('MAIN-Logger', $log_level, "$log_alias: ".$log_msg);
    }
  }
}


# any STDERR blurb gets logged
sub endpoint_stdout {
  my ($kernel, $input, $wheel_id) = @_[KERNEL, ARG0, ARG1];
  $kernel->post('MAIN-Logger', 'alert', "ERROR: Enpoint in wheel $wheel_id wrote to STDOUT: $input\n");
}

# any STDERR blurb gets logged
sub endpoint_stderr {
  my ($kernel, $input, $wheel_id) = @_[KERNEL, ARG0, ARG1];
  $kernel->post('MAIN-Logger', 'alert', "ERROR: Enpoint in wheel $wheel_id wrote to STDERR: $input\n");
}


# mark dead EP as failed
sub child_dead {
  my ($kernel, $self, $wheel_id) = @_[KERNEL, OBJECT, ARG0];
  foreach my $ep (@{$self->{endpoints}}) {
    next if $ep->{stat} == EP_STOPPED;
    if ($ep->{wheel}->ID == $wheel_id) {
      return if $self->{shutdown};
      my $pid = $ep->{wheel}->PID;
      $kernel->post('MAIN-Logger', 'alert', "Set FAIL on EP of dead child wheel id:$wheel_id PID: $pid\n");
      $ep->{stat} = EP_STAT_FA;
      $ep->{retries} = 0;
    }
  }

  # delayed EP restart procedure
  $_[KERNEL]->delay_set('endpoint_restart',$self->{config}->aes_rstc,$_[ARG0]);

}

# Cleans the old wheel and starts a fresh endpoint in it's place. This
# sub is delayed (see main AES session) because the endpoint could be
# dying emmediately and hogging the whole system in an infinite loop.
sub endpoint_restart {

  my ($kernel, $self, $wheel_id) = @_[KERNEL, OBJECT, ARG0];

  $kernel->post('MAIN-Logger', 'debug', "endpoint_restart()\n");

  # find the wheel and restart endpoint
  foreach my $ep (@{$self->{endpoints}}) {
    next if $ep->{stat} == EP_STOPPED;
    my $wheel = $ep->{wheel};
    my $name = $ep->{name};
    my $pname = $ep->{pname};
    if ($wheel->ID == $wheel_id) {
      $ep->{wheel} = &new_wheel($pname);
      $ep->{stat} = EP_STAT_OK;
      $kernel->post(
        'MAIN-Logger',
        'alert',
        "Restarting EP: $name in wheel ".
          $ep->{wheel}->ID." with new PID:".$ep->{wheel}->PID."\n");
    }
  }
}


# starts a stopped endpoint
sub endpoint_start {
  my ($kernel, $self, $name) = @_[KERNEL, OBJECT, ARG0];

  $kernel->post('MAIN-Logger', 'debug', "endpoint_start()\n");

  foreach my $ep (@{$self->{endpoints}}) {
    if ($ep->{name} eq $name) {
      if($ep->{stat} == EP_STOPPED){
        $ep->{wheel} = &new_wheel($ep->{pname});
        $ep->{stat} = EP_STAT_OK;
        $kernel->post(
          'MAIN-Logger', 'alert', 
          "Restarting EP: $name in wheel ".
          $ep->{wheel}->ID." with new PID:".$ep->{wheel}->PID."\n");
      }
      else{
        $kernel->post(
          'MAIN-Logger', 'alert',
          "Cannot start EP: $name with stat".$ep->{stat}."\n");
      }
    }
  }
}

# stop an endpoint in runtime
sub endpoint_stop {
  my ($kernel, $self, $name) = @_[KERNEL, OBJECT, ARG0];

  $kernel->post('MAIN-Logger', 'debug', "endpoint_stop()\n");

  foreach my $ep (@{$self->{endpoints}}) {
    my $wheel = $ep->{wheel};
    if ($ep->{name} eq $name) {
      if($ep->{stat} == EP_STAT_OK){
        $ep->{stat} = EP_STOPPED;
        $wheel->kill($SIG{TERM});
        $kernel->post(
          'MAIN-Logger', 'alert',
          "Stopping EP: $name in wheel ".
          $ep->{wheel}->ID." with new PID:".$ep->{wheel}->PID."\n");
      }
      else{
        $kernel->post(
          'MAIN-Logger', 'alert',
          "Cannot stop EP: $name with stat".$ep->{stat}."\n");
      }
    }
  }
}


# spawns new wheel
sub new_wheel {
  my $pname = shift;
  my $wheel = POE::Wheel::Run->new(
    Program => $pname,
    StdoutEvent => 'endpoint_stdout',
    StderrEvent => 'endpoint_stderr',
    CloseEvent => 'child_dead',
  );
  return $wheel;
}

# the endpoint watchdog
sub endpoint_wdog {
  my ($kernel, $self) = @_[KERNEL, OBJECT];

  return if $self->{shutdown};

  # watchdog blurb is notice level
  $kernel->post('MAIN-Logger', 'notice', "--- ENTERING Endpoint Watchdog ---\n");

  foreach my $ep (@{$self->{endpoints}}) {
    my $stat    = \$ep->{stat};
    next if $$stat == EP_STOPPED;

    my $name    = $ep->{name};
    my $pname   = $ep->{pname};
    my $retries = \$ep->{retries};
    my $wheel   = $ep->{wheel};
    my $pid     = $wheel->PID;

    $$retries++;

    # debug
    $kernel->post('MAIN-Logger', 'debug', "$pname RETRIES: $$retries STATUS:$$stat\n");

    # time to kill non-answering process
    if (
      ($$retries > $self->{config}->aes_wdgr) and
        ($$stat == EP_STAT_WA)
      ) {
      # TODO: probable portability issue to non-unix
      # systems. Not a prority for me right now, but a helping
      # hand on non-unix machine is very welcome indeed.

      # this blurb is surely critical
      my $wid = $wheel->ID;
      $kernel->post(
        'MAIN-Logger',
        'alert',
        "------------------------------------------------------------\n".
        "WATCHDOG ALERT: The Watchdog has been forced to kill process\n".
        "with PID: $pid on wheel id: $wid, because it never answered\n".
        "to STAT requests. EP Name: $pname\n".
        "------------------------------------------------------------\n"
      );

      # set EP to FAIL status
      $$stat = EP_STAT_FA;
      $$retries = 0;

      # signal the child to die
      $wheel->kill($SIG{KILL});

    }
    else {
      # request for status once again
      $$stat = EP_STAT_WA;
      $kernel->post( 'IKC', 'call', 'poe://'.$wheel->PID.'_IKCC/CA_SESSION/aesstat', undef, 'poe:ikc_event' );
    }
  }

  # this watchdog blurb is debug level
  $kernel->post('MAIN-Logger', 'debug', "--- LEAVING Endpoint Watchdog ---\n");

  # reset watchdog
  $kernel->delay_set('endpoint_wdog', $self->{config}->aes_cwdg);

}


# shutdown stage 1
sub shutdown_start {
  my ($kernel, $self) = @_[KERNEL, OBJECT];
  $kernel->post('MAIN-Logger', 'alert', "Starting shutdown sequence...\n");
  $self->{shutdown} = 1;

  my ($pid, $wid, $wheel, $pname, $stat) = undef;
  # ask endpoints to exit kindly
  foreach my $ep (@{$self->{endpoints}}) {
    $pname = $ep->{pname};
    $stat  = $ep->{stat};
    unless($stat == EP_STAT_NA or $stat == EP_STOPPED){
      $wheel = $ep->{wheel};
      $pid = $wheel->PID;
      $wid = $wheel->ID;
    }
    else{
      $wheel = undef;
    }

    if(defined $wheel){
      $kernel->post(
        'MAIN-Logger','alert',
        "SENDING TERM TO PID: $pid on wheel id: $wid Name: $pname\n"
      );
      $wheel->kill($SIG{TERM});
    }
  }

  $kernel->delay_set('shutdown_complete', 3);
}

# shutdown everything else
sub shutdown_complete {
  my ($kernel, $self) = @_[KERNEL, OBJECT];

  $kernel->post('MAIN-Logger', 'alert', "Completing shutdown sequence...\n");

  $self->{mq}->shutdown();
  $self->{mq} = undef;
  $kernel->alias_remove($self->{alias});
  $kernel->alias_remove('AES_SESSION');
  $kernel->alias_remove('MAIN-Logger');

}



# Syslog debug levels
#0 debug
#1 info
#2 notice
#3 warning
#4 error
#5 critical
#6 alert
#7 emergency




1;

__END__


=head1 NAME

POE::Component::Server::AsyncEndpoint - SOA Asynchronous Endpoint Server


=head RELEASE NOTES FOR 0.10

  B<IMPORTANT:> The API has changed for this (0.10) release. SOAP
  client is now asynchronous. You will have to port your existing
  Endpoint code to the new pattern. The easiest way to do this is to
  backup you Endpoint code and generate new ones with the scaffolding
  helper scripts. Then port the old functionallity to the new
  pattern. Although it may seem a lot of work, is actually easier
  because the new pattern has a lot less code than the 0.02 version.


=head1 SYNOPSIS

  1) Create the server and your endpoints:

  shell$ mkdir MyAES; cd MyAES; aescreate
  shell$ cd endpoints/
  shell$ endpointcreate

  Follow the prompts! (read on for full explanation)

  2) Configure the server and develop the endpoint code
  see POE::Component::Server::AsyncEndpoint::ChannelAdapter

  3) Run or daemonize the server
  shell$ ./aes

  4) Monitor the server using the Web Interface or SNMP
    (Web and SNMP are still in development)

=head1 DESCRIPTION


=head2

WebServices are very popular 


=head2 Note on the term AES

Please note that at times we may abbreviate this project as AES
(Asynchronous Endpoint Server), and other times we may use "AES" to
refer to the master AES process. It should be clear by context when
we use it for one or the other.

=head2 Library or Platform?

More than a library, is a ready-to-use and complete SOA Application
Integration Platform. Once installed, you will use the helper scripts
to generate your server and message endpoints. These scripts will
scaffold most of the code and configuration files for you and all you
have to do is implement the code and your interface will be running in
a few minutes. It is also a CPAN library of course, which can be
easily extended and specialized to develop new software.

The initial motivation to develop this library was to facilitate the
deployment of B<asynchronous (non-blocking) outbound soap services>,
but we decided to build a complete end-to-end integration platform
that would be scalable and very easy to implement. It is not targeted
at the expert hacker, but rather to the integration consultant who
wants to get the job done, fast and easy.

The "Asynchronous Endpoint Server" implements a design pattern to aid
in the development and deployment of a B<distributed> (as opposed to
the centralized spirit of the so-called "Enterprise Service Bus" or
B<ESB>) Service Oriented Architecture (B<SOA>). The concepts and terms
come from several sources, but the actual names of the components are
inspired by the book "Enterprise Integration Patterns" by Gregor Hohpe
and Bobby Wolf (L<http://www.enterpriseintegrationpatterns.com>). The
AsyncEnpoint Server implements a component called a "Message Endpoint"
based on the specialization of the "Channel Adapter" concept coined in
the book, plus a series of helpers and facilities to deploy your
interface in just a few hours.

=head2 Current Protocol Support

Right now, the Channel Adapters support for SOAP on the WS side
and STOMP on the MQ side. More protocols can be easily added by
specializing the ChannelAdpater class. We hope to receive feedback and
incorporate new protocols as needed by the user community.


=head2 Is this an Enterprise Service Bus?

To date, there is certain controversy on whether SOA should be
implemented in a B<hub-and-spoke> versus a B<bus> fashion, and it
seems that the "Enterprise Service Bus" is gaining some traction in
the "Enterprise" and also in the Free and Open Source Communities.

B<This project is the contrary of the bus pattern and promotes a more
distributed architecture where "the ESB (if it exists) is pushed to
the endpoints"> (quote from Dr. Jim Webbers's "Guerrilla SOA"
presentation Jim.Webber@ThoughtWorks.com L<http://jim.webber.name>).

ESB pretends to hide the complexities of EAI inside the bus, when in
reality, the real complexity lies in the writing of the web service at
the endpoint. That is, exposing your current working code through a
web-service API, is the real hard work. Once you get your current
system API exposed via a "Web Service", one small problem remains: the
HTTP is (a) synchronous and (b) it must be initiated from the
outside. This means that even though you may write a Web Service that
sends "OUTBOUND" data to another system, it must be "pulled" or
invoked from the "outside" because your web service cannot initiate
the HTTP connection in a "push" fashion.

What the AES does, is that it allows for you to "pull" your OUTBOUND
data from an OUTBOUND Web Service and put it in a Message Queue where
it can be "pushed" to subscribed clients on the other end. It also,
allow for you to write the INBOUND clients as well, that receive the
data via the Message Queue and push it to the destination system with
an INBOUND Web Service.


=head2 In a Nutshell

Basically, you start by generating a server with the B<aescreate>
helper script (inside a pre existing empty directory). This will
create a directory structure, configuration files, and the aes
executable. To create a new Endpoint, you invoke the B<endpointcreate>
helper script (inside the B<endpoints> directory) and it will generate a
directory for the endpoint and scaffolding code. The B<endpointcreate>
will ask you a few questions and all you have to do is follow the
prompts.

Once you have your Endpoint code ready, you run the master B<aes>
executable and it, will in turn scan your directory structure and load
your endpoints automatically. The watchdog in the B<aes> will monitor
your Endpoints and re-start them if they should die or hang for some
reason.

Each Endpoint is a distinct executable and will run as a separate PID
on your machine. This means that to a certain degree, you can develop
and debug your Endpoint code individually, although you won't have
access to the Message Queue server provided by the main aes
process. We hope to get some feedback on how we can further facilitate
the individual development of the Endpoints, perhaps by simulating the
MQ and other parts of the system. In the mean time, you may just
comment the things that rely on the B<aes> process. There is a
conceived facility to allow each Endpoint to be started and stopped
via a web interface, but this feature is currently under
development.


=head3 Programming Style

The programming technique is event-based (EDA) using POE (Perl Object
Environment) so you should have some familiarity with POE before
coding your Endpoints. Nevertheless, the scaffolding already generates
typical endpoint skeletons for you, so you don't have to be an expert
in POE.


=head3 Inbound (IB) and Outbound (OB) Endpoints

When creating and Endpoint you must chose between an IB or OB Endpoint
base. The OB Endpoint is designed to poll an OB Web Service (SOAP at
the moment) and publish the OB data to the MQ. The IB Endpoints
subscribe to an MQ and push to the target system via an IB Web Service
(SOAP at the moment).

The OB endpoints can be single or multi phased. Please read the
"Poling or Event Driven Endpoints" subsection below for some important
information on the OB Endpoint design and considerations.

=head3 Poling or Event Driven Endpoints

To implement a B<non-blocking, asynchronous outbound> interface for
any application, you must somehow signal the outbound event to the
destination process. To guarantee that the signal delivery is
non-blocking, this signal must not depend on instantaneous
acknowledgement of any other process, and at the same time, the signal
must not be lost. The most obvious way to do this is to store the
signal into permanent storage for later retrieval by the destination
process, and usually, you would want to store these outbound signals
in a database table or to a file on disk.

Retrieving the signals from permanent storage requires either a
polling technique, or an event-based interface to the database table
or file (via a db trigger, or something in the likes of
POE::Wheel::FollowTail). Access to the table or file requires a
database connection or physical access to the file (locally or via the
network) which can be a security risk for many set-ups. Most systems
administrators do not want to deal with complicated set-ups, opening
arbitrary IP ports, etc. And also, she would want the flexibility to
run the interface on any server, not on one particular server.

Because of these issues, we assumed in our design that ALL interaction
with the business systems on ALL ends are STRICTLY through the use of
a Web Service, and for our first deployment, we have chosen SOAP over
HTTP transport. If you need something different, you can either extend
our classes, write us, or send us a patched version of your
extension. In any case, please contact the mailing list to discuss the
needs of your particular implementation.

In our model, the OB Endpoint must periodically invoke a Web Service
that retrieves the outbound signals from the source system's permanent
storage (in other words, B<polling> the "signals" file with a Web
Service). We call this "signals" file a B<FIFO> and the Web Service
that reads it, is called the B<FIFO Popper>. B<The FIFO must never be
confused or treated like a Message Queue>. The FIFO is just a
temporary stack to make the outbound signals non-blocking and allow
for the B<complete application interface> to be developed through Web
Services.

The Endpoint design pattern, can only process B<one single FIFO
record> at any given time and will only mark the FIFO as done when the
data is sent to the MQ and we get a receipt. This assures that our
Endpoint code can hang or die at any moment and we are sure that we
have not lost any data. Also, by changing the status of the FIFO only
when we get a receipt from the MQ, we can rest assured that the EP
will process the failed FIFO when it re-starts. B<It is very important
that you follow this pattern> in your code so you never treat the FIFO
or your Endpoint as a Queue. The actual Queue, is an industry-grade
Message Queue that is available for POE
(see POE::Component::MessageQueue).


=head4 Single or Multi Phased OB Endpoint

The OB Endpoint can be single-phased or multi-phased depending on the
complexity ("orchestration", "choreography") and business needs of
each particular interface.

In the single-phased OB Endpoints, the FIFO record by itself contains
all the data needed to be pushed to the other system. This is
practical for simple interfaces such as passing document states
between two systems, or synchronizing master-slave value list data
between two databases. So if the data is not too complex, or you don't
need any complex "orchestration" or "choreography" it is usually enough
to implement a single-phased OB Endpoint.

Double-phased OB Endpoints are needed when it's not practical or
feasible to save the OB data into the FIFO table or file directly. For
example, an interface that needs to send a complex document from one
system to the other. A complex document will have multiple parts and
dependant data (like foreign key records), that must be processed in a
particular order. In these cases, the FIFO record will probably just
have the id of the document, and another larger and complex WebService
will actually construct the OB data package in a second phase.

In the double or multi-phased Endpoints, one phase extracts the basic
information with the FIFO, and then invokes the actual Web Service
that does the complex packaging of the Outbound data. More stages can
be added easily but two phases should accomodate most of your
integration needs.

The standard OB Endpoints generated by the helper scripts will let you
choose between single-phased or double-phased. Multi-phased are
implementation dependant and should be based on the double-phased type.


=head1 Technical Details

The idea of this section is that you can quickly understand the
library code and help us make this project better by hacking it and
sending us reviews and patches. We would very much welcome comments
and ideas on the code and most importantly, if you can send us
references on how you are using it would be excellent also.

As you can tell by the name-space,
POE::Component::Server::AsyncEndpoint resides in the Server components
of POE. This means that is mostly ready to use, and large part of the
code is actually based on other Components of POE and of CPAN in
general (please note that we use POE::Component and the abbreviated
form "PoCo" from this point on).

For the experienced Perl hacker, you may find that our classes are a
bit restrictive, and that many of them will refuse to start and croak
if not implemented correctly. This is done on purpose because it's
targeted for the final user, and by reducing the flexibility we hope
to reduce the pain. Any comments are, of course, very welcome on the
mailing list.

Some of the main packages that we build upon for the main server are:

        POE
        POE::Wheel::Run
        POE::Component::Logger
        POE::Component::MessageQueue
        POE::Component::Server::HTTP (planned for release 0.2x)
        POE::Component::Server::SNMP (planned for release 0.3x)

Basically, the AsyncEndpoint Server spawns a PoCo::MessageQueue
session and then scans the directory structure to find and run the
individual Endpoints via the package
PoCo::Server::AsyncEndpoint::Endpoints. The package
PoCo::Server::AsyncEndpoint::Config provides the configuration
facilities and PoCo::Server::AsyncEndpoint::WebServer provides the Web
Interface, which in turn is an implementation of
POE::Component::Server::HTTP.

The Endpoints are based on the class
PoCo::Server::AsyncEndpoint::ChannelAdapter which in turn implements
other POE components such as:

        SOAP::Lite (for SOAP support)
        POE::Component::Client::Stomp (for STOMP support)

Through these wrappers respectively:

        POE::Component::Server::AsyncEndpoint::ChannelAdapter::SOAP
        (the above uses POE::Component::Client::SOAP)
        POE::Component::Server::AsyncEndpoint::ChannelAdapter::Stomp

It also provides a configuration file interface through

        POE::Component::Server::AsyncEndpoint::ChannelAdapter::Config

The AES starts the Endpoints with POE::Wheel::Run and communicates with
them via POE IKC on a predefined port. So the endpoints wind up
"speaking" three different languages: SOAP to communicate with the Web
Services, STOMP (L<http://stomp.codehaus.org/>) to communicate with
the MQ and SEP (Simple Endpoint Protocol) to communicate with the main
server process (via IKC). Endpoint programmers need not know about the
IKC and associated SEP protocol, as this is encapsulated in the
ChannelAdapter superclass.

Functionally, the Outbound (OB) Endpoints invoke a Web Service and
push the data using STOMP to the MQ Server. The IB Endpoints, on the
other hand, subscribe to the channels and push the incoming data
through a Web Service on their side. So in a nutshell, the AES as a
whole is a platform to link systems that offer plain SOAP services,
with an emphasis on easily implementing asynchronous outbound SOAP
services.

=head2 Event and Process Model

The publishing of SEDA (Matt Welsh 2001) raised many polemic
discussions on whether EDA is better than thread/process model and
others. We think that each one has it's benefits so we opted for a
"Salomonic" solution: Each Endpoint is an Operating System Process,
but the programming technique of the Endpoint code is EDA (thanks to
POE).


=head1 TIPS AND PITFALLS

The OB Endpoint must be coded in such a way, that it can only handle
ONE FIFO RECORD at any given time, and should not mark the FIFO record
as "POPPED", until the endpoint gets a STOMP/RECEIPT. This way, you
don't have to handle stacks or queues in your code and place all
responsibility on the MQ, where it should be. In the IB Endpoint, you
should not STOMP/ACK the message until you have made sure that the IB
Web Service has succeeded. The stub code generated by the helper
scripts try to enforce these practices, but ultimately it's up to the
final programmer to follow them.

Note that an obvious weak spot is if the OB Endpoint process dies
right after getting the STOMP RECEIPT and before the invocation of the
POPPED Web Service (the one that marks the FIFO record as effectively
popped). Also, if the POPPED Web Service is failing in any way, as
long as you don't shutdown the Endpoint, make sure B<YOU DON'T>
process any more FIFO records until you can successfully mark the
current one as POPPED (i.e. you get some-kind of OK from your Web
Service). We are currently evaluating all borderline conditions an
will not only develop automated tests for each one, but will also work
on a safe shutdown sequence that warns about these conditions.

Even with all these precautions, if the OB Endpoint dies, or the
POPPED Service never recovers before a re-start of the endpoint, this
WILL RESULT IN A DUPLICATE MESSAGE DOWN THE MQ, so B<please take this
into account>. Unless you are processing B<TRANSACTIONS> (GL entries,
for example) all this should not worry you too much. If you do process
transactions, the use of a correlative and/or distinct id, might aid
to reduce or effectively eliminate the possibility of duplicate
records on the target system. Some interfaces rely on the concept of
master and slave tables, where the unique identifiers of the slave
tables are always re-written by the owner of the record (the
Master).

The good news is that the way this library is written (and if
you follow all the recommendations) you should never lose events, on
the contrary, the problem is actually the possibility of duplication
as stated above, which can easily be solved with unique identifiers
and good coding of the Web Services themselves. Please discuss your
specific needs on the list so we can work on these issues.

In any case, the use of serial id's should always be preferred over
the use of alpha-numeric identifiers for records, so FIFO tables and
files, should always have a serial id column (this is regardless of
the "logic" correlative that you may have for transaction based
FIFOs). The examples and the generated stub code already set-up many
of these practices for you.

=head3 Using XML for the actual Message Data

Even though traditionally, most Web Services use XML for the
serialization of data, we have found that using XML is, in many cases,
a useless overhead and an unnecessary complication. The use of simple
and universal serialization languages, such as JSON, is a great
alternative for many interfaces. Of course, you use still have to use
XML B<to define> the WS (and for the SOAP envelope), but the actual
data (the "message parts" in WSDL) are just XSD::string (JSON encoded
strings) that carry associative arrays and perhaps even simple
objects. All our examples and scaffolding code use this technique, but
of course, it's up to you if you want to use XML or another
serialization technique.

=head3 Encoding

We assume that all interface components as well as the Web Services
that provide the data use UTF-8 encoded information. Support for other
encoding systems is up to the developer, but please discuss it on the
list if you require a different one and it's not working.

=head2 OPERATING SYSTEM SUPPORT

The system has been developed and tested on Linux and FreeBSD. We
should say that it runs everywhere that Perl runs but we don't have
the resources or the need for it to run outside of Linux and FreeBSD
(or most Unix or Unix-like OSs). Testing and portability issues to
other platforms may be an added bonus in the future, and if anyone
needs this to run in a non-UNIX platform please let us know. In
general, we think that should run anywhere POE runs, but we can't be
sure. Send us your comments and we will do our best to help.

=head2 COMMUNITY SUPPORT

This software is part of the P2EE project (L<http://www.p2ee.org>) and
can be directly discussed on the p2ee development mailing list here:
L<https://lists.sourceforge.net/lists/listinfo/p2ee-devel>.

=head2 COMMERCIAL SUPPORT

Corcaribe Tecnología C.A. (L<http://www.corcaribe.com>) has funded
this particular development and provides commercial support and
enhancements to this software. They plan to release any enhancements
to the community and keep this software free.

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<POE::Component::Server::AsyncEndpoint::ChannelAdapter>
L<POE::Component::Server::AsyncEndpoint::ChannelAdapter::SOAP>
L<POE::Component::Server::AsyncEndpoint::ChannelAdapter::Stomp>
L<POE::Component::Server::AsyncEndpoint::ChannelAdapter::Config>

L<POE>
L<POE::Wheel::Run>
L<POE::Component::Logger>
L<POE::Component::MessageQueue>
L<POE::Component::Server::HTTP>
L<POE::Component::Server::SNMP>
L<POE::Component::Client::SOAP>
L<POE::Component::Client::Stomp>
L<SOAP::Lite>
L<JSON>

=head1 AUTHOR

Alejandro Imass <ait@p2ee.org>
Alejandro Imass <aimass@corcaribe.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Alejandro Imass / Corcaribe Tecnología C.A. for the P2EE Project

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
