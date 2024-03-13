use 5.008001; use strict; use warnings;

package Plack::Middleware::NeverExpire;

our $VERSION = '1.201';

BEGIN { require Plack::Middleware; our @ISA = 'Plack::Middleware' }

use Plack::Util ();

sub ONE_YEAR () { 31_556_930 } # 365.24225 days

# RFC 9110 Section 5.6.7
my @DAY = qw( Sun Mon Tue Wed Thu Fri Sat );
my @MON = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
sub FMT () { '%s, %02d %s %04d %02d:%02d:%02d GMT' }
sub imf_fixdate {
	my @f = gmtime $_[0];
	sprintf FMT, $DAY[$f[6]], $f[3], $MON[$f[4]], 1900+$f[5], @f[2,1,0];
}

my $cached_stamp = imf_fixdate my $cached_time = time;
sub inject_headers {
	$_[0][0] == 200 or return;
	my $h = $_[0][1];
	push @$h, 'Cache-Control', 'max-age=' . ONE_YEAR . ', public';
	my $now = time;
	$cached_time == $now or $cached_stamp = imf_fixdate ONE_YEAR + ( $cached_time = $now );
	Plack::Util::header_set( $h, Expires => $cached_stamp );
}

sub call { Plack::Util::response_cb( &{ shift->app }, \&inject_headers ) }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::NeverExpire - set expiration headers far in the future

=head1 SYNOPSIS

 # in app.psgi
 use Plack::Builder;
 
 builder {
     enable_if { $_[0]{'PATH_INFO'} =~ m!^/static/! } 'NeverExpire';
     $app;
 };

=head1 DESCRIPTION

This middleware adds headers to a response that allow proxies and browsers to
cache them for an effectively unlimited time. It is meant to be used in
conjunction with the L<Conditional|Plack::Middleware::Conditional> middleware.

=head1 INTERFACE

This middleware provides some functions for general use. They are not exported.

=head2 C<imf_fixdate>

This takes an epoch time and returns it as a timestamp formatted according to
L<S<RFC 9110 section 5.6.7>|https://datatracker.ietf.org/doc/html/rfc9110#name-date-time-formats>.

=head2 C<inject_headers>

This takes a L<PSGI> response array and adds the caching headers to it
if the status is 200.
It returns nothing.

=head1 SEE ALSO

=over 4

=item *

L<Plack::Middleware::Expires>

For most requests you want either immediate expiry with conditional C<GET>,
or indefinite caching, or on high-load websites maybe a very short expiry
duration for certain URIs (on the order of minutes or seconds, just to keep
them from getting hammered): fine-grained control is rarely needed. I wanted
a really trivial middleware for when it's not, so I wrote NeverExpire.

But when you need it, L<Expires|Plack::Middleware::Expires> will give you the
precise control over expiry durations that NeverExpire doesn't.

=back

=head1 AUTHOR

Aristotle Pagaltzis <pagaltzis@gmx.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Aristotle Pagaltzis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
