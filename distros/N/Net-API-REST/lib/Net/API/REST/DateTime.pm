# -*- perl -*-
##----------------------------------------------------------------------------
## REST API Framework - ~/lib/Net/API/REST/DateTime.pm
## Version v1.0.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/12/15
## Modified 2023/06/10
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::REST::DateTime;
BEGIN
{
	use strict;
    use warnings;
	use common::sense;
	use parent qw( Apache2::API::DateTime );
	use vars qw( $VERSION );
	our $VERSION = 'v1.0.0';
};

use strict;
use warnings;

1;
# NOTE: pod
__END__

=encoding utf8

=head1 NAME

Net::API::REST::DateTime - HTTP DateTime Manipulation and Formatting

=head1 SYNOPSIS

	use Net::API::REST::DateTime;
	my $d = Net::API::REST::DateTime->new( debug => 3 );
	my $dt = DateTime->now;
	$dt->set_formatter( $d );
	print( "$dt\n" );
	## will produce
	Sun, 15 Dec 2019 15:32:12 GMT
	
	my( @parts ) = $d->parse_date( $date_string );
	
	my $datetime_object = $d->str2datetime( $date_string );
	$datetime_object->set_formatter( $d );
	my $timestamp_in_seconds = $d->str2time( $date_string );
	my $datetime_object = $d->time2datetime( $timestamp_in_seconds );
	my $datetime_string = $d->time2str( $timestamp_in_seconds );

=head1 VERSION

    v1.0.0

=head1 DESCRIPTION

This module contains methods to create and manipulate datetime representation from and to C<DateTime> object or unix timestamps.

When using it as a formatter to a C<DateTime> object, this will make sure it is properly formatted for its use in http headers and cookies.

As of version <v1.0.0> it completely inherits from L<Apache2::API::DateTime>

=head1 METHODS

=head2 new( hash )

This initiates the package and take the following parameters:

=over 4

=item I<debug>

Optional. If set with a positive integer, this will activate verbose debugging message

=back

=head2 format_datetime( $date_time_object )

Provided a C<DateTime> object, this returns a http compliant string representation, such as:

	Sun, 15 Dec 2019 15:32:12 GMT

that can be used in http headers and cookies' expires property as per rfc6265.

=head2 parse_date( string )

Given a datetime string, this returns, in list context, a list of day, month, year, hour, minute, second and time zone or an iso 8601 datetime string in scalar context.

This is used by the method B<str2datetime>

=head2 str2datetime( string )

Given a string that looks like a date, this will parse it and return a C<DateTime> object.

=head2 str2time( string )

Given a string that looks like a date, this returns its representation as a unix timestamp in second since epoch.

In the background, it calls B<str2datetime> for parsing.

=head2 time2datetime( timestamp in seconds )

Given a unix timestamp in seconds since epoch, this returns a C<DateTime> object.

=head2 time2str( timestamp in seconds )

Given a unix timestamp in seconds since epoch, this returns a string representation of the timestamp suitable for http headers and cookies. The format is like C<Sat, 14 Dec 2019 22:12:30 GMT>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

CPAN ID: jdeguest

L<https://gitlab.com/jackdeguest/Net-API-REST>

=head1 SEE ALSO

C<DateTime>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2018-2019 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.

=cut
