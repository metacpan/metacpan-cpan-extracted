package Net::Peep::Client::Pinger;

require 5.00503;
use strict;
# use warnings; # commented out for 5.005 compatibility
use Carp;
use Data::Dumper;
use File::Tail;
use Net::Ping::External qw(ping);
use Net::Peep::Client;
use Net::Peep::Client::Pinger::Host;
use Net::Peep::BC;
use Net::Peep::Notifier;
use Net::Peep::Notification;

require Exporter;

use vars qw{ @ISA %EXPORT_TAGS @EXPORT_OK @EXPORT $VERSION };

@ISA = qw(Exporter Net::Peep::Client);
%EXPORT_TAGS = ( 'all' => [ qw( INTERVAL MAX_INTERVAL ADJUST_AFTER ) ] );
@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
@EXPORT = qw( );
$VERSION = do { my @r = (q$Revision: 1.5 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

use constant DEFAULT_PID_FILE => "/var/run/pinger.pid";
use constant DEFAULT_INTERVAL => 60; # ping every 60 seconds

sub new {

	my $self = shift;
	my $class = ref($self) || $self;
	my $this = $class->SUPER::new('pinger');
	bless $this, $class;
	$this->name('pinger');
	$this->{'HOSTS'} = [];
	$this;

} # end sub new

sub Start {

	my $self = shift;

	my $interval = DEFAULT_INTERVAL;
	my $pidfile = DEFAULT_PID_FILE;
	my $hosts = '';

	my $events = '';
	my $logfile = '';
	my $pidfile = DEFAULT_PID_FILE;
	my @groups = ();
	my @exclude = ();

	my %options = ( 
			'events=s' => \$events, 
			'interval=s' => \$interval, 
			'events=s' => \$events, 
			'pidfile=s' => \$pidfile,
			'groups=s' => \@groups,
			'exclude=s' => \@exclude );

	$self->initialize(%options) || $self->pods();

	$self->logger()->debug(9,"Registering parser ...");
	$self->parser(sub { my @text = @_; $self->parse(@text); });
	$self->logger()->debug(9,"\tParser registered ...");

	# have the client parse the configuration file and 
	# get the configuration object which should be populated with the
	# standard command-line options and configuration information
	my $conf = $self->configure();

	unless ($conf->getOption('autodiscovery')) {
		$self->pods("Error:  Without autodiscovery you must provide a server and port option.")
			unless $conf->optionExists('server') && $conf->optionExists('port') &&
			       $conf->getOption('server') && $conf->getOption('port');
	}

	my @groups = $self->getGroups();
	my @exclude = $self->getExcluded();
	$self->logger()->debug(1,"Recognized event groups are [@groups]");
	$self->logger()->debug(1,"Excluded event groups are [@exclude]");

	# Check whether the pidfile option was set. If not, use the default
	unless ($conf->optionExists('pidfile') && $conf->getOption('pidfile')) {
		$self->logger()->debug(3,"No pid file specified. Using default [" . DEFAULT_PID_FILE . "]");
		$conf->setOption('pidfile', DEFAULT_PID_FILE);
	}

	# Check whether the interval option was set. If not, use the default
	unless ($conf->optionExists('interval') && $conf->getOption('interval')) {
		$self->logger()->debug(3,"No interval specified. Using default [" . DEFAULT_INTERVAL . "]");
		$conf->setOption('interval', DEFAULT_INTERVAL);
	}

	$self->logger()->debug(9,"Registering callback ...");
	$self->callback(sub { $self->loop(); });
	$self->logger()->debug(9,"\tCallback registered ...");
	$self->MainLoop($interval);

	return 1;

} # end sub Start

sub loop {

    my $self = shift;

    my $conf = $self->conf();

    my @hosts = grep $self->filter($_), $self->hosts();

    my $notifier = new Net::Peep::Notifier;

    for my $host (@hosts) {

	my $object = $host->host();
	my $name = $object->name();
	my $ip = $object->ip();
	$self->logger()->debug(7,"Pinging host [$name] with IP [$ip] ...");
	my $alive = ping( host => $ip );
	if ($alive) {
	    $self->logger()->debug(7,"\tHost [$name] is alive.");
	} else {
    	    $self->logger()->debug(7,"\tHost [$name] is unresponsive!");
	    my $eventname = $host->event();
	    my $location = $host->location();
	    my $priority = $host->priority();
	    my $status = $host->notification();
	    # send an event to the Peep server
	    $self->peck()->send(
				'pinger',
				'type'       => 0,
				'sound'      => $eventname,
				'location'   => $location,
				'priority'   => $priority,
				'volume'     => 255
				);

	    my $notification = new Net::Peep::Notification;

	    $notification->client('pinger');
	    $notification->hostname($Net::Peep::Notifier::HOSTNAME);
	    $notification->status($status);
	    $notification->datetime(time());
	    $notification->message("${Net::Peep::Notifier::HOSTNAME}:  Host [$name] with IP address [$ip] is unresponsive.");
	    
	    $notifier->notify($notification);

	}

    }

} # end sub loop

sub peck {

	my $self = shift;

	my $conf = $self->conf();

	unless (exists $self->{"__PEEP"}) {
		if ($conf->getOption('config')) {
			$self->{"__PEEP"} = Net::Peep::BC->new( $self->name(), $conf );
		} else {
			confess "Error:  Expecting options to have been parsed by now.";
		}
	}

	return $self->{"__PEEP"};

} # end sub peck

sub parse {

    my $self = shift;
    my $client = $self->name() || confess "Cannot parse logparser events:  Client name attribute not set.";
    my @text = @_;

    my $conf = $self->conf() || confess "Cannot parse logparser events:  Configuration object not found.";

    $self->logger()->debug(1,"\t\tParsing events for client [$client] ...");

    $self->tempParseDefaults(@text);

    my @hosts = $self->getConfigSection('hosts',@text);

    while (my $line = shift @hosts) {
	next if $line =~ /^\s*#/ || $line =~ /^\s*$/;

	my $name;
	if ($line =~ /^\s*([\w\-\.]+)\s+([\w\-]+)\s+([\w\-]+)\s+(\d+)\s+(\d+)\s+(info|warn|crit)\s+([\w\-\.]+)/) {

	    my ($name,$event,$group,$location,$priority,$notification,$hosts) = 
		($1,$2,$3,$4,$5,$6,$7);
	    my $host = new Net::Peep::Client::Pinger::Host;
	    $host->name($name);
	    $host->event($event);
	    $host->group($group);
	    $host->location($location);
	    $host->priority($priority);
	    $host->notification($notification);
	    $host->hosts($hosts);
	    
	    $self->addHost($host);
	    $self->logger()->debug(1,"\t\t\tClient host [$host] added.");

	}

    }
 

} # end sub parse

sub addHost {

    my $self = shift;
    my $host = shift || confess "Cannot add pinger host:  No host was provided.";
    push @{$self->{'HOSTS'}}, $host;
    return 1;

} # end sub addHost

sub hosts {

    # returns the list of hosts built with the addHost method
    my $self = shift;
    return wantarray ? @{$self->{'HOSTS'}} : $self->{'HOSTS'};

} # end sub hosts

1;

__END__

=head1 NAME

Net::Peep::Client::Pinger - Perl extension for checking whether a host
or a variety of services on a host are running

=head1 SYNOPSIS

  use Net::Peep::Client::Pinger;
  $pinger = new Net::Peep::Client::Pinger;
  $SIG{'INT'} = $SIG{'TERM'} = sub { $pinger->shutdown(); exit 0; };
  $pinger->Start();

=head1 DESCRIPTION

Perl extension for checking whether a host or a variety of services on
a host are running.  For now it only checks pingability.

It is intended to eventually check not only pingability, but services
such as telnet, ssh, ftp, etc.

=head2 EXPORT

None by default.

=head2 METHODS

    new() - The constructor

    Start() - Begins pinging hosts and signaling events.  Terminates
    by entering the Net::Peep::Client->MainLoop() method.

    loop() - The callback called by the Net::Peep::Client->MainLoop()
    method.  See Net::Peep::Client for more information.

    parse(@text) - Callback given to the Net::Peep::Client->parser()
    method which parses the pinger client config section of the Peep
    configuration file.

    addHost($host) - Adds a Net::Peep::Client::Pinger::Host object to
    an array.

    hosts() - Retrieves an array of Net::Peep::Client::Pinger::Host
    objects added by the addHost method.


  

=head1 AUTHOR

Michael Gilfix <mgilfix@eecs.tufts.edu> Copyright (C) 2001

Collin Starkweather <collin.starkweather@colorado.edu>

=head1 SEE ALSO

perl(1), peepd(1), Net::Peep::BC, Net::Peep::Log, Net::Peep::Parser,
Net::Peep::Client, pinger.

http://peep.sourceforge.net

=cut
