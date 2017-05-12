package Net::Peep::Client::Pinger::Host;

require 5.00503;
use strict;
# use warnings; # commented out for 5.005 compatibility
use Carp;
use Data::Dumper;
use Net::Peep::Host;
use Net::Peep::Host::Pool;

require Exporter;

use vars qw{ @ISA %EXPORT_TAGS @EXPORT_OK @EXPORT $VERSION };

@ISA = qw(Exporter Net::Peep::Host);
%EXPORT_TAGS = ( 'all' => [ qw( ) ] );
@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
@EXPORT = qw( );
$VERSION = do { my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

sub new {

	my $self = shift;
	my $class = ref($self) || $self;
	my $this = $class->SUPER::new();
	bless $this, $class;

} # end sub new

sub name {

    my $self = shift;
    if (@_) { $self->{'NAME'} = shift; }
    return $self->{'NAME'};

} # end sub name

sub host {

    my $self = shift;
    unless (exists $self->{'HOST'}) {
	my $name = $self->name() || confess "Cannot get host object:  No host name or IP address found.";
	my $host = new Net::Peep::Host;
	if ($host->isIP($name)) {
	    $host->ip($name);
	} else {
	    $host->name($name);
	}
	$self->{'HOST'} = $host;
    }
    return $self->{'HOST'};

} # end sub host

sub event {

    my $self = shift;
    if (@_) { $self->{'EVENT'} = shift; }
    return $self->{'EVENT'};

} # end sub event

sub group {

    my $self = shift;
    if (@_) { $self->{'GROUP'} = shift; }
    return $self->{'GROUP'};

} # end sub group

sub location {

    my $self = shift;
    if (@_) { $self->{'LOCATION'} = shift; }
    return $self->{'LOCATION'};

} # end sub location

sub priority {

    my $self = shift;
    if (@_) { $self->{'PRIORITY'} = shift; }
    return $self->{'PRIORITY'};

} # end sub priority

sub notification {

    my $self = shift;
    if (@_) { $self->{'NOTIFICATION'} = shift; }
    return $self->{'NOTIFICATION'};

} # end sub notification

sub hosts {

    my $self = shift;
    if (@_) { $self->{'HOSTS'} = shift; }
    return $self->{'HOSTS'};

} # end sub hosts

sub pool {

    my $self = shift;
    unless (exists $self->{'POOL'}) {
        my $hosts = $self->hosts() 
            || confess "Cannot get host pool:  No hosts have been identified yet.";
        my $pool = new Net::Peep::Host::Pool;
        $pool->addHosts($hosts);
        $self->{'POOL'} = $pool;
    }
    return $self->{'POOL'};

} # end sub pool

1;

__END__

# Below is stub documentation for your module. You better edit it!

=head1 NAME

Net::Peep::Client::Pinger::Host - Perl extension for storing
host information for the pinger client.

=head1 SYNOPSIS

  use Net::Peep::Client::Pinger::Host;

=head1 DESCRIPTION

Perl extension for storing host settings for the pinger client.

It basically provides a set of attributes which store process
information parsed from the Peep configuration file(s).

=head2 EXPORT

None by default.

=head2 METHODS

    new() - The constructor

    name() - The name or IP address of the host.

    host() - Returns a Net::Peep::Host object initialized with the
    name or IP address found in the name() method.

    event() - The event associated with this host.

    group() - The group name associated with this host.

    location() - The sound location the server will use when playing
    the event.

    priority() - The priority the server will give to the event.

    notification() - The notification status associated with the event.  See
    Net::Peep::Notification for more information.

    hosts() - A list of comma-delimited host names or IP address on
    which this process will be checked.

    pool() - A pool of hosts in the form of a Net::Peep::Host::Pool
    object.  The pool is derived automatically the first time this
    method is accessed via the information contained in the hosts()
    method.

=head1 AUTHOR

Collin Starkweather <collin.starkweather@colorado.edu> Copyright (C) 2001

=head1 SEE ALSO

perl(1), peepd(1), Net::Peep::Conf, Net::Peep::Client,
Net::Peep::Client::Pinger, pinger.

http://peep.sourceforge.net

=cut
