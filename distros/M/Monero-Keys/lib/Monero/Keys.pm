package Monero::Keys;

use strict;
use warnings;
use Crypt::Digest::Keccak256 qw(keccak256);
use Math::BigInt;

our $VERSION = '0.04';

require XSLoader;
XSLoader::load('Monero::Keys', $VERSION);

sub load3 {
    my ($b, $index) = @_;
    my $result = substr($b, $index, 3) . "\x0";
    return Math::BigInt->new(unpack("V", $result));
}

sub load4 {
    my ($b, $index) = @_;
    my $result = substr($b, $index, 4);
    return Math::BigInt->new(unpack("V", $result));
}

sub sc_reduce {
    my ($b) = @_;
    my $s0 = 2097151 & load3($b, 0);
    my $s1 = 2097151 & (load4($b, 2) >> 5);
    my $s2 = 2097151 & (load3($b, 5) >> 2);
    my $s3 = 2097151 & (load4($b, 7) >> 7);
    my $s4 = 2097151 & (load4($b, 10) >> 4);
    my $s5 = 2097151 & (load3($b, 13) >> 1);
    my $s6 = 2097151 & (load4($b, 15) >> 6);
    my $s7 = 2097151 & (load3($b, 18) >> 3);
    my $s8 = 2097151 & load3($b, 21);
    my $s9 = 2097151 & (load4($b, 23) >> 5);
    my $s10 = 2097151 & (load3($b, 26) >> 2);
    my $s11 = load4($b, 28) >> 7;
    my $s12 = 0;

    my $carry0 = ($s0 + (1 << 20)) >> 21; $s1 += $carry0; $s0 -= $carry0 << 21;
    my $carry2 = ($s2 + (1 << 20)) >> 21; $s3 += $carry2; $s2 -= $carry2 << 21;
    my $carry4 = ($s4 + (1 << 20)) >> 21; $s5 += $carry4; $s4 -= $carry4 << 21;
    my $carry6 = ($s6 + (1 << 20)) >> 21; $s7 += $carry6; $s6 -= $carry6 << 21;
    my $carry8 = ($s8 + (1 << 20)) >> 21; $s9 += $carry8; $s8 -= $carry8 << 21;
    my $carry10 = ($s10 + (1 << 20)) >> 21; $s11 += $carry10; $s10 -= $carry10 << 21;

    my $carry1 = ($s1 + (1 << 20)) >> 21; $s2 += $carry1; $s1 -= $carry1 << 21;
    my $carry3 = ($s3 + (1 << 20)) >> 21; $s4 += $carry3; $s3 -= $carry3 << 21;
    my $carry5 = ($s5 + (1 << 20)) >> 21; $s6 += $carry5; $s5 -= $carry5 << 21;
    my $carry7 = ($s7 + (1 << 20)) >> 21; $s8 += $carry7; $s7 -= $carry7 << 21;
    my $carry9 = ($s9 + (1 << 20)) >> 21; $s10 += $carry9; $s9 -= $carry9 << 21;
    my $carry11 = ($s11 + (1 << 20)) >> 21; $s12 += $carry11; $s11 -= $carry11 << 21;

    $s0 += $s12 * 666643;
    $s1 += $s12 * 470296;
    $s2 += $s12 * 654183;
    $s3 -= $s12 * 997805;
    $s4 += $s12 * 136657;
    $s5 -= $s12 * 683901;
    $s12 = 0;

    $carry0 = $s0 >> 21; $s1 += $carry0; $s0 -= $carry0 << 21;
    $carry1 = $s1 >> 21; $s2 += $carry1; $s1 -= $carry1 << 21;
    $carry2 = $s2 >> 21; $s3 += $carry2; $s2 -= $carry2 << 21;
    $carry3 = $s3 >> 21; $s4 += $carry3; $s3 -= $carry3 << 21;
    $carry4 = $s4 >> 21; $s5 += $carry4; $s4 -= $carry4 << 21;
    $carry5 = $s5 >> 21; $s6 += $carry5; $s5 -= $carry5 << 21;
    $carry6 = $s6 >> 21; $s7 += $carry6; $s6 -= $carry6 << 21;
    $carry7 = $s7 >> 21; $s8 += $carry7; $s7 -= $carry7 << 21;
    $carry8 = $s8 >> 21; $s9 += $carry8; $s8 -= $carry8 << 21;
    $carry9 = $s9 >> 21; $s10 += $carry9; $s9 -= $carry9 << 21;
    $carry10 = $s10 >> 21; $s11 += $carry10; $s10 -= $carry10 << 21;
    $carry11 = $s11 >> 21; $s12 += $carry11; $s11 -= $carry11 << 21;

    $s0 += $s12 * 666643;
    $s1 += $s12 * 470296;
    $s2 += $s12 * 654183;
    $s3 -= $s12 * 997805;
    $s4 += $s12 * 136657;
    $s5 -= $s12 * 683901;

    $carry0 = $s0 >> 21; $s1 += $carry0; $s0 -= $carry0 << 21;
    $carry1 = $s1 >> 21; $s2 += $carry1; $s1 -= $carry1 << 21;
    $carry2 = $s2 >> 21; $s3 += $carry2; $s2 -= $carry2 << 21;
    $carry3 = $s3 >> 21; $s4 += $carry3; $s3 -= $carry3 << 21;
    $carry4 = $s4 >> 21; $s5 += $carry4; $s4 -= $carry4 << 21;
    $carry5 = $s5 >> 21; $s6 += $carry5; $s5 -= $carry5 << 21;
    $carry6 = $s6 >> 21; $s7 += $carry6; $s6 -= $carry6 << 21;
    $carry7 = $s7 >> 21; $s8 += $carry7; $s7 -= $carry7 << 21;
    $carry8 = $s8 >> 21; $s9 += $carry8; $s8 -= $carry8 << 21;
    $carry9 = $s9 >> 21; $s10 += $carry9; $s9 -= $carry9 << 21;
    $carry10 = $s10 >> 21; $s11 += $carry10; $s10 -= $carry10 << 21;
    $DB::single = 1;
    my @items = (
        $s0 >> 0,
        $s0 >> 8,
        ($s0 >> 16) | ($s1 << 5),
        $s1 >> 3,
        $s1 >> 11,
        ($s1 >> 19) | ($s2 << 2),
        $s2 >> 6,
        ($s2 >> 14) | ($s3 << 7),
        $s3 >> 1,
        $s3 >> 9,
        ($s3 >> 17) | ($s4 << 4),
        $s4 >> 4,
        $s4 >> 12,
        ($s4 >> 20) | ($s5 << 1),
        $s5 >> 7,
        ($s5 >> 15) | ($s6 << 6),
        $s6 >> 2,
        $s6 >> 10,
        ($s6 >> 18) | ($s7 << 3),
        $s7 >> 5,
        $s7 >> 13,
        $s8 >> 0,
        $s8 >> 8,
        ($s8 >> 16) | ($s9 << 5),
        $s9 >> 3,
        $s9 >> 11,
        ($s9 >> 19) | ($s10 << 2),
        $s10 >> 6,
        ($s10 >> 14) | ($s11 << 7),
        $s11 >> 1,
        $s11 >> 9,
        $s11 >> 17
    );

    my $newb = '';
    for my $i (@items) {
        $newb .= chr($i & 0xFF);
    }
    return $newb;
}

sub _is_not_zero {
    my $b = shift;
    for my $i (0..31) {
        return 1 if ord(substr($b, $i, 1)) != 0;
    }
    return 0;
}

sub generate_keys {
    my $seed = shift;
    if (length($seed) < 32) {
        $seed .= "\x00" x (32 - length($seed));
    }
    my $spend_pk = sc_reduce($seed);
    my $spend_pub = _generate_pk_from_sk($spend_pk);
    return undef unless _is_not_zero($spend_pk);
    my $keccak = keccak256($spend_pk);
    my $view_pk = sc_reduce($keccak);
    return undef unless _is_not_zero($view_pk);
    return {
        spend_pk  => $spend_pk,
        spend_pub => $spend_pub,
        view_pk   => $view_pk,
        view_pub  => _generate_pk_from_sk($view_pk),
    };
}
# Preloaded methods go here.

1;
__END__

=head1 NAME

Monero::Keys - module to generate Monero cryptocurrency compatible keys.
Monero pulic key generation algorithm varies from standard Ed25519.

=head1 SYNOPSIS

  use Monero::Keys;

  my $keys;
  do {
      my $seed = random_32_bytes();
      $keys = Monero::Keys::generate_keys($seed);
  } while (!defined($keys));
  printf ("Spend Private key:%s \n", unpack('H*', $keys->{spend_pk}));
  printf ("Spend Public key:%s \n", unpack('H*', $keys->{spend_pub}));
  printf ("View Private key:%s \n", unpack('H*', $keys->{view_pk}));
  printf ("View Public key:%s \n", unpack('H*', $keys->{view_pub}));

=head1 DESCRIPTION

=over

=item generate_keys($seed)

This function generates Monero compatible keys from 32 bytes seed.
The valid private keys in monero should less than L (L is 2^252 + 27742317777372353535851937790883648493).
So private key = mod(seed, L). In case of seed is multiple of L, the function will return undef.
In that case try another seed.
The seed should be cryptographically secure random 32 bytes.

=back

=head1 SEE ALSO

This module uses XS code from Crypt::PK::Ed25519 for point generation.
It also uses sc_reduce32 function from Monero codebase for mod L operation.

=head1 AUTHOR

Denys Fisher, E<lt>shmakins at gmail dot comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2025 by Denys Fisher

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.34.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
