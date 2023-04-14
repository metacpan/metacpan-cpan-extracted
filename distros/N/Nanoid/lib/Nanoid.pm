package Nanoid;
use 5.010;
use strict;
use warnings;

our $VERSION = "0.04";

use strict;
use warnings;

use POSIX qw(ceil);
use Carp qw(croak);
use Bytes::Random::Secure qw(random_bytes);

use constant DEFAULT_SIZE => 21;
use constant DEFAULT_ALPHABETS =>
    '_-0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';

sub generate {
    my (%opts) = @_;

    my $size     = $opts{size}     // DEFAULT_SIZE;
    my $alphabet = $opts{alphabet} // DEFAULT_ALPHABETS;

    my $alphabet_size = length $alphabet;

    if ( $size <= 0 ) {
        croak 'size must be greater than zero';
    }

    if ( $alphabet_size == 0 || $alphabet_size > 255 ) {
        croak 'alphabet must not empty and contain no more than 255 chars';
    }

    my @alphabet_array = split( '', $alphabet );
    my $mask = ( 2 << ( log( $alphabet_size - 1 ) / log(2) ) ) - 1;

    my $step = ceil( 1.6 * $mask * $size / $alphabet_size );
    my $id   = '';

    while (1) {
        my $bytes = [ unpack( 'C*', random_bytes($step) ) ];

        for my $idx ( 0 .. $step ) {
            my $byte;

            if ( defined $bytes->[$idx] ) {
                $byte = $bytes->[$idx] & $mask;

                if ( defined $alphabet_array[$byte] ) {
                    $id .= $alphabet_array[$byte];
                }
            }

            if ( length $id == $size ) {
                return $id;
            }
        }
    }

}

1;
__END__

=encoding utf-8

=head1 NAME

Nanoid - Perl implementation of L<Nano ID|https://github.com/ai/nanoid>

=head1 SYNOPSIS

    use Nanoid;

    my $default = Nanoid::generate();                                        # length 21 / use URL-friendly characters
    my $custom1 = Nanoid::generate(size => 10);                              # length 10 / use URL-friendly characters
    my $custom2 = Nanoid::generate(size => 10, alphabet => 'abcdef012345');  # length 10 / use 'abcdef012345' characters


=head1 DESCRIPTION

Nanoid is a tiny, secure, URL-friendly, unique string ID generator.

=head1 LICENSE

Copyright (C) Hatena Co., Ltd..

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

tkzwtks E<lt>tkzwtks@gmail.comE<gt>

=cut

