package Pcore::Util::Random;

use Pcore -export;
use Net::SSLeay qw[];

our $EXPORT = { ALL => [qw[random_bytes random_bytes_hex]] };

our $PASSWORD_LENGTH = 16;

my $PASSWORD_SYMBOLS = [ 0 .. 9, 'a' .. 'z', 'A' .. 'Z', qw[! @ $ % ^ & *], q[#] ];
my $_PASSWORD_RANGE  = [ map { $PASSWORD_SYMBOLS->[ $_ % $PASSWORD_SYMBOLS->@* ] } 0x00 .. 0xFF ];

*random_bytes     = \&bytes;
*random_bytes_hex = \&bytes_hex;

sub bytes ($len) {
    Net::SSLeay::RAND_bytes( my $buf, $len );

    return $buf;
}

sub bytes_hex ($len) {
    return unpack 'H*', &bytes;    ## no critic qw[Subroutines::ProhibitAmpersandSigils]
}

sub password ($len = $PASSWORD_LENGTH) {
    return join $EMPTY, map { $_PASSWORD_RANGE->[ord] } split //sm, bytes($len);
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Random

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
