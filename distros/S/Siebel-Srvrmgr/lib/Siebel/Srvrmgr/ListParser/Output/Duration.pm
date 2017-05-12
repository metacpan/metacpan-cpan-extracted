package Siebel::Srvrmgr::ListParser::Output::Duration;

use warnings;
use strict;
use Moose::Role 2.1604;
use Carp;
use DateTime 1.12;

our $VERSION = '0.29'; # VERSION

=pod

=head1 NAME

Siebel::Srvrmgr::ListParser::Output::Duration - Moose role to deal with start and end time of objects

=head1 SYNOPSIS

    with 'Siebel::Srvrmgr::ListParser::Output::Duration';

=head1 DESCRIPTION

This L<Moose> role enables a class to deal with start and end time of it's instances, including calculating the duration
of the object life inside the Siebel Server.

=head1 ATTRIBUTES

=head2 start_datetime

A string representing the date and time the object was created.

The string will have the following format:

    YYYY-MM-DD hh:mm:ss

This is a required attribute duration object creation and it's read-only.

=cut

has 'start_datetime' =>
  ( is => 'ro', isa => 'Str', 'required' => 1, reader => 'get_start' );

=head2 curr_datetime

A L<DateTime> instance created during the object creation that is using this role.

In the absence of a value for C<end_time> attribute, this object will be used to calcule the value
returned by C<duration> method.

This is a read-only attribute.

=cut

has 'curr_datetime' => (
    is       => 'ro',
    isa      => 'DateTime',
    required => 0,
    builder  => '_get_now',
    reader   => 'get_current'
);

=head2 end_datetime

Same thing as C<start_time>, but representing when the object had finish anything that was doing
in the Siebel server. 

It is not a required attribute during creation and it is read-only. The default value for it
is an empty string.

=cut

has 'end_datetime' => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
    reader   => 'get_end',
    writer   => '_set_end',
    default  => ''
);

=head2 time_zone

The time_zone to be considered for the time stamps parsed, for having proper date and time as configured
in the Siebel Enterprise OS level.

This parameter has a default value fetched from the environment variable c<SIEBEL_TZ>, so this variable must
previously set before to avoid errors. See L<Siebel::Srvrmgr::Daemon> for that.

=cut

has 'time_zone' => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
    reader   => 'get_time_zone',
    builder  => '_set_time_zone'
);

sub _set_time_zone {
    confess
"The environment SIEBEL_TZ is not configured. See Siebel::Srvrmgr::Daemon perldoc for information"
      unless ( ( exists( $ENV{SIEBEL_TZ} ) )
        and ( defined( $ENV{SIEBEL_TZ} ) ) );
    my $tmp = $ENV{SIEBEL_TZ};

    # to avoid problems with taint mode
    $tmp =~ /^([\w\/\_]+)$/;
    return $1;
}

=head1 METHODS

=head2 get_time_zone

Returns the C<time_zone> attribute value.

=head2 get_start

Returns C<start_datetime> attribute value.

=head2 get_current

Returns C<curr_datetime> attribute value.

=head2 get_end

Returns C<end_datetime> attribute value.

=head2 fix_endtime

This method will check the value of C<end_time> attribute for inconsistences and set a sane value to it.

Any class using this role B<must> execute this method inside it's BUILD method. If there isn't one, you will
need to a create one to do that.

=cut

sub fix_endtime {
    my $self = shift;
    if ( $self->get_end eq '2000-00-00 00:00:00' ) {
        $self->_set_end('');
    }
}

=head2 is_running

This method checks if the object is still (supposely) running by the time it's data was recovered from C<srvrmgr>.

If returns true (1) or false (0);

=cut

sub is_running {
    my $self = shift;
    return ( $self->get_end eq '' ) ? 1 : 0;
}

sub _get_now {
    return DateTime->now;
}

=head2 get_datetime

Expects as parameter a string in the format of C<start_datetime> attribute.

Returns a L<DateTime> object representation of this string using the available timezone and locale information.

=cut

sub get_datetime {
    my ( $self, $timestamp ) = @_;
    my ( $date, $time ) =
      split( /\s/, $timestamp );
    my @date = split( /\-/, $date );
    my @time = split( /\:/, $time );
    return DateTime->new(
        year   => $date[0],
        month  => $date[1] * 1,    #forcing to be stored as a number
        day    => $date[2] * 1,
        hour   => $time[0] * 1,
        minute => $time[1] * 1,
        second => $time[2] * 1
    );
}

=head2 get_duration

Calculates how much time the object spent doing whatever it was doing, or, if it is not finished, 
how much time already spent doing that (using C<curr_datetime> attribute for that).

The return value is in seconds.

=cut

sub get_duration {
    my $self = shift;
    my $end;

    if ( $self->get_end ne '' ) {
        $end = $self->get_datetime( $self->get_end );
    }
    else {
        $end = $self->get_current;
    }

    my $duration =
      $end->subtract_datetime_absolute(
        $self->get_datetime( $self->get_start ) );
    return $duration->seconds;
}

=head1 SEE ALSO

=over

=item *

L<Moose::Manual::Roles>

=item *

L<DateTime>

=item *

L<Siebel::Srvrmgr::Daemon>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>.

This file is part of Siebel Monitoring Tools.

Siebel Monitoring Tools is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Siebel Monitoring Tools is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Siebel Monitoring Tools.  If not, see L<http://www.gnu.org/licenses/>.

=cut

1;
