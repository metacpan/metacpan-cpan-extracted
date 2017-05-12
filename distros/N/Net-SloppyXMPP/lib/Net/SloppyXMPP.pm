package Net::SloppyXMPP;

use strict;
use warnings;
use Encode;
use IO::Socket::INET;
use XML::Simple;
use Data::Dumper;

our $VERSION = '0.06';

=head1 NAME

Net::SloppyXMPP - A rather sloppy XMPP client implementation

=head1 DESCRIPTION

In an attempt to drastically reduce external dependencies, this module doesn't use a lot of them.
Therefore, it doesn't do a whole lot via proper standards.

The XML parser is a combination of a mess of regex hacks and some processing through XML::Simple.

XML namespaces aren't really used properly.

There's no guarantee that this will work for anything.

Reinventing the wheel?  You betcha.  Unfortunately, neither L<Net::XMPP> nor L<AnyEvent::XMPP> would
work in the fashion I needed.  It doesn't help that L<Net::XMPP> is unmaintained (or so it seems)
these days.  L<AnyEvent::XMPP> requires LibIDN, which has been too big of an issue to deal with
where I'm needing to implement an XMPP client.

SASL and TLS are both available, but not required.  Just disable one or both of them if you don't
want or can't use them.  SASL features are provided via L<Authen::SASL> and are only used if
C<usesasl> is true (it's true unless you specifically set it to false).  TLS features are provided
via L<Net::SSLeay> and are only used if C<usetls> is true (it's true unless you specifically set
it to false).

One of the goals of this implementation is to ensure that it will work on as many platforms as possible,
especially those that can't use a few of the dependencies of the other XMPP modules available for Perl.

=head1 WHO SHOULD USE THIS?

Probably no one.  It's sloppy.  It's untested.  It's incomplete.  But if the description above didn't
scare you away, you might be a good candidate.  You'll probably need to track down some bugs in it
before you can really use it.  If you're using Openfire 3.6.2 as an XMPP server, you might have good
luck in using it straight away.  If you're using Google's XMPP service, you won't have any luck (yet).

If you really want to use this module, but it doesn't work for you, please post your troubles on the
CPAN bug tracker.  If you need support for additional XMPP servers, I'd love to add such support.
To do that, I might need access to the XMPP server with a test username/password.  I'd really rather not
setup loads of XMPP servers for testing purposes.  Providing me with a test account will help the process
of adding additional XMPP servers.

But like I said, maybe no one should be using this module.  Other seemingly good XMPP modules are
available on CPAN.  Some examples: L<Net::XMPP> and L<AnyEvent::XMPP>.

=head1 EXAMPLE

  use Net::SloppyXMPP;

  my $xmpp = Net::SloppyXMPP->new(
    debug => 1,
    tickdelay => 1,
    #usetls => 0, # set this if you don't want TLS
    #usesasl => 0, # set this if you don't want SASL
    domain => 'yourdomain.xyz',
    username => 'yourusername',
    password => 'yourpassword',
    resource => 'yourresourcename', # or don't set and a default will be supplied
    initialpresence => 'available', # available, busy, dnd, defaults to available
    initialstatus => 'I am alive!', # defaults to ''
    message_callback => \&messageCallback,
  );
  die qq(XMPP didn't create.\n) unless $xmpp;

  sub messageCallback
  {
    my $xmpp = shift;
    my $data = shift;
    print Dumper($data);
  }

  my $xmppConnect = $xmpp->connect;
  die qq(XMPP didn't connect.\n) unless $xmppConnect;

  # if you want SloppyXMPP to control your main loop
  $xmpp->run(\&tick);
  sub tick
  {
    # do stuff in here that needs to happen each loop (use as a main loop)
    my $xmpp = shift; # if you need it, same object as the $xmpp you already used
    print "This runs every $xmpp->{tickdelay} seconds.\n";
  }

  # or if you want to run your own loop, do this:
  sub loop
  {
    print "Doing something useful here...\n";

    # ... more useful code ...

    $xmpp->tick; # runs the SloppyXMPP loop once

    # ... and more useful code ...
  }
  loop();

=head1 ABSTRACT

Not complete, just like the module itself.  Feel free to read the source code to figure out how to
use it.  A bit of help is sprinkled about the page below.

B<WARNING:> Most of these functions are internal functions not to be used outside of the module.
If you use them yourself, I don't want to get bug reports about it.  If it just says
"C<Used internally>" but doesn't say you can't use it, you're probably okay to use it.  If it says
something like "C<Don't use it yourself>", don't use it.  You're likely to upset the delicate
balance of nature and might cause mass casualties, famine, hurricanes, tornadoes, floods, or drought.
You've been warned.

If you've avoided my warning above and are using a function that you really have no business using,
let me know (see my contact info at the end of this doc) so I can create a more proper interface
into whatever it is that you're doing improperly.

=head2 new

  my $xmpp = Net::SloppyXMPP->new(
    someoption => "somevalue",       # see below
    anotheroption => "anothervalue", #   for the options
  );

=over

=item usetls

Specify the use of TLS.
TLS requires L<Net::SSLeay>, but it'll only be loaded if this is true.
Your XMPP server must support TLS.
Default true if not set.

=item usesasl

Specify the use of SASL for authentication.
SASL requires L<Authen::SASL> and L<MIME::Base64>, but they'll only be loaded if this is true.
Your XMPP server must support SASL.
Default true if not set.

=item usesrv

Specify the use of SRV records to determine XMPP host/port based on domain.
This requires L<Megagram::ResolveSRV>, but it'll only be loaded if this is true.
If your domain doesn't use C<_xmpp-client._tcp.yourdomain.com> SRV records, this will fail.
Default true if not set.

=item domain

The domain.
If your XMPP user is C<fred@yourdomain.xyz>, the domain is C<yourdomain.xyz>.
I<A required variable>.

=item host

The IP/domain of the XMPP server to connect to.
You can use either C<"yourdomain.xyz"> or C<"yourdomain.xyz:5222"> formats.
If you're using SRV records (see C<usesrv> above), don't set this.
I<A required variable>, but only if C<usesrv> is false.

=item port

The port of the XMPP server to connect to.
If you've set the port number along with the host (see C<host> above), don't set this.
If you're using SRV records (see C<usesrv> above), don't set this.
I<A required variable>, but only if C<usesrv> is false.

=item username

The username.
If your XMPP user is C<fred@yourdomain.xyz>, the username is C<fred>.
I<A required variable>.

=item password

The password.
This probably doesn't need introduction.
I<A required variable>.

=item resource

The resource.
If you don't know what this is, you probably don't need to set it.
In the JID C<fred@yourdomain.xyz/Office>, the resource is C<Office>.
A default is provided if you don't set it.

=item message_callback

The function or code that you want to run on each incoming message.
Must be a coderef.
A default (NOOP with complaint) provided if you don't set it.

=item debug

The debug level.
The higher the number, the more debug messages you'll get.
If you don't want to get I<any> messages, set it to -1.
Default is C<0>.

=item tickdelay

The delay in the C<run> loop, in floating-point seconds.
If you don't use C<run> (see below), you won't need this.
Default is C<0.5> seconds.

=item initialpresence

Your initial presence on the XMPP server upon connection.
Set it to any valid presence value (such as C<available>, C<dnd>, C<away>).
Can be changed at any time while connected via the C<presence> function (see below).
Default is C<available>.

=item initialstatus

Your initial status message on the XMPP server upon connection.
Set it to some string.
Can be changed at any time while connected via the C<presence> function (see below).
Default is empty string.

=item socket_write_len

If you don't know what this is for, don't mess with it.
Sets the amount to write to the socket at one time.
Default is C<4096>.

=item socket_read_len

If you don't know what this is for, don't mess with it.
Sets the amount to read from the socket at one time.
Default is C<4096>.

=item pingfreq

If you don't know what this is for, don't mess with it.
Sets the number of seconds between automatic pings.
Set it to C<0> if you wish to disable it.
Default is C<300> seconds (5 minutes).

=back

=cut

sub new
{
  my $class = shift;
  my %args = @_;
  my $self = bless({}, $class);

  $self->{debug} = $args{debug} || 0;

  $self->{tickdelay} = int((defined($args{tickdelay}) ? $args{tickdelay} : 0.5) * 100) / 100 || 0.5;
  $self->{tick_callback} = sub { $self->debug(0, __PACKAGE__." has no tick callback."); };

  $self->{pingtimer} = time();
  $self->{pingfreq} = (defined($args{pingfreq}) ? abs($args{pingfreq}) : 300);

  $self->{message_callback} = sub { $self->debug(0, __PACKAGE__." has no message callback."); };
  if (defined($args{message_callback}))
  {
    if (ref($args{message_callback}) eq 'CODE')
    {
      $self->{message_callback} = $args{message_callback};
    }
    else
    {
      $self->debug(0, __PACKAGE__."->new message_callback must be coderef.");
      return 0;
    }
  }

  @{$self->{write_queue}} = ();
  @{$self->{read_queue}} = ();
  $self->{read_buffer} = '';

  $self->{usetls} = (defined($args{usetls}) ? $args{usetls} : 1);
  $self->{usesrv} = (defined($args{usesrv}) ? $args{usesrv} : 1);
  $self->{usesasl} = (defined($args{usesasl}) ? $args{usesasl} : 1);

  if ($self->{usesrv})
  {
    require Megagram::ResolveSRV;
    import Megagram::ResolveSRV;
    $self->{rsrv} = Megagram::ResolveSRV->new;
  }

  if ($self->{usetls})
  {
    require Net::SSLeay;
    import Net::SSLeay qw(die_if_ssl_error);

    #### NET::SSLeay is not really thread-safe it seems... fixable? FIXME

    Net::SSLeay::load_error_strings();
    Net::SSLeay::SSLeay_add_ssl_algorithms();
    Net::SSLeay::randomize();
    $Net::SSLeay::ssl_version = 10; # Insist on TLSv1
  }

  if ($self->{usesasl})
  {
    $self->debug(2, "We'll be using SASL for Authentication.");
    eval
    {
      require Authen::SASL;
      import Authen::SASL;
      require MIME::Base64;
      import MIME::Base64;
    };
  }

  $self->{domain} = $args{domain} or do
  {
    $self->debug(0, __PACKAGE__."->new requires domain.");
    return 0;
  };

  $self->{host} = $args{host};
  $self->{port} = $args{port};

  if (defined($self->{host}) && $self->{host} =~ s/:(\d+)//)
  {
    my $port = $1;
    if ($self->{port})
    {
      $self->debug(0, __PACKAGE__."->new uses either domain=host:port or domain=host, port=port, not both.");
      return 0;
    }
    $self->{port} = $port;
  }

  if ($self->{usesrv} && ($self->{host} || $self->{port}))
  {
    $self->debug(0, __PACKAGE__."->new does not accept host or port if usesrv is true.");
    return 0;
  }

  if (!$self->{usesrv} && (!$self->{host} || !$self->{port}))
  {
    $self->debug(0, __PACKAGE__."->new requires host and port (host=host:port or host=host, port=port) when usesrv is false.");
    return 0;
  }

  $self->{username} = $args{username} or do
  {
    $self->debug(0, __PACKAGE__."->new requires username.");
    return 0;
  };
  $self->{password} = $args{password};
  $self->{resource} = $args{resource} || "Perl-Net-SimpleXMPP-$VERSION-".int(rand() * 100000);
  $self->{initialpresence} = $args{initialpresence} || 'available';
  $self->{initialstatus} = $args{initialstatus} || '';

  $self->{socket_write_len} = $args{socket_write_len} || 4096;
  $self->{socket_read_len} = $args{socket_read_len} || 4096;

  $self->{xmpp_features} = {};
  $self->{authenticated} = 0;
  $self->{resourcebound} = 0;
  $self->{sessionstarted} = 0;

  @{$self->{roster}} = ();

  return $self;
}

=head2 debug

Used internally.
B<Don't use it yourself.>
Debug messages are written to this function.
Debug messages only appear (via STDERR) when C<< ($debugvalue <= $xmpp-{debug}) >>.

=cut

sub debug
{
  my $self = shift;
  my $level = shift || 1;
  return 0 unless ($level <= $self->{debug});
  my $text = shift;
  warn $text."\n";
}

=head2 connect

Initiates the XMPP connection.

=cut

sub connect
{
  my $self = shift;

  my @hosts;

  if ($self->{usesrv})
  {
    @hosts = $self->{rsrv}->resolve('_xmpp-client._tcp.'.$self->{domain});
    return -1 unless ($hosts[0]); # no XMPP service listed
  }
  else
  {
    @hosts = ({target => $self->{host}, port => $self->{port}});
  }

  foreach my $host (@hosts)
  {
    my $target = $host->{target};
    my $port = $host->{port};
    $self->debug(3, "Connecting to $target:$port");
    $self->{socket} = IO::Socket::INET->new(
      PeerAddr => $target,
      PeerPort => $port,
      Proto    => 'tcp',
      Blocking => 1,
    );
    last if (defined($self->{socket}) && $self->{socket}->connected);
  }

  unless (defined($self->{socket}) && $self->{socket}->connected)
  {
    $self->debug(1, "SOCKETERROR: $!");
    return 0;
  }

  $self->{socket}->blocking(0); # set to non-blocking
  binmode($self->{socket}, ':raw');

  $self->sendhandshake;

  return 1;
}

=head2 sendhandshake

Used internally.
B<Don't use it yourself.>
Sends the XMPP handshake.

=cut

sub sendhandshake
{
  my $self = shift;

  # start the handshake
  $self->write(qq(<?xml version='1.0' ?><stream:stream version='1.0' xmlns:stream='http://etherx.jabber.org/streams' xmlns='jabber:client' to='$self->{domain}' xml:lang='en' />));
}

=head2 check_socket_connected

Used internally.
Checks to see if the socket is currently connected.
Doesn't test to see if the socket is TLS or not.

=cut

sub check_socket_connected
{
  my $self = shift;

  unless (defined($self->{socket}) && $self->{socket}->connected)
  {
    $self->debug(1, "SOCKET NOT CONNECTED.");
    return 0;
  }

  return 1;
}

=head2 disconnect

Disconnects the socket.
Also shuts down the TLS connection cleanly.

=cut

sub disconnect
{
  my $self = shift;

  $self->debug(1, "DISCONNECT.");

  $self->{tick_running} = 0;

  if ($self->{usetls})
  {
    Net::SSLeay::free($self->{ssl});
    delete($self->{ssl});
    Net::SSLeay::free($self->{ctx});
    delete($self->{ctx});
  }

  close($self->{socket});
  delete($self->{socket});

  return 1;
}

=head2 ready

Used internally.
Determines if the XMPP socket is ready to be used.
It's ready after authentication was successful, the resource is bound, and the session has started.

=cut

sub ready
{
  my $self = shift;
  return $self->{authenticated} && $self->{resourcebound} && $self->{sessionstarted};
}

=head2 use_tls

Used internally.
Determines whether the socket is TLS'ified or not.

=cut

sub use_tls
{
  my $self = shift;
  return (($self->{usetls} && defined($self->{ssl})) ? 1 : 0);
}

=head2 setup_tls

Used internally.
B<Don't use it yourself.>
Sets up the TLS connection over the socket.

=cut

sub setup_tls
{
  my $self = shift;
  return 0 unless $self->{usetls};
  return 0 unless $self->check_socket_connected;

  $self->debug(2, "Using TLS, setting up.");

  $self->{ctx} = Net::SSLeay::CTX_new() or die "SSL ERROR: CTX_new\n";

  Net::SSLeay::CTX_set_mode($self->{ctx}, 1 | 2);
  die_if_ssl_error("SSL ERROR: CTX_set_mode");

  Net::SSLeay::CTX_set_options($self->{ctx}, &Net::SSLeay::OP_ALL);
  die_if_ssl_error("SSL ERROR: CTX_set_options");

  $self->{ssl} = Net::SSLeay::new($self->{ctx}) or die "SSL ERROR: new\n";

  Net::SSLeay::set_fd($self->{ssl}, fileno($self->{socket}));
  die_if_ssl_error("SSL ERROR: set_fd");

  Net::SSLeay::connect($self->{ssl});
  die_if_ssl_error("SSL ERROR: connect");

  return 1;
}

=head2 run

  $xmpp->run(\&mycallbackfunction);
  # .. or ..
  $xmpp->run(sub {
    my $xmpp = shift;
    print "This is my callback function!\n";
  });

Starts the SloppyXMPP-controlled main loop.
If you don't want SloppyXMPP to control your loop, use C<tick> instead.
Runs C<tick> once, runs your callback function, and then sleeps for C<< $xmpp->{tickdelay} >> seconds.

=cut

sub run
{
  my $self = shift;
  my $callback = shift;

  unless (ref($callback) eq 'CODE')
  {
    $self->debug(0, __PACKAGE__."->run requires callback and it must be a valid sub or a reference to one.");
    return 0;
  }

  $self->{tick_callback} = $callback;
  $self->{tick_running} = 1;

  $self->debug(3, "BEGIN RUN LOOP");

  while ($self->{tick_running})
  {
    $self->debug(6, __PACKAGE__."->run TICK!");
    $self->tick;
    &{$self->{tick_callback}}($self);
    select(undef, undef, undef, ($self->ready ? $self->{tickdelay} : 0.01));
  }
}

=head2 tick

Runs the SloppyXMPP loop once.
Don't use this if you're using C<run>.

=cut

sub tick
{
  my $self = shift;

  $self->ping if (($self->{pingfreq} > 0) && ($self->ready) && (time() - $self->{pingtimer} > $self->{pingfreq}));
  $self->socket_read;
  $self->process_read_buffer if length($self->{read_buffer});
  $self->process_read_queue if $self->readable;
  $self->socket_write;
}

=head2 message

  $xmpp->message({
    to => 'fred@fakedomain.xyz',
    message => 'This is a message.',
  });

  $xmpp->message({
    to => [
      'fred@fakedomain.xyz',
      'jane@fakedomain.xyz',
    ],
    message => 'This is a message.',
  });

Sends a message to an XMPP user.
If C<to> is an arrayref, it will send to multiple parties.

=cut

sub message
{
  my $self = shift;
  my $data = shift;

  my @to = ((ref($data->{to}) eq 'ARRAY') ? @{$data->{to}} : ($data->{to}));

  foreach my $to (@to)
  {
    $to =~ s/[<>"']//g;

    my $message = XMLout({
      to => $to,
      type => 'normal',
      body => ["$data->{message}"],
    }, RootName => 'message');

    $self->debug(5, qq(Message send to [$to] message [$message]));
    $self->write($message);
  }
}

=head2 write

Used internally.
B<Don't use it yourself.>
Writes raw data to the socket write queue.

=cut

sub write
{
  my $self = shift;
  push(@{$self->{write_queue}}, shift);
  $self->socket_write; # force a write, if it can write.
}

=head2 read

Used internally.
B<Don't use it yourself.>
Reads data from the read queue.
Used by the event manager.

=cut

sub read
{
  my $self = shift;
  shift(@{$self->{read_queue}});
}

=head2 unread

Used internally.
B<Don't use it yourself.>
If C<read> was used, but the data can't be used, put it back in the queue.

=cut

sub unread
{
  my $self = shift;
  unshift(@{$self->{read_queue}}, @_);
}

=head2 readable

Used internally.
B<Don't use it yourself.>
Determines if there is any data to be read in the read queue.

=cut

sub readable
{
  my $self = shift;
  return (scalar(@{$self->{read_queue}}) ? 1 : 0);
}

=head2 socket_write

Used internally.
B<Don't use it yourself.>
Writes data from the socket write queue to the socket.

=cut

sub socket_write
{
  my $self = shift;
  return 0 unless $self->check_socket_connected;

  $self->debug(6, "SOCKET_WRITE");

  my $total_written_len = 0;
  my $start_pos = 0;

  while (my $data = shift(@{$self->{write_queue}}))
  {
    $data = encode_utf8($data);

    $self->debug(4, "SOCKET_WRITE-1: [$data]");

    while ($data)
    {
      my $data_to_write = (($start_pos <= length($data)) ? substr($data, $start_pos, $self->{socket_write_len}) : '');
      my $data_to_write_len = length($data_to_write);
      last unless $data_to_write_len;

      $self->debug(3, "SOCKET_WRITE-CHUNK: [$data_to_write_len] [$data_to_write]");

      my $data_written_len = 0;

      if ($self->use_tls)
      {
        $self->debug(3, "SOCKET_WRITE with TLS");
        $data_written_len = Net::SSLeay::write($self->{ssl}, $data_to_write);
      }
      else
      {
        $self->debug(3, "SOCKET_WRITE no TLS");
        $data_written_len = syswrite($self->{socket}, $data_to_write);
      }

      if ($data_written_len > 0)
      {
        $start_pos += $data_written_len;
        $total_written_len += $data_written_len;
      }
      else
      {
        unshift(@{$self->{write_queue}}, $data);
        $self->debug(2, "SOCKET_WRITE ERROR: Didn't write. [$data_to_write_len] [$data_written_len] [$!]");
        return $total_written_len;
      }
    }
  }

  return $total_written_len;
}

=head2 socket_read

Used internally.
B<Don't use it yourself.>
Reads data from the socket and pushes it into the socket read buffer to be processed by C<process_read_buffer>.

=cut

sub socket_read
{
  my $self = shift;
  return 0 unless $self->check_socket_connected;

  $self->debug(6, "SOCKET_READ");

  my $total_read_len = 0;

  while (1)
  {
    my $data;
    my $data_read_len = 0;

    if ($self->use_tls)
    {
      $data = Net::SSLeay::read($self->{ssl}) || '';
      $data_read_len = length($data) if defined($data);
    }
    else
    {
      $data_read_len = sysread($self->{socket}, $data, $self->{socket_read_len});
    }

    last unless $data_read_len;

    $data = decode_utf8($data);
    $self->debug(3, "SOCKET_READ: [$data]");
    $self->{read_buffer} .= $data;
    $total_read_len += $data_read_len;
  }

  return $total_read_len;
}

=head2 process_read_buffer

Used internally.
B<Don't use it yourself.>
Processes data in the socket read buffer and pushes it into the read queue to be processed by C<process_read_queue>.

=cut

sub process_read_buffer
{
  my $self = shift;

  return 0 unless $self->{read_buffer};

  $self->debug(4, "PROCESS_READ_BUFFER");

  $self->debug(3, "PROCESS_READ_BUFFER-1: [$self->{read_buffer}]");
  $self->{read_buffer} =~ s#(<\?.*?\?>)##;
  $self->{read_buffer} =~ s#(</?)stream:#$1#g;
  $self->{read_buffer} =~ s#xmlns:stream=#xmlns-stream=#g;
  $self->{read_buffer} =~ s#:stream=#=#g;
  $self->{read_buffer} =~ s#</?stream\b[^>]*?>##g;
  $self->debug(3, "PROCESS_READ_BUFFER-2: [$self->{read_buffer}]");

  $self->{read_buffer} =~ s#^\s*(<\s*([a-z0-9\-_]+)\s*\b[^>]*?\s*)/>#$1></$2>#i; # convert self-closing first tag to empty non-self-closing tag, to prep for next regex

  while ($self->{read_buffer} =~ s#^\s*(<\s*([a-z0-9\-_]+)\s*\b.*?</\s*\2\s*>)##is)
  {
    my $section = $1;
    my $opentag = $2;
    $self->debug(5, "PROCESS_READ_BUFFER-OPENTAG: $opentag");
    $self->debug(5, "PROCESS_READ_BUFFER-SECTION: $section");
    push(@{$self->{read_queue}}, XMLin($section, KeepRoot => 1));
  }
}

=head2 process_read_queue

Used internally.
B<Don't use it yourself.>
Handles events, errors, etc.

=cut

sub process_read_queue
{
  my $self = shift;

  $self->debug(4, "PROCESS_READ_QUEUE");

  while (my $data = $self->read)
  {
    $self->debug(4, Dumper($data));

    if (defined($data->{features}))
    {
      $self->debug(3, "PRQ: FEATURES DEFINED");
      $self->{xmpp_features} = $data->{features};
      $self->debug(4, Dumper($self));
    }

    if (defined($data->{features}) && defined($data->{features}->{starttls}) && $self->{usetls})
    {
      $self->debug(3, "PRQ: STARTTLS");
      delete($data->{features}->{starttls}->{required});
      $self->write(XMLout($data->{features}->{starttls}, RootName => 'starttls'));
    }
    elsif (defined($data->{features}) && defined($data->{features}->{starttls}) && defined($data->{features}->{starttls}->{required}) && !$self->{usetls})
    {
      $self->debug(3, "PRQ: STARTTLS IS REQUIRED");
      $self->disconnect;
    }
    elsif (defined($data->{proceed}) && defined($data->{proceed}->{xmlns}) && $data->{proceed}->{xmlns} =~ m/xmpp-tls$/i)
    {
      $self->debug(3, "PRQ: PROCEED WITH TLS");
      if ($self->setup_tls)
      {
        $self->debug(3, "PRQ: SETUPTLS SUCCESS");
        $self->sendhandshake;
      }
    }
    elsif (defined($data->{features}) && defined($data->{features}->{auth}))
    {
      $self->debug(3, "PRQ: AUTHENTICATION WILL COMMENCE");
      $self->authenticate;
    }
    elsif (defined($data->{features}) && defined($data->{features}->{bind}))
    {
      $self->debug(3, "PRQ: RESOURCE BIND WILL COMMENCE");
      $self->bindresource;
    }
    elsif (defined($data->{iq}))
    {
      $self->debug(3, "PRQ: IQ RECEIVED");
      if (defined($data->{iq}->{bind}))
      {
        $self->debug(3, "PRQ: BIND IQ RECEIVED");
        if ($data->{iq}->{type} eq 'error')
        {
          $self->debug(3, "PRQ: BIND IQ ERROR");
          $self->debug(3, Dumper($data));
        }
        else
        {
          $self->{resourcebound} = 1;
          $self->{jid} = $data->{iq}->{bind}->{jid};
          $self->debug(3, Dumper($self->{xmpp_features}));
          if (defined($self->{xmpp_features}->{session}))
          {
            $self->startsession;
          }
        }
      }
      elsif (defined($data->{iq}->{session}))
      {
        $self->debug(3, "PRQ: SESSION IQ RECEIVED");
        if ($data->{iq}->{type} eq 'error')
        {
          $self->debug(3, "PRQ: SESSION IQ ERROR");
          $self->debug(3, Dumper($data));
        }
        else
        {
          $self->{sessionstarted} = 1;
          $self->rosterfetch;
        }
      }
      elsif (defined($data->{iq}->{query}->{xmlns}) && $data->{iq}->{query}->{xmlns} eq 'jabber:iq:roster')
      {
        $self->debug(3, "PRQ: ROSTER RECEIVED");
        $self->presence($self->{initialpresence}, $self->{initialstatus});
        $self->rosterreceived($data->{iq}->{query});
      }
      elsif (defined($data->{iq}->{ping}))
      {
        $self->debug(3, "PRQ: PING IQ RECEIVED");
        $self->pong($data->{iq});
      }
    }
    elsif (defined($data->{message}))
    {
      $self->debug(3, "PRQ: MESSAGE RECEIVED");
      if (defined($data->{message}->{composing}))
      {
        $self->debug(3, "PRQ: MESSAGE IS BEING COMPOSED");
        $self->messagecomposingstarted($data->{message});
      }
      elsif (defined($data->{message}->{body}))
      {
        my $body = $data->{message}->{body};
        $self->debug(3, "PRQ: MESSAGE BODY RECEIVED");
        $self->debug(3, "MESSAGE: $body");
        $self->messagereceived($data->{message});
      }
      elsif (defined($data->{message}->{paused}))
      {
        $self->debug(3, "PRQ: MESSAGE IS BEING COMPOSED HAS PAUSED");
        $self->messagecomposingpaused($data->{message});
      }
      elsif (defined($data->{message}->{active}))
      {
        $self->debug(3, "PRQ: MESSAGE IS BEING COMPOSED HAS ENDED");
        $self->messagecomposingended($data->{message});
      }
    }
    elsif (defined($data->{challenge}))
    {
      $self->debug(3, "PRQ: SASL CHALLENGE RECEIVED");
      $self->saslchallenge($data);
    }
    elsif (defined($data->{failure}))
    {
      $self->debug(3, "PRQ: FAILURE DETECTED");
      if (defined($data->{failure}->{'not-authorized'}))
      {
        $self->debug(3, "PRQ: AUTHENTICATION FAILURE");
      }
    }
    elsif (defined($data->{success}))
    {
      $self->debug(3, "PRQ: SUCCESS DETECTED");
      $self->saslsuccess($data);
    }
  }
}

=head2 authenticated

Used internally.
Returns true if this connection has been authenticated successfully.

=cut

sub authenticated
{
  my $self = shift;
  return $self->{authenticated};
}

=head2 authenticate

Used internally.
B<Don't use it yourself.>
Begins the authentication process.

=cut

sub authenticate
{
  my $self = shift;
  return 0 unless $self->check_socket_connected;
  return 0 if ($self->{usetls} && !$self->use_tls); # want TLS, but not ready
  return 0 unless (defined($self->{xmpp_features}) && defined($self->{xmpp_features}->{auth}));

  $self->debug(2, "Authenticating with XMPP");

  if ($self->{usesasl})
  {
    my $xmlns = $self->{xmpp_features}->{mechanisms}->{xmlns};
    my $mechanisms = $self->{xmpp_features}->{mechanisms}->{mechanism};
    my @mechanisms = (ref($mechanisms) eq 'ARRAY' ? @{$mechanisms} : ($mechanisms));
    my $sasl = Authen::SASL->new(
      mechanism => join(' ', @mechanisms),
      callback => {
        user => $self->{username},
        pass => $self->{password},
      },
    );
    $self->debug(5, Dumper($sasl));
    $self->{sasl} = $sasl->client_new('xmpp', $self->{domain});
    my $mechanism = $self->{sasl}->mechanism;
    my $response = MIME::Base64::encode_base64($self->{sasl}->client_start, '');
    $self->write(qq(<auth xmlns="$xmlns" mechanism="$mechanism"/>));
  }
}

=head2 saslchallenge

Used internally.
B<Don't use it yourself.>
Handles the SASL challenge.

=cut

sub saslchallenge
{
  my $self = shift;
  my $data = shift;
  my $challenge = MIME::Base64::decode_base64($data->{challenge}->{content});

  $self->debug(2, "SASLCHALLENGE!");
  $self->debug(3, Dumper($challenge));

  $self->debug(1, "SENDING RESPONSE TO SASLCHALLENGE");
  my $xmlns = $data->{challenge}->{xmlns};
  my $response = $self->{sasl}->client_step($challenge);
  unless ($response)
  {
    $self->debug(1, "SASL ERROR for $challenge");
    return 0;
  }
  $response = MIME::Base64::encode_base64($response);
  $self->write(qq(<response xmlns="$xmlns">$response</response>));
}

=head2 saslsuccess

Used internally.
B<Don't use it yourself.>
Handles SASL challenge success.

=cut

sub saslsuccess
{
  my $self = shift;
  my $data = shift;
  my $success = MIME::Base64::decode_base64($data->{success}->{content});

  $self->debug(1, "SUCCESSFUL SASLCHALLENGE");
  $self->debug(3, Dumper($success));

  $self->{authenticated} = 1;

  $self->sendhandshake;
}

=head2 bindresource

Used internally.
B<Don't use it yourself.>
Binds this connection to a specific resource.

=cut

sub bindresource
{
  my $self = shift;

  $self->debug(1, "RESOURCE BIND");

  my $xmlns = $self->{xmpp_features}->{bind}->{xmlns};
  $self->write(qq(<iq type="set" id="bind_2"><bind xmlns="$xmlns"><resource>$self->{resource}</resource></bind></iq>));
}

=head2 startsession

Used internally.
B<Don't use it yourself.>
Starts the XMPP session.

=cut

sub startsession
{
  my $self = shift;

  $self->debug(1, "SESSION START");

  my $xmlns = $self->{xmpp_features}->{session}->{xmlns};
  $self->write(qq(<iq to="$self->{domain}" type="set" id="sess_1"><session xmlns="$xmlns" /></iq>));
}

=head2 presence

  $xmpp->presence('available', 'Playing music and eating chips.');

Sets your presence and status.

=cut

sub presence
{
  my $self = shift;
  my $presence = shift || 'available';
  my $status = shift || '';
  return 0 unless $self->ready;

  $self->debug(1, "SET PRESENCE -> $presence -> $status");
  $self->write(qq(<presence xml:lang="en"><show>$presence</show><status>$status</status></presence>));
  return 1;
}

=head2 messagecomposingstarted

Used internally.
B<Don't use it yourself.>
Event handler uses this function to handle the C<messagecomposingstarted> event.
This happens when some user starts typing a message to you.
Not all XMPP clients send this notification.

=cut

sub messagecomposingstarted
{
  my $self = shift;
  my $data = shift;

  $self->debug(1, "A MESSAGE IS BEING COMPOSED TO YOU FROM [$data->{from}]");
}

=head2 messagecomposingpaused

Used internally.
B<Don't use it yourself.>
Event handler uses this function to handle the C<messagecomposingpaused> event.
This happens when the person typing the message stopped typing (but didn't erase
their message, send the message, or close the message window).

=cut

sub messagecomposingpaused
{
  my $self = shift;
  my $data = shift;

  $self->debug(1, "A MESSAGE BEING COMPOSED TO YOU FROM [$data->{from}] HAS PAUSED.");
}

=head2 messagecomposingended

Used internally.
B<Don't use it yourself.>
Event handler uses this function to handle the C<messagecomposingended> event.
This happens when the person typing the message quit their message (erased
their message, sent the message, or closed the message window).

=cut

sub messagecomposingended
{
  my $self = shift;
  my $data = shift;

  $self->debug(1, "A MESSAGE BEING COMPOSED TO YOU FROM [$data->{from}] HAS ENDED.");
}

=head2 messagereceived

Used internally.
B<Don't use it yourself.>
Event handler uses this function to handle the C<messagereceived> event.
This happens when a message is received from another XMPP user.

=cut

sub messagereceived
{
  my $self = shift;
  my $data = shift;

  $self->debug(1, "MESSAGE RECEIVED FROM [$data->{from}]");

  $self->debug(2, <<XYZ);
---------------
To: $data->{to}
From: $data->{from}
Body: $data->{body}
---------------
XYZ

  &{$self->{message_callback}}($self, $data);
}

=head2 roster

  my $roster = $xmpp->roster;

Returns an arrayref that contains the roster.

=cut

sub roster
{
  my $self = shift;
  return $self->{roster};
}

=head2 rosterfetch

Used internally.
B<Don't use it yourself.>
Requests the roster from the XMPP server.
Only has to happen once at connection time.

=cut

sub rosterfetch
{
  my $self = shift;

  $self->debug(1, "GETTING ROSTER");

  $self->write(qq(<iq from="$self->{jid}" type="get" id="roster_1"><query xmlns="jabber:iq:roster" /></iq>));
}

=head2 rosterreceived

Used internally.
B<Don't use it yourself.>
The roster arrived from the XMPP server.
This populates the proper variable that contains the roster arrayref.
Access this data via C<roster> (see above).

=cut

sub rosterreceived
{
  my $self = shift;
  my $roster = shift;

  $self->debug(1, "RECEIVED ROSTER");

  my @contacts = (ref($roster->{item}) eq 'ARRAY' ? @{$roster->{item}} : ($roster->{item}));

  $self->{roster} = \@contacts;

  $self->debug(3, Dumper($self->{roster}));
}

=head2 ping

Used internally.
B<Don't use it yourself.>
Sends a ping to the server.

=cut

sub ping
{
  my $self = shift;
  my $id = 'ping'.int(rand() * 100000);
  $self->write(qq(<iq from='$self->{jid}' to='$self->{domain}' id='$id' type='get'><ping xmlns='urn:xmpp:ping'/></iq>));
  $self->{pingtimer} = time();
}

=head2 pong

Used internally.
B<Don't use it yourself.>
Sends a pong (ping response) to the server.

=cut

sub pong
{
  my $self = shift;
  my $data = shift;
  my $from = $data->{from};
  my $id = $data->{id};
  $self->write(qq(<iq from='$self->{jid}' to='$from' id='$id' type='result'/>));
  $self->{pingtimer} = time();
}

=head1 TODO

=over

=item *

Event callbacks.  There aren't any.  They are planned and should be reasonably easy to setup.
This module isn't all that useful without them.

=item *

Test on more XMPP servers.  This has only been tested on the Openfire XMPP Server, version 3.6.2.

=item *

Make sure it works on Google's XMPP servers.  Right now, it doesn't.

=back

=head1 BUGS

Find bugs?  Of course you will.  Report them on the CPAN bug tracker.  Don't email me directly about bugs.
If it works for you, I'd love to hear about it.  Find my email address in my CPAN profile (C<wilsond>).
Make sure to put "C<Net::SloppyXMPP Feedback>" in the subject line or I might ignore it completely.
Please don't send HTML email if at all possible.  I greatly prefer plaintext email.

If you have a patch for this module, post it on the CPAN bug tracker.  If it fits the goal of this module,
I'll be very happy to merge it in.  If it doesn't fit the goal, I won't, even if you think it makes sense.

=over

=item *

This is version 0.04 of a module called SloppyXMPP.  If you don't hit any bugs, you might want to try
your luck at the lottery today.

=item *

Doesn't work with Google's XMPP server right now.  I plan to make it work.

=back

=head1 COPYRIGHT/LICENSE

Copyright 2009 Megagram.  You can use any one of these licenses: Perl Artistic, GPL (version >= 2), BSD.

=head2 Perl Artistic License

Read it at L<http://dev.perl.org/licenses/artistic.html>.
This is the license we prefer.

=head2 GNU General Public License (GPL) Version 2

  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License
  as published by the Free Software Foundation; either version 2
  of the License, or (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see http://www.gnu.org/licenses/

See the full license at L<http://www.gnu.org/licenses/>.

=head2 GNU General Public License (GPL) Version 3

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see http://www.gnu.org/licenses/

See the full license at L<http://www.gnu.org/licenses/>.

=head2 BSD License

  Copyright (c) 2009 Megagram.
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, are permitted
  provided that the following conditions are met:

      * Redistributions of source code must retain the above copyright notice, this list of conditions
      and the following disclaimer.
      * Redistributions in binary form must reproduce the above copyright notice, this list of conditions
      and the following disclaimer in the documentation and/or other materials provided with the
      distribution.
      * Neither the name of Megagram nor the names of its contributors may be used to endorse
      or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
  PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
  IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
