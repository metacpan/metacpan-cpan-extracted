package Peta::Synth::Engine;
# ABSTRACT: the engines that render voices

# Where the voices become samples. Every engine renders the same voice model
# (Peta::Synth::Voice) and gives the same sound, within the precision of its
# arithmetic; they differ in speed, and so in how many partials and voices
# a machine affords.
#
#   perl   plain Perl: everywhere; on pperl compiled by the JIT
#   pdl    PDL: the partials of many voices as whole-array operations
#   gpu    WebGPU compute shaders: every partial of every voice at once (pperl)
#
# An engine implements
#
#   new(rate => ..., partials => ...)   dies when its engine is missing
#   name
#   render(\@voices, $n, $rate)          (\@left, \@right, \@send): $n samples
#
# and may implement
#
#   render_reverb(\@voices, $n, $rate, $reverb)
#                         the same and the reverb on it, (\@left, \@right,
#                         \@send, \@wet_left, \@wet_right)
#   reads_waves           whether it fares better reading harmonic partials
#                         from wave sequences (Peta::Synth::Wavetable)

use v5.36;

our $VERSION = '0.2610180';

my %CLASS = (
    perl => 'Peta::Synth::Engine::Perl',
    pdl  => 'Peta::Synth::Engine::PDL',
    gpu  => 'Peta::Synth::Engine::GPU',
);

sub names () { return sort keys %CLASS }

# An engine, or undef when it is not there; $@ then says why. Why an
# engine's module did not load is kept: perl does not load it again, and
# would only say so.
my %MISSING;

sub try ($name, %arg) {
    my $class = $CLASS{$name} // die "unknown engine '$name' (have: @{[ names() ]}, auto)\n";
    if ($MISSING{$class}) {
        $@ = $MISSING{$class};
        return undef;
    }

    (my $file = "$class.pm") =~ s{::}{/}g;
    if (!eval { require $file; 1 }) {
        $MISSING{$class} = $@;
        return undef;
    }
    return eval { $class->new(%arg) };
}

sub available () { return grep { defined try($_) } names() }

# An engine by name, or for 'auto' the fastest here (see choose).
sub create ($name = 'auto', %arg) {
    $name = choose(%arg) if $name eq 'auto';
    return try($name, %arg) // die "engine '$name' is not available here: $@";
}

# The name of the engine 'auto' takes: $ENV{PETA_SYNTH_ENGINE} when set,
# or the fastest of those here, measured; rate and partials as the
# synthesizer will have them.
sub choose (%arg) {
    return $ENV{PETA_SYNTH_ENGINE} if $ENV{PETA_SYNTH_ENGINE} && $ENV{PETA_SYNTH_ENGINE} ne 'auto';
    my ($fastest) = measure(%arg);
    return $fastest->{name};
}

# How fast each engine here renders a test: a chord on four instruments and
# three drums, with the reverb, as a synthesizer plays them. Fastest first:
# [ { name, speed } ], speed in seconds of sound per second.
#
# What is fastest depends on the perl (pperl's JIT makes the Perl engine
# fast), on the card, and on how much there is to render: a GPU costs a
# fixed time per quantum, which pays from some number of partials on. The
# test is a moderate load; the first quanta are not timed, so that pperl's
# JIT has compiled the loops.
my $QUANTUM = 1024;
my $WARM    = 2;       # quanta not timed
my $TIMED   = 4;       # quanta timed at most
my $BUDGET  = 0.25;    # seconds an engine is timed for at most, after one quantum

sub measure (%arg) {
    require Peta::Synth::Synth;
    require Time::HiRes;
    my $rate = $arg{rate} // 48000;
    my @speed;
    for my $name (names()) {
        my $engine = try($name) or next;
        my $synth = Peta::Synth::Synth->new(rate => $rate, partials => $arg{partials} // 48, engine => $engine, limiter => 0);

        # Piano, strings, brass and a pad, four notes each; kick, snare, hi-hat.
        my @programs = (0, 48, 61, 89);
        for my $channel (0 .. $#programs) {
            $synth->play({ type => 'program', channel => $channel, program => $programs[$channel] });
            for my $key (48 + $channel, 55, 60 + $channel, 64) {
                $synth->play({ type => 'note_on', channel => $channel, key => $key, velocity => 90 });
            }
        }
        $synth->play({ type => 'note_on', channel => 9, key => $_, velocity => 100 }) for 36, 38, 42;

        $synth->render_arrays($QUANTUM) for 1 .. $WARM;
        my ($best, $spent) = (9**9**9, 0);
        for (1 .. $TIMED) {
            my $started = Time::HiRes::time();
            $synth->render_arrays($QUANTUM);
            my $took = Time::HiRes::time() - $started;
            $best = $took if $took < $best;
            last if ($spent += $took) > $BUDGET;
        }
        push @speed, { name => $name, speed => $QUANTUM / $rate / ($best || 1e-9) };
    }
    return sort { $b->{speed} <=> $a->{speed} } @speed;
}

# Which perl this is, and what it has: for choosing what a machine can afford.
sub perl_info () {
    my $pperl = $^V =~ /\.99\z/;    # pperl's version ends so
    return {
        perl    => $pperl ? 'pperl' : 'perl5',
        version => $pperl ? $ENV{PPERL} : sprintf('%vd', $^V),    # pperl sets PPERL to its own
        jit     => $pperl && do { require Config; my @counts = eval { Config::jit_counts() }; @counts ? 1 : 0 } ? 1 : 0,
        pdl     => eval { require PDL::Lite; 1 } ? 1 : 0,
        gpu     => eval { require Peta::WebGPU; Peta::WebGPU::have_gpu() } ? 1 : 0,
        cpus    => cpus(),
    };
}

sub cpus () {
    open my $fh, '<', '/proc/cpuinfo' or return 1;
    my $count = grep { /^processor\s*:/ } <$fh>;
    return $count || 1;
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::Synth::Engine - the engines that render voices

=head1 VERSION

version 0.2610180

=head1 SYNOPSIS

    my $engine = Peta::Synth::Engine::create('auto', rate => 48000, partials => 48);   # or 'perl', 'pdl', 'gpu'
    print join ' ', Peta::Synth::Engine::available();     # gpu pdl perl
    printf "%s %.1fx\n", $_->{name}, $_->{speed} for Peta::Synth::Engine::measure();

=head1 DESCRIPTION

Every engine renders the voice model of L<Peta::Synth::Voice> and sounds
the same; they differ in speed. C<perl> is everywhere (and compiled by
pperl's JIT), C<pdl> needs PDL, C<gpu> needs pperl with WebGPU and a
graphics card. C<auto> takes the fastest of those there are, measured,
or C<$ENV{PETA_SYNTH_ENGINE}> when set.

=head1 FUNCTIONS

=head2 create

C<create($name, %arg)>: an engine; dies if it is not available. For
C<auto>, C<rate> and C<partials> say what the synthesizer will have, for
the measurement (L</choose>).

=head2 choose

C<choose(rate => $rate, partials => $partials)>: the name of the engine
C<auto> takes: C<$ENV{PETA_SYNTH_ENGINE}> when set, or the fastest.

=head2 measure

C<measure(rate => $rate, partials => $partials)>: how fast each engine
here renders a test, fastest first: C<< [ { name => 'gpu', speed => 9.2 }, ... ] >>,
the speed in seconds of sound per second. The test is a chord of sixteen
notes on four instruments and three drums, with the reverb, as the
synthesizer plays them; the first quanta are not timed, so that pperl's
JIT has compiled the loops. It takes a fraction of a second per engine.

Which engine is fastest depends on how much there is to render: the GPU
costs a fixed time per quantum and pays from some number of partials on;
the test is a moderate load.

=head2 try

The same, or undef with the reason in C<$@>.

=head2 available, names

The engines that work here, and all of them.

=head2 perl_info

What this perl is and has: C<perl> (C<pperl> or C<perl5>), C<version>
(pperl's own under pperl, not the perl it is compatible with), C<jit>,
C<pdl>, C<gpu>, C<cpus>.

=head2 cpus

The number of processors.

=head1 THE ENGINE INTERFACE

=over

=item new

Dies when the engine cannot run here.

=item name

=item render

C<render(\@voices, $n, $rate)>: the voices' next C<$n> samples (a multiple of
64), each voice under its envelope and channel gains, mixed into three
array references: left, right and the reverb send. The voices' C<phase>
and C<nstate> are carried on.

=back

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
