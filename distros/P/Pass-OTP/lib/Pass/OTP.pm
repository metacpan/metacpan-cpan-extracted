package Pass::OTP;

=encoding utf8

=head1 NAME

Pass::OTP - Perl implementation of HOTP / TOTP algorithms

=head1 SYNOPSIS

    use Pass::OTP qw(otp);
    use Pass::OTP::URI qw(parse);

    my $uri = "otpauth://totp/ACME:john.doe@email.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=ACME&digits=6";
    my $otp_code = otp(parse($uri));

=cut

use utf8;
use strict;
use warnings;

use Convert::Base32 qw(decode_base32);
use Digest::HMAC;
use Digest::SHA;
use Math::BigInt;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(otp hotp totp);

our $VERSION = '1.7';

=head1 DESCRIPTION

The C<Pass::OTP> module provides implementation of HOTP and TOTP algorithms according to the RFC 4226 and RFC 6238.

=head1 FUNCTIONS

=over 4

=item hotp(%options)

Computes HMAC-based One-time Password (RFC 4226).

    HOTP(K,C) = Truncate(HMAC-SHA-1(K,C))

Step 1: Generate an HMAC-SHA-1 value

    Let HS = HMAC-SHA-1(K,C)

Step 2: Generate a 4-byte string (Dynamic Truncation)

    Let Sbits = DT(HS)

Step 3: Compute an HOTP value

    Let Snum = StToNum(Sbits)       # Convert S to a number in 0..2^{31}-1
    Return D = Snum mod 10^Digit    # D us a number in the range 0..10^{Digit}-1

=cut

sub hotp {
    my %options = (
        algorithm => 'sha1',
        counter   => 0,
        digits    => 6,
        @_,
    );

    my $C = Math::BigInt->new($options{counter});

    my ($hex) = $C->as_hex =~ /^0x(.*)/;
    $hex = "0" x (16 - length($hex)) . $hex;

    my ($algorithm) = $options{algorithm} =~ /sha(\d+)/i;
    my $digest = Digest::SHA->new($algorithm);
    my $hmac   = Digest::HMAC->new(
        $options{base32} ? decode_base32($options{secret} =~ s/ //gr) : pack('H*', $options{secret}),
        $digest,
        $algorithm < 384? 64 : 128,
    );
    $hmac->add(pack 'H*', $hex);
    my $hash = $hmac->digest;

    my $offset = hex(substr(unpack('H*', $hash), -1));
    my $bin_code = unpack('N', substr($hash, $offset, 4));
    $bin_code &= 0x7fffffff;
    $bin_code = Math::BigInt->new($bin_code);

    if (defined $options{chars}) {
        my $otp = "";
        foreach (1 .. $options{digits}) {
            $otp .= substr($options{chars}, $bin_code->copy->bmod(length($options{chars})), 1);
            $bin_code = $bin_code->btdiv(length($options{chars}));
        }
        return $otp;
    }
    else {
        my $otp = $bin_code->bmod(10**$options{digits});
        return "0" x ($options{digits} - length($otp)) . $otp;
    }
}

=item totp(%options)

Computes Time-based One-time Password (RFC 6238).

    TOTP = HOTP(K,T)
    T = (Current Unix time - T0) / X

=cut

sub totp {
    my %options = (
        'start-time' => 0,
        now          => time,
        period       => 30,
        @_,
    );

    $options{counter} = Math::BigInt->new(int(($options{now} - $options{'start-time'}) / $options{period}));
    return hotp(%options);
}

=item otp(%options)

Convenience wrapper which calls totp/hotp according to options.

=cut

sub otp {
    my %options = (
        type => 'hotp',
        @_,
    );

    return totp(
        %options,
        digits => 5,
        chars  => "23456789BCDFGHJKMNPQRTVWXY",
    ) if defined $options{issuer} and $options{issuer} =~ /^Steam/i;

    return hotp(%options) if $options{type} eq 'hotp';
    return totp(%options) if $options{type} eq 'totp';
}

=back

=head1 SEE ALSO

L<Digest::HMAC>

L<oathtool(1)>

RFC 4226
RFC 6238

L<https://github.com/google/google-authenticator/wiki/Key-Uri-Format>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 Jan Baier

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
