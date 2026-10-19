package Peta::MP3::Encode::Filterbank::PDL;
# ABSTRACT: Layer III's filterbank with PDL

# The filterbank of Peta::MP3::Encode::Filterbank in PDL: the same
# arithmetic, as a handful of whole-array operations per granule.
#
#   windowed sums   the samples gathered by an index of (8, 64, 18), times
#                   the window, summed over the 8
#   matrixing       a matrix product: (64, 18) times (32, 64)
#   MDCT            a matrix product per window: the 36 inputs of the 32
#                   subbands times the window's (18, 36), or the three short
#                   windows' (6, 12)
#   butterflies     two slices of 8 lines by 31 subbands

use v5.36;

# PDL exports dozens of functions into a package. They go to a package of
# their own, and this one calls PDL by name.
{
    package Peta::MP3::Encode::Filterbank::PDL::Imports;
    use PDL::LiteF;
}

use Peta::MP3::Encode::Filterbank;
use Peta::MP3::Encode::Tables;

our $VERSION = '0.2610180';

use constant SHORT => 2;    # the block type of short blocks

# A piddle of doubles from a list, in the dimensions given.
sub _pdl ($list, @dims) { return PDL->pdl(PDL::double(), $list)->reshape(@dims) }

# What every bank shares, made once, the first time a bank is made.
my %SHARED;

sub _shared () {
    return \%SHARED if %SHARED;

    # The windowed sums: which sample each term reads, (8, 64, 18), and the
    # window it is weighed by, (8, 64).
    my (@index, @window);
    for my $t (0 .. 17) {
        for my $i (0 .. 63) {
            for my $j (0 .. 7) {
                push @index,  511 + 32 * $t - $i - 64 * $j;
                push @window, $Peta::MP3::Encode::Tables::WINDOW[ $i + 64 * $j ] if $t == 0;
            }
        }
    }
    $SHARED{index}  = PDL->pdl(PDL::long(), \@index)->reshape(8, 64, 18);
    $SHARED{window} = _pdl(\@window, 8, 64);

    # The matrixing (32, 64) and the subbands' signs (32, 18).
    my @matrix = map { Peta::MP3::Encode::Filterbank::matrixing($_ % 32, int($_ / 32)) } 0 .. 2047;
    my @sign   = map { Peta::MP3::Encode::Filterbank::sign(int($_ / 32), $_ % 32) } 0 .. 575;
    $SHARED{matrix} = _pdl(\@matrix, 32, 64);
    $SHARED{sign}   = _pdl(\@sign, 32, 18);

    # The MDCTs: element (m, k) of each long window's (18, 36), and of the short (6, 12).
    for my $type (0, 1, 3) {
        my @long = map { Peta::MP3::Encode::Filterbank::long_mdct($type, $_ % 18, int($_ / 18)) } 0 .. 647;
        $SHARED{long}{$type} = _pdl(\@long, 18, 36);
    }
    my @short = map { Peta::MP3::Encode::Filterbank::short_mdct($_ % 6, int($_ / 6)) } 0 .. 71;
    $SHARED{short} = _pdl(\@short, 6, 12);

    my ($cs, $ca) = Peta::MP3::Encode::Filterbank::butterflies();
    $SHARED{cs} = _pdl($cs, 8);
    $SHARED{ca} = _pdl($ca, 8);

    return \%SHARED;
}

sub new ($class, $rate) {
    return bless {
        shared   => _shared(),
        history  => PDL->zeroes(PDL::double(), 480),
        previous => PDL->zeroes(PDL::double(), 32, 18),
        order    => PDL->pdl(PDL::long(), Peta::MP3::Encode::Filterbank::short_order($rate)),
    }, $class;
}

# The lines of the next granule of 576 samples, in a block type's window.
sub granule ($self, $samples, $type) {
    my $s   = $self->{shared};
    my $buf = $self->{history}->append(_pdl($samples, 576));
    $self->{history} = $buf->slice('576:1055')->copy;

    # The subband samples, (32, 18): sub[sb, t]. The MDCT's inputs, (36, 32): in[k, sb].
    my $y   = ($buf->index($s->{index}) * $s->{window})->sumover;    # (64, 18)
    my $sub = ($y x $s->{matrix}) * $s->{sign};
    my $in  = $self->{previous}->transpose->append($sub->transpose);
    $self->{previous} = $sub;

    return [ $self->_short($in)->list ] if $type == SHORT;
    return [ _long($in, $s, $type)->list ];
}

# A long block: the MDCT, (18, 32), line 18 sb + m; then the butterflies.
sub _long ($in, $s, $type) {
    my $xr   = $in x $s->{long}{$type};
    my $up   = $xr->slice('17:10', '0:30');
    my $down = $xr->slice('0:7', '1:31');
    my $u    = $up->copy;
    my $d    = $down->copy;
    $up   .= $u * $s->{cs} + $d * $s->{ca};
    $down .= $d * $s->{cs} - $u * $s->{ca};
    return $xr->reshape(576);
}

# A short block: three windows of 12 inputs, from 6, 12 and 18, (6, 32)
# each; side by side as (3, 6, 32), line 18 sb + 3 m + w; then in the
# bitstream's order.
sub _short ($self, $in) {
    my $short = $self->{shared}{short};
    my @windows = map { $in->slice((6 + 6 * $_) . ':' . (17 + 6 * $_)) x $short } 0 .. 2;
    my $mdct = PDL::cat(@windows)->mv(2, 0)->reshape(576);
    return $mdct->index($self->{order});
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::MP3::Encode::Filterbank::PDL - Layer III's filterbank with PDL

=head1 VERSION

version 0.2610180

=head1 SYNOPSIS

    my $bank = Peta::MP3::Encode::Filterbank::PDL->new(44100);
    my $xr   = $bank->granule(\@samples, $block_type);

=head1 DESCRIPTION

What L<Peta::MP3::Encode::Filterbank> computes, as whole-array operations:
the same lines, to rounding.

=head1 METHODS

=head2 new, granule

As L<Peta::MP3::Encode::Filterbank>'s.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
