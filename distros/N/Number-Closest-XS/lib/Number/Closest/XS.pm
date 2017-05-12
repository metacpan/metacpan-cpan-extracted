package Number::Closest::XS;
use strict;
use warnings;
our $VERSION = "0.09";
my $XS_VERSION = $VERSION;
$VERSION = eval $VERSION;

require XSLoader;
XSLoader::load( "Number::Closest::XS", $XS_VERSION );

use base 'Exporter';
our @EXPORT_OK = qw(find_closest_numbers find_closest_numbers_around);
our %EXPORT_TAGS = (all => [@EXPORT_OK]);

=head1 NAME

Number::Closest::XS - find numbers closest to a given

=head1 VERSION

This document describes Number::Closest::XS version 0.09

=head1 SYNOPSIS

    use Number::Closest::XS qw(:all);
    my $res = find_closest_numbers($num, \@list, $amount);
    my $res2 = find_closest_numbers_around($num, \@list, $amount);

=head1 DESCRIPTION

Module provides functions to extract from the list numbers closest to the
given.

=head1 SUBROUTINES

=head2 find_closest_numbers($num, \@list, [$amount])

selects from the I<@list> up to I<$amount> numbers closest to the I<$num>. If
I<$amount> is not specified, is assumed to be 1.  Returns reference to the
array containing found numbers sorted by the distance from the I<$num>. The
sort is stable, so the numbers that have the same distance to the C<$num> will
be present in the result in the same order as in the C<@list>.
Distance between C<$num> and C<$x> computed as C<abs($num - $x)>.

=head2 find_closest_numbers_around($num, \@list, [$amount])

selects from the I<@list> up to I<$amount> numbers closest to the I<$num>.
Tries to select equal amounts of numbers from both sides of the I<$num>, but if
there are not enough numbers from one side will select more numbers from the
other. If I<$amount> is odd, then the last number will be closest to I<$num>,
e.g. if $num is 5, @list is 1, 2, 6, 7, and amount is 3 it will return 2, 6,
and 7, because 7 is closer to 5 than 1.  If I<$amount> is not specified, is
assumed to be 2. Returns reference to the array containing closest numbers
sorted by their values.

=cut

1;

__END__

=head1 SEE ALSO

L<Number::Closest>, L<Number::Closest::NonOO>

=head1 CAVEATS

Internally module coerses all numbers into double or long double depending on
perl compilation options. If perl was compiled with 64 bit integer support and
underlying platform does not support long double data type then during
conversion of integers into double some significant digits may be lost and
module may produce incorrect results. This only happens for integers that have
more significant bits than fraction part of the double (usually 52 bit). The
problem is known to be present on NetBSD and Windows if perl was compiled with
Microsoft compiler.

=head1 AUTHOR

Pavel Shaydo C<< <zwon at cpan.org> >>

=head1 THANKS

Thanks to Dana Jacobsen for reporting a bug with handling 64 bit integers and long doubles.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 Pavel Shaydo

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
