package Peta::Synth::Engine::PDL;
# ABSTRACT: the voices rendered with PDL

# The engine on PDL: the partials of many voices at once, as whole-array
# operations, in double precision.
#
# A partial is the same rotating phasor as in the Perl engine, but the
# phasors are not turned one by one: those of every partial, in every
# control block, of a group of voices are one array, (partial, block,
# voice), and the 64 samples of a block are 64 turns of all of them. A
# sin() per sample would cost more than the turn's four multiplications.
#
# The voices of a group are padded to the group's largest number of
# partials (with partials of no amplitude); the voices are grouped by their
# number of partials, so that little is padded, and so that an array stays
# small enough for the processor's cache.
#
# The noise band-pass is a recursion, sample after sample, and stays in
# Perl (Peta::Synth::Engine::Perl::noise).

use v5.36;

# PDL exports dozens of functions into a package; they go to one of their
# own, and this one calls PDL by name.
{
    package Peta::Synth::Engine::PDL::Imports;
    use PDL::LiteF;
}

use Peta::Synth::Engine::Perl;

our $VERSION = '0.2610180';

use constant BLOCK  => 64;
use constant TWO_PI => 6.283185307179586;
use constant ROWS   => 16384;    # phasors in an array at most: (partials x blocks x voices)

sub new ($class, %arg) { return bless { %arg }, $class }
sub name ($self) { return 'pdl' }

sub render ($self, $voices, $n, $rate) {
    my $B  = BLOCK;
    my $nb = $n / $B;
    my $left  = PDL->zeroes(PDL::double(), $B, $nb);
    my $right = PDL->zeroes(PDL::double(), $B, $nb);
    my $send  = PDL->zeroes(PDL::double(), $B, $nb);

    # Groups of voices with about as many partials, each small enough (a
    # voice read from wave sequences has none here).
    my $parts = sub ($voice) { $voice->{wave} ? 0 : scalar @{ $voice->{ratio} } };
    my @order = sort { $parts->($b) <=> $parts->($a) } @$voices;
    while (@order) {
        my $k     = $parts->($order[0]) || 1;
        my $count = int(ROWS / ($k * $nb)) || 1;
        my @group = splice @order, 0, $count;
        my ($l, $r, $s) = _group(\@group, $k, $n, $nb, $rate);
        $left  += $l;
        $right += $r;
        $send  += $s;
    }
    return map { [ $_->list ] } $left, $right, $send;
}

# A group of voices of at most $k partials: (left, right, send), each of
# dims (B, nb).
sub _group ($voices, $k, $n, $nb, $rate) {
    my $B  = BLOCK;
    my $V  = @$voices;
    my $dt = $B / $rate;

    my (@ratio, @amp, @decay, @attack, @phase, @t0, @w, @env, @gl, @gr, @gs, @fmode, @fx, @fq);
    for my $voice (@$voices) {
        # A voice read from wave sequences has no partials here: all padding.
        my @own = $voice->{wave} ? ([], [], [], [], []) : @$voice{qw(ratio amp decay attack phase)};
        my $pad = $k - @{ $own[0] };
        push @ratio,  @{ $own[0] }, (0.0) x $pad;
        push @amp,    @{ $own[1] }, (0.0) x $pad;
        push @decay,  @{ $own[2] }, (0.0) x $pad;
        push @attack, @{ $own[3] }, (0.0) x $pad;
        push @phase,  @{ $own[4] }, (0.0) x $pad;
        push @t0, $voice->{t0};
        push @w,   @{ $voice->{w} };
        push @env, @{ $voice->{env} };
        push @gl,  @{ $voice->{gl} };
        push @gr,  @{ $voice->{gr} };
        push @gs,  @{ $voice->{gs} };
        my $mode = $voice->{fmode} // 0;
        push @fmode, $mode;
        push @fx, $mode ? @{ $voice->{fx} } : (0.0) x ($nb + 1);
        push @fq, $mode ? @{ $voice->{fq} } : (1.0) x ($nb + 1);
    }
    my $partials = sub ($list) { PDL->pdl(PDL::double(), $list)->reshape($k, 1, $V) };
    my $R = $partials->(\@ratio);
    my $A = $partials->(\@amp);
    my $D = $partials->(\@decay);
    my $T = $partials->(\@attack);
    my $P = $partials->(\@phase);
    my $W = PDL->pdl(PDL::double(), \@w)->reshape(1, $nb, $V);

    # The amplitudes at the blocks' edges, (k, nb + 1, V). Before a voice's
    # first block its envelope is zero; they are taken at time 0 there,
    # where they are finite, so that zero times them stays zero.
    my $t = PDL->pdl(PDL::double(), \@t0)->reshape(1, 1, $V) + PDL->sequence(PDL::double(), 1, $nb + 1) * $dt;
    $t *= $t > 0;
    my $edge = $A * exp(-$D * $t);
    my $fades = $T > 0;
    if ($fades->any) {
        my $fade = 1 - exp(-$t / ($T + !$fades));
        $edge *= $fade * $fades + !$fades;
    }
    if (grep { $_ } @fmode) {
        # The filter's gain at the edges (see Peta::Synth::Voice::filter_gain), (k, nb + 1, V).
        my $x     = $R * PDL->pdl(PDL::double(), \@fx)->reshape(1, $nb + 1, $V);
        my $q     = PDL->pdl(PDL::double(), \@fq)->reshape(1, $nb + 1, $V);
        my $mode  = PDL->pdl(PDL::double(), \@fmode)->reshape(1, 1, $V);
        my $x2    = $x * $x;
        my $d     = sqrt((1 - $x2)**2 + $x2 / ($q * $q));
        my $steep = sqrt(1 + $x2 * $x2);

        # Each voice's mode picks its term; the others are times 0.
        $edge *= ($mode == 0)
               + ($mode == 1) / $d
               + ($mode == 2) / ($d * $steep)
               + ($mode == 3) * $x2 / $d
               + ($mode == 4) * $x2 * $x2 / ($d * $steep)
               + ($mode == 5) * $x / $q / $d;
    }
    my $g  = $edge->slice(':,0:-2')->copy;
    my $dg = ($edge->slice(':,1:-1') - $g) / $B;

    # Each partial's angle per sample in each block, and its phase where
    # the block begins; the phase where the quantum ends is the voice's.
    my $step  = $R * $W;                                          # (k, nb, V)
    my $sum   = $step->mv(1, 0)->cumusumover->mv(0, 1) * $B;      # through the end of each block
    my $start = $P + $sum - $step * $B;
    $start -= TWO_PI * PDL::floor($start / TWO_PI);
    my $end = $P->slice(':,(0)') + $sum->slice(':,(-1)');
    $end -= TWO_PI * PDL::floor($end / TWO_PI);
    my @ends = $end->list;
    for my $v (0 .. $V - 1) {
        next if $voices->[$v]{wave};
        my $count = @{ $voices->[$v]{ratio} };
        $voices->[$v]{phase} = [ @ends[ $v * $k .. $v * $k + $count - 1 ] ];
    }

    # The 64 turns of every phasor: a sample of each block at a time,
    # summed over the partials of each voice.
    my $c  = cos($start);
    my $s  = sin($start);
    my $cw = cos($step);
    my $sw = sin($step);
    my $x  = PDL->zeroes(PDL::double(), $B, $nb, $V);
    for my $m (0 .. $B - 1) {
        (my $sample = $x->slice("($m)")) .= ($s * $g)->sumover;
        last if $m == $B - 1;
        my $turn = $c * $sw;
        $c *= $cw;
        $c -= $s * $sw;
        $s *= $cw;
        $s += $turn;
        $g += $dg;
    }

    # The wave sequences, the string, FM, the noise on the partials, then the
    # bands of noise (as the Perl engine has them: recursions, and tables read).
    my $blocks = sub ($samples) { PDL->pdl(PDL::double(), $samples)->reshape($B, $nb) };
    for my $v (0 .. $V - 1) {
        my $voice = $voices->[$v];
        next if !($voice->{wave} || $voice->{noise} || $voice->{rough} || $voice->{string} || $voice->{fm});

        my $own = $x->slice(":,:,($v)");
        $own += $blocks->(Peta::Synth::Engine::Perl::waves($voice, $n, $nb, $rate)) if $voice->{wave};
        $own += $blocks->(Peta::Synth::Engine::Perl::string($voice, $n, $nb))       if $voice->{string};
        $own += $blocks->(Peta::Synth::Engine::Perl::fm($voice, $n, $nb))           if $voice->{fm};
        $own *= $blocks->(Peta::Synth::Engine::Perl::rough($voice, $n, $nb))        if $voice->{rough};
        $own += $blocks->(Peta::Synth::Engine::Perl::noise($voice, $n, $nb))        if $voice->{noise};
    }

    # The envelope and the channel's gains, interpolated across each block.
    my $m = PDL->sequence(PDL::double(), $B) / $B;
    my $across = sub ($list) {
        my $edges = PDL->pdl(PDL::double(), $list)->reshape($nb + 1, $V);
        my $from  = $edges->slice('0:-2');
        return $from->dummy(0, $B) + $m * ($edges->slice('1:-1') - $from)->dummy(0, $B);   # (B, nb, V)
    };
    my $y = $x * $across->(\@env);
    return map { ($y * $across->($_))->mv(2, 0)->sumover } \@gl, \@gr, \@gs;
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::Synth::Engine::PDL - the voices rendered with PDL

=head1 VERSION

version 0.2610180

=head1 DESCRIPTION

The partials of many voices as whole-array operations in double precision;
the noise in Perl. Agrees with the Perl engine to rounding. See
L<Peta::Synth::Engine> for the interface.

=head1 METHODS

=head2 new, name

C<new(%arg)> makes the engine (it dies where it cannot run here); C<name> is C<pdl>.

=head2 render

C<render(\@voices, $n, $rate)>: the voices' next C<$n> samples, mixed, as
array references: left, right and the reverb send.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
