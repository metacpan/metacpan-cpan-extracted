package Net::OAuth::SignatureMethod;

use strict;
use warnings;

# SPDX-SnippetBegin
# SPDX-SnippetCopyrightText: 2021 by Leon Timmermans.
# SPDX-License-Identifier: The Artistic License 2.0 (GPL Compatible)

sub secure_compare {
    my ( $self, $up, $down ) = @_;
    my $r     = length $up != length $down;
    my $left  = $up . $down;
    my $right = $down . $up;
    $r |= ord( substr $left, $_, 1 ) ^ ord( substr $right, $_, 1 ) for 0 .. length($left) - 1;
    return $r == 0;
}

# SPDX-SnippetEnd

=head1 NAME

Net::OAuth::SignatureMethod - a base class for signature methods

=head1 SEE ALSO

L<Net::OAuth>

=head1 AUTHOR

This uses the C<secure_compare> function from L<Crypt::Passphrase::Validator> by  Leon Timmermans.

=cut

1;
