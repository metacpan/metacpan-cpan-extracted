package Steemit::Base58;
use Modern::Perl;

=head1 NAME

Steemit::Base58 - perl library for base58 encoding the bitcoin way

=head1 SYNOPSIS

    use Steemit::Base58

    my $binary = Steemit::Base58::decode_base58( $base58_string )
    my $base58 = Steemit::Base58::encode_base58( $binary )

=cut

use Math::BigInt try => 'GMP,Pari';
use Carp;

# except 0 O D / 1 l I
my $chars = [qw(
    1 2 3 4 5 6 7 8 9

    A B C D E F G H J
    K L M N P Q R S T
    U V W X Y Z

    a b c d e f g h i
    j k m n o p q r s
    t u v w x y z

)];
my $test = qr/^[@{[ join "", @$chars ]}]+$/;

my $map = do {
    my $i = 0;
    +{ map { $_ => $i++ } @$chars };
};

sub encode_base58 {
    my ($binary) = @_;
    return $chars->[0] unless $binary;

    my $bigint = Math::BigInt->from_bytes($binary);
    my $base58 = '';
    my $base = @$chars;

    while ($bigint->is_pos) {
        my ($quotient, $rest ) = $bigint->bdiv($base);
        $base58 = $chars->[$rest] . $base58;
    }

    return $base58;
}

sub decode_base58 {
    my $base58 = shift;
    $base58 =~ tr/0OlI/DD11/;
    $base58 =~ $test or croak "Invalid Base58";

    my $decoded = Math::BigInt->new(0);
    my $multi   = Math::BigInt->new(1);
    my $base    = @$chars;

    while (length $base58 > 0) {
        my $digit = chop $base58;
        $decoded->badd($multi->copy->bmul($map->{$digit}));
        $multi->bmul($base);
    }

    return $decoded->to_bytes;
}


1;


=head1 REPOSITORY

L<https://github.com/snkoehn/perlSteemit>


=head1 AUTHOR

snkoehn, C<< <koehn.sebastian at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-steemit at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Steemit::WsClient>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Steemit::WsClient


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Steemit::WsClient>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Steemit::WsClient>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Steemit::WsClient>

=item * Search CPAN

L<http://search.cpan.org/dist/Steemit::WsClient/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2018 snkoehn.

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

