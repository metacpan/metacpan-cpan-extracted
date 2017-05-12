package Net::Peep::Client::Logparser::Event;

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

sub group {

    my $self = shift;
    if (@_) { $self->{'GROUP'} = shift; }
    return $self->{'GROUP'};

} # end sub group

sub letter {

    my $self = shift;
    if (@_) { $self->{'LETTER'} = shift; }
    return $self->{'LETTER'};

} # end sub letter

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

sub regex {

    my $self = shift;
    if (@_) { $self->{'REGEX'} = shift; }
    return $self->{'REGEX'};

} # end sub regex

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

Net::Peep::Client::Logparser::Event - Perl extension for storing event
information for the logparser client.

=head1 SYNOPSIS

  use Net::Peep::Client::Logparser::Event;

=head1 DESCRIPTION

Perl extension for storing event settings for the logparser client.

It basically provides a set of attributes which store event
information parsed from the Peep configuration file(s).

=head2 EXPORT

None by default.

=head1 METHODS

    new() - The constructor

    name() - The name of the event.

    group() - The group into which the event falls.

    letter() - The reference letter for the event.

    location() - The sound location the server will use when playing
    the event.

    priority() - The priority the server will use when playing the
    event.

    notification() - The notification status associated with the event.  See
    Net::Peep::Notification for more information.

    regex() - A Perl regular expression which will be used to perform
    a pattern match on lines from the log files parsed by the
    logparser client.

    hosts() - A list of comma-delimited host names or IP address on
    which this event will be checked.

    pool() - A pool of hosts in the form of a Net::Peep::Host::Pool
    object.  The pool is derived automatically the first time this
    method is accessed via the information contained in the hosts()
    method.

=head1 AUTHOR

Collin Starkweather <collin.starkweather@colorado.edu> Copyright (C) 2001

=head1 SEE ALSO

perl(1), peepd(1), Net::Peep::Conf, Net::Peep::Client,
Net::Peep::Client::Logparser, logparser.

http://peep.sourceforge.net

=cut
