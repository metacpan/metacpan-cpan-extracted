package Proquint;
use strict;
use warnings;
use Carp ();
use Exporter::Tiny;

our $VERSION   = '0.003';
our @ISA       = 'Exporter::Tiny';
our @EXPORT_OK = (qw/uint32proquint proquint32uint hex2proquint proquint2hex/);
our @EXPORT_TAGS = ( all => \@EXPORT_OK );

my @UINT_TO_CONSONANT = (qw/ b d f g h j k l m n p r s t v z /);
my @UINT_TO_VOWEL     = (qw/ a i o u /);
my $CHARS_PER_CHUNK   = 5;
my $MASK_LAST2        = 0x3;
my $MASK_LAST4        = 0xF;
my $SEPARATOR         = '-';

my %CONSONANT_TO_UINT = do {
    my $i = 0;
    map { $_ => $i++ } @UINT_TO_CONSONANT;
};

my %VOWEL_TO_UINT = do {
    my $i = 0;
    map { $_ => $i++ } @UINT_TO_VOWEL;
};

sub _uint16_to_chunk {
    my $in  = shift // Carp::croak 'usage: _uint16_to_chunk($INTEGER)';
    my $out = '';

    foreach my $i ( 1 .. $CHARS_PER_CHUNK ) {
        if ( $i & 1 ) {
            $out .= $UINT_TO_CONSONANT[ $in & $MASK_LAST4 ];
            $in >>= 4;
        }
        else {
            $out .= $UINT_TO_VOWEL[ $in & $MASK_LAST2 ];
            $in >>= 2;
        }
    }
    scalar reverse $out;
}

# uint32proquint(0x7f000001) eq 'lusab-babad';
sub uint32proquint {
    my $in  = shift // Carp::croak 'usage: uint32proquint($INTEGER)';
    my $sep = shift // $SEPARATOR;

    Carp::croak('input out of range 0-0xFFFFFFFF')
      if $in < 0 or $in > 0xffffffff;

    _uint16_to_chunk( $in >> 16 ) . $sep . _uint16_to_chunk($in);
}

sub _chunk_to_uint16 {
    my $in = shift // Carp::croak 'usage: _chunk_to_uint16($INTEGER)';

    Carp::croak 'invalid chunk: ' . $in unless length($in) == $CHARS_PER_CHUNK;

    my $res = 0;
    foreach my $c ( split //, $in ) {
        if ( exists $CONSONANT_TO_UINT{$c} ) {
            $res <<= 4;
            $res += $CONSONANT_TO_UINT{$c};
        }
        elsif ( exists $VOWEL_TO_UINT{$c} ) {
            $res <<= 2;
            $res += $VOWEL_TO_UINT{$c};
        }
        else {
            Carp::croak 'invalid quint char: ' . $c;
        }
    }

    $res;
}

# proquint32uint('lusab-babad') == 0x7f000001;
sub proquint32uint {
    my $in  = shift // Carp::croak 'usage: proquint32uint($QUINT)';
    my $sep = shift // $SEPARATOR;

    $in =~ s/$sep//g;
    Carp::croak 'invalid quint: ' . $in
      unless not length($in) % $CHARS_PER_CHUNK;

    my @chunks = $in =~ m/(.{$CHARS_PER_CHUNK})/gx;
    Carp::croak 'invalid quint: ' . $in unless @chunks == 2;

    my $out = _chunk_to_uint16( $chunks[0] );
    $out <<= 16;
    $out += _chunk_to_uint16( $chunks[1] );
    $out;
}

# hex2proquint('7f00001') eq 'lusab-babad'
sub hex2proquint {
    my $in  = shift // Carp::croak 'usage: hex2proquint($HEXIDECIMAL)';
    my $sep = shift // $SEPARATOR;

    $in =~ s/^0[xX]//;

    Carp::croak 'input must be multiple of 4-characters'
      unless not length($in) % 4;

    join( $sep,
        map { _uint16_to_chunk( hex( '0x' . $_ ) ) } $in =~ m/(.{4})/g );
}

# proquint2hex('lusab-babad') eq '7f000001';
sub proquint2hex {
    my $in  = shift // Carp::croak 'usage: proquint2hex($QUINT)';
    my $sep = shift // $SEPARATOR;

    $in =~ s/$sep//g;
    Carp::croak 'invalid quint: ' . $in
      unless not length($in) % $CHARS_PER_CHUNK;

    my @chunks = $in =~ m/(.{$CHARS_PER_CHUNK})/g;
    Carp::croak 'invalid quint: ' . $in unless @chunks;

    join( '', map { sprintf( '%04x', _chunk_to_uint16($_) ) } @chunks );
}

1;

__END__

=head1 NAME

Proquint - convert to and from proquint strings

=head1 VERSION

0.003 (2018-01-03)

=head1 SYNOPSIS

    use Proquint ':all';

    my $quint = uint32proquint(0xCF000001);    # "lusab-babad"
    my $int   = proquint32uint($quint);        # 0xCF000001

    my $quint2 = hex2proquint("dead1234beef"); # "tupot-damuh-ruroz"
    my $hex    = proquint2hex($quint2);        # "dead1234beef"

=head1 DESCRIPTION

L<Proquints|https://arxiv.org/html/0901.4016> are readable, spellable,
and pronounceable identifiers. The B<Proquints> module converts 32-bit
integers and hexadecimal strings to and from proquints.

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2018 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

