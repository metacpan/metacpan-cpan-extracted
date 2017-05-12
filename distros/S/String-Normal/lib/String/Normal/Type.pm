package String::Normal::Type;
use strict;
use warnings;

use String::Normal::Type::Business;
use String::Normal::Type::Address;
use String::Normal::Type::Phone;
use String::Normal::Type::State;
use String::Normal::Type::City;
use String::Normal::Type::Zip;
use String::Normal::Type::Title;

sub _scrub_value {
    my $value = shift;

    $value = _deaccent_value( $value );
    $value =~ tr/'//d;

    # replace all rejected charactes with space
    $value =~ s/[^a-z0-9#]/ /g;

    return $value
}

sub _deaccent_value {
    my $value = shift;

    # remove decorations and stem variations of single quotes
    $value =~ tr[àáâãäåæçèéêëìíîïñòóôõöøùúûüýÿ’`\x92]
                [aaaaaaaceeeeiiiinoooooouuuuyy'''];

    return $value;
}

1;

__END__
=head1 NAME

String::Normal::Type;

=head1 DESCRIPTION

Base class for String::Normal Types. Contains utility private
methods for defining transformation rules.

=head1 TYPE CLASSES

=over 4

=item * L<String::Normal::Type::Business>

=item * L<String::Normal::Type::Address>

=item * L<String::Normal::Type::City>

=item * L<String::Normal::Type::State>

=item * L<String::Normal::Type::Zip>

=item * L<String::Normal::Type::Phone>

=item * L<String::Normal::Type::Title>

=back

=head1 AUTHOR

Jeff Anderson, C<< <jeffa at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Jeff Anderson.

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
