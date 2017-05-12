package Net::Peep::Client::Sysmonitor::Uptime;

require 5.00503;
use strict;
# use warnings; # commented out for 5.005 compatibility
use Carp;
use Data::Dumper;
use Net::Peep::Host::Pool;

require Exporter;

use vars qw{ @ISA %EXPORT_TAGS @EXPORT_OK @EXPORT $VERSION };

@ISA = qw(Exporter);
%EXPORT_TAGS = ( 'all' => [ qw( ) ] );
@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
@EXPORT = qw( );
$VERSION = do { my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

sub new {

	my $self = shift;
	my $class = ref($self) || $self;
	my $this = {};
	bless $this, $class;

} # end sub new

sub name {

    my $self = shift;
    if (@_) { $self->{'NAME'} = shift; }
    return $self->{'NAME'};

} # end sub name

sub value {

    my $self = shift;
    if (@_) { $self->{'VALUE'} = shift; }
    return $self->{'VALUE'};

} # end sub value

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

sub state {

    my $self = shift;
    if (@_) { $self->{'STATE'} = shift; }
    return $self->{'STATE'};

} # end sub state

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

=head1 NAME

Net::Peep::Client::Sysmonitor::Proc - Perl extension for storing
process information for the sysmonitor client.

=head1 SYNOPSIS

  use Net::Peep::Client::Sysmonitor::Uptime;

=head1 DESCRIPTION

Perl extension for storing uptime (i.e., load and user) settings for
the sysmonitor client.

It basically provides a set of attributes which store uptime
information parsed from the Peep configuration file(s).

=head1 METHODS

    new() - The constructor

    name() - The name of the event.

    value() - A value associated the uptime statistic.  The value set
    here will determine the state information sent to the Peep daemon.

    location() - The sound location the server will use when playing
    the event.

    priority() - The priority the server will give to the event.

    state() - The state associated with this uptime statistic.

    notification() - The notification status associated with the
    event.  See Net::Peep::Notification for more information.

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
Net::Peep::Client::Sysmonitor, sysmonitor.

http://peep.sourceforge.net

=cut
