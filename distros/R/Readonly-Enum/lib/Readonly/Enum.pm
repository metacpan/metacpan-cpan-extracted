package Readonly::Enum;

use v5.10;

use strict;
use warnings;

use version 0.77; our $VERSION = version->declare("v0.1.4");

use Scalar::Readonly qw/ readonly_on /;

=head1 NAME

Readonly::Enum - enumerated scalar values

=head1 SYNOPSIS

  use Readonly::Enum;

  # $foo = 1, $bar = 2, etc.

  Readonly::Enum my ($foo, $bar, $baz);

  # $foo = 0, $bar = 1, etc.

  Readonly::Enum my ($foo, $bar, $baz) => 0;

  # $foo = 0, $bar = 5, $baz = 6, etc.

  Readonly::Enum my ($foo, $bar, $baz) => (0, 5);

=head1 DESCRIPTION

This module provides some syntactic sugar for defining enumerated
scalar values.

It is to L<Readonly> what the L<enum> package is to L<constant>.
Unlike enumerated constants, these scalars can be used as hash keys
and interpolated in strings.

Unlike L<enum>, only integers are supported in this version.

=head1 STATUS

This module is no longer maintained. See L<Const::Exporter> for
similar functionality.

=head1 AUTHOR

Robert Rothenberg C<rrwo@cpan.org>.

=head1 LICENSE AND COPYRIGHT

Copyright 2013-2014 Robert Rothenberg.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

sub Readonly::Enum {

    my @vals  = grep { defined $_ } @_;

    my $i = 0;

    my $start = 0;

    for($i=0; $i<@_; $i++) {

	last if defined $_[$i];

	$start = @vals ? (shift @vals) : ++$start;

	readonly_on($_[$i] = $start);

    }
}


1;
