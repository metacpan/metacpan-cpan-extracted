package SimpleFlake;
use 5.008001;
use strict;
use warnings;

use Time::HiRes qw(time);
use Math::BigInt lib => 'GMP';
use Bytes::Random::Secure qw(
  random_bytes random_bytes_base64 random_bytes_hex
);

our $VERSION = "0.11";

our $random;
our @map = ( 0 .. 9, "A" .. "Z", "a" .. "z" );

sub random {

    my ($class) = @_;

    unless ($random) {

        $random = Bytes::Random::Secure->new(
            Bits        => 64,
            NonBlocking => 1,
        );
    }

    return $random;
}

sub get_random_bits {

    my ( $class ) = @_;

    my $return = Math::BigInt->from_bin( unpack( 'B*', $class->random->bytes(8) ) );

    return $return;
}

sub get_millisecond_timestamp {

    my $epoch = 946702800;

    my $time = Math::BigInt->new( int( ( time - $epoch ) * 100_000_000 ) );
    return $time;
}

sub get_pid {

    return Math::BigInt->new($$);
}

sub get_flake {

    my $self = shift;

    my $timestamp = $self->get_millisecond_timestamp;
    my $random    = $self->get_random_bits;
    my $pid       = $self->get_pid;

    my $t = $timestamp->blsft(4) ;
    my $r =  $t->bior($pid);
    my $p = $t->blsft(32);
    my $y = $p->bior($random);
    my $a = base36encode($y->as_int);

    # Limit length to 16 chars
    return substr($a,0, 16)
}

sub base36encode {

    my $number = shift;

    my $output = "";
    my ( $q, $r );

    do {
        ( $q, $r ) = ( int( $number / 62 ), $number % 62 );
        $number /= 62;
        $output = $map[$r] . $output;
    } while ($q);

    return $output;
}

1;
__END__

=encoding utf-8

=head1 NAME

SimpleFlake - A perl implemantation of SimpleFlake. Inspired by https://github.com/SawdustSoftware/simpleflake

=head1 SYNOPSIS

    use SimpleFlake;

    my $hex_flake = SimpleFlake->get_flake;

=head1 DESCRIPTION

SimpleFlake is a unique ID Generation Module based on timestamp in milliseconds, the pid and a part of randomness

=head1 LICENSE

Copyright (C) Jens Gassmann - Software Entwicklung.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

=over 1

=item Jens Gassmann E<lt>jg@gassmann.itE<gt>

=back

=cut

