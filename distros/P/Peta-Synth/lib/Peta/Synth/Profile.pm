package Peta::Synth::Profile;
# ABSTRACT: what a piece will cost to render, second by second, before it is rendered

# What a piece will cost to render, before it is rendered: its voices (when
# each starts and falls silent, what it is made of: Peta::Synth::Synth's
# foresee), what sounds at each moment, and with an engine's costs
# measured (calibrate) how long each second of it takes to render. For
# planning: which notes to prepare, which stretches to render ahead.
#
# The cost model: a quantum costs the synthesizer's own work (events,
# mixing, the reverb, the limiter: quantum), and each voice sounding in it
# its controls (voice) and what it is made of: its partials (partial each;
# filter each more under a moving filter), its string, its FM, its bands of
# noise. calibrate measures them on an engine, as render_arrays spends them.

use v5.36;
use List::Util qw(max min sum0);
use Time::HiRes ();
use Peta::Synth::Engine::Perl;
use Peta::Synth::Patch;
use Peta::Synth::Synth;

our $VERSION = '0.2610180';

use constant QUANTUM => 1024;      # as Peta::Synth plays

# A piece's voices: timeline (events, times in seconds, as Peta::Synth::Synth's
# schedule takes them), length (seconds, where the events end), tail (the most
# seconds sounded after it: 30, as rendering does), rate (48000), partials
# (48), bank, waves (as Peta::Synth::Synth takes them: 1 by default; a
# store is filled with the sequences the piece needs).
sub new ($class, %arg) {
    my $rate     = $arg{rate} // 48000;
    my $partials = $arg{partials} // 48;
    my $synth    = Peta::Synth::Synth->new(
        rate     => $rate,
        partials => $partials,
        engine   => Peta::Synth::Engine::Perl->new,
        waves    => $arg{waves} // 1,
    );
    $synth->apply_edits($arg{bank}) if $arg{bank};
    $synth->schedule($arg{timeline});

    my $length = $arg{length} // max(0, map { $_->{time} } @{ $arg{timeline} });
    my $until  = $length + ($arg{tail} // 30);
    my @voices = map { _summary($_, $until) } grep { $_->{start} < $until } @{ $synth->foresee };

    return bless {
        rate     => $rate,
        length   => $length,
        until    => $until,
        end      => max($length, map { $_->{end} } @voices),
        voices   => \@voices,
        partials => $partials,
        bank     => $arg{bank},
        timeline => $arg{timeline},
        waves    => $synth->waves // 0,
    }, $class;
}

# A foreseen voice as the profile keeps it: when it sounds (to $until at
# most), whose it is, and what it is made of.
sub _summary ($v, $until) {
    my $voice = $v->{voice};
    my $wave  = $voice->{wave};
    return {
        start    => $v->{start},
        end      => $v->{end} eq 'inf' || $v->{end} > $until ? $until : $v->{end},
        channel  => $voice->{channel},
        program  => $v->{program},
        key      => $voice->{key},
        velocity => $voice->{velocity},
        partials => $wave ? 0 : scalar @{ $voice->{ratio} },    # turned one by one
        copies   => $wave ? scalar @$wave : 0,                    # read from wave sequences
        filter   => $voice->{fmode}  ? 1 : 0,
        string   => $voice->{string} ? 1 : 0,
        fm       => $voice->{fm}     ? 1 : 0,
        bands    => scalar @{ $voice->{bands} // [] },
    };
}

sub voices  ($self) { return $self->{voices} }
sub seconds ($self) { return $self->{length} }

# The steps (seconds) a voice sounds in: [index, share of the step], the
# last step the one holding the end.
sub _steps ($v, $step, $count) {
    my @steps;
    for my $i (int($v->{start} / $step) .. min($count - 1, int($v->{end} / $step))) {
        my $share = (min($v->{end}, ($i + 1) * $step) - max($v->{start}, $i * $step)) / $step;
        push @steps, [ $i, $share ] if $share > 0;
    }
    return @steps;
}

# What sounds, step by step (seconds): for each step from 0 to where the
# last voice falls silent, the time it starts at and the mean, over the
# step, of the voices sounding, their partials (and those under a filter),
# the copies read from wave sequences, strings, FM voices and bands of noise.
sub load ($self, $step = 1) {
    my $count = int($self->{end} / $step) + 1;
    my @load;
    for my $i (0 .. $count - 1) {
        push @load, { at => $i * $step, map { $_ => 0 } qw(voices partials filtered copies strings fm bands) };
    }

    for my $v (@{ $self->{voices} }) {
        for (_steps($v, $step, $count)) {
            my ($i, $share) = @$_;
            my $l = $load[$i];
            $l->{voices}   += $share;
            $l->{partials} += $share * $v->{partials};
            $l->{filtered} += $share * $v->{partials} * $v->{filter};
            $l->{copies}   += $share * $v->{copies};
            $l->{strings}  += $share * $v->{string};
            $l->{fm}       += $share * $v->{fm};
            $l->{bands}    += $share * $v->{bands};
        }
    }
    return \@load;
}

# Seconds of rendering a second of sound takes, step by step, by the costs
# calibrate measured: [ { at, load } ] (load 1: just in real time).
sub predict ($self, $costs, $step = 1) {
    my $count = int($self->{end} / $step) + 1;
    my @spent = (0) x $count;    # a quantum's seconds, the voices'
    for my $v (@{ $self->{voices} }) {
        my $cost = _voice_cost($v, $costs);
        $spent[ $_->[0] ] += $_->[1] * $cost for _steps($v, $step, $count);
    }

    my $quanta = $self->{rate} / QUANTUM;    # a second's
    return [ map { { at => $_ * $step, load => ($costs->{quantum} + $spent[$_]) * $quanta } } 0 .. $count - 1 ];
}

# A voice's seconds a quantum: what its program (or drum) was measured to
# cost beside its partials (its filter in that), and its partials; one not
# measured what it is made of.
sub _voice_cost ($v, $costs) {
    my $own = defined $v->{program} ? $costs->{programs}{ $v->{program} } : $costs->{drums}{ $v->{key} };
    return $own + $v->{partials} * $costs->{partial} if defined $own;

    return $costs->{voice}
         + $v->{copies} * $costs->{copy}
         + $v->{string} * $costs->{string}
         + $v->{fm} * $costs->{fm}
         + $v->{bands} * $costs->{band}
         + $v->{partials} * ($costs->{partial} + $v->{filter} * $costs->{filter});
}

# The programs the piece plays, and its drums (their keys).
sub programs ($self) {
    my %seen;
    return [ sort { $a <=> $b } grep { !$seen{$_}++ } map { $_->{program} // () } @{ $self->{voices} } ];
}

sub drums ($self) {
    my %seen;
    return [ sort { $a <=> $b } grep { !$seen{$_}++ } map { defined $_->{program} ? () : $_->{key} } @{ $self->{voices} } ];
}

# The notes the piece plays, as wavetables would be made for them: program
# (or the drum: program undef, the key its drum), key, velocity; how often,
# for how many seconds in all. Most seconds first; the same seconds by
# program (the drums last), key and velocity.
sub notes ($self) {
    my %note;
    for my $v (@{ $self->{voices} }) {
        my $id = join ',', $v->{program} // 'drum', $v->{key}, $v->{velocity};
        my $n  = $note{$id} //= { program => $v->{program}, key => $v->{key}, velocity => $v->{velocity}, count => 0, seconds => 0 };
        $n->{count}++;
        $n->{seconds} += $v->{end} - $v->{start};
    }
    return [
        sort {
                   $b->{seconds} <=> $a->{seconds}
                || ($a->{program} // 128) <=> ($b->{program} // 128)
                || $a->{key} <=> $b->{key}
                || $a->{velocity} <=> $b->{velocity}
        } values %note
    ];
}

# The costs of an engine, in seconds a quantum (of QUANTUM samples):
# quantum (the synthesizer's own work), voice, partial, filter (a partial's
# more under a moving filter), copy (a copy of a voice read from a wave
# sequence), string, fm, band: each from 16 held notes of a plain patch of
# one kind. And with programs and drums (keys) given (and waves, as the
# synthesizer will have them), what a voice of each costs beside its
# partials, from 8 notes of it: programs => { n => seconds }, drums =>
# { key => seconds }. Each the quickest of a few quanta, the notes' first
# quantum (making them) not counted, after the engine (and pperl's JIT)
# warmed up.
sub calibrate (%arg) {
    my $engine = $arg{engine} // die "calibrate needs an engine\n";
    my $rate   = $arg{rate} // 48000;
    my $timer  = sub (%test) { _quickest($engine, $rate, %test) };

    _quickest($engine, $rate, _plain({}, 48)) for 1 .. 2;    # warming up
    my ($quantum) = $timer->(keys => []);

    # A voice of a plain patch so changed: its seconds a quantum.
    my $each = sub ($edits, $partials, $waves = 0) {
        my ($took) = $timer->(_plain($edits, $partials, $waves));
        return max(0, ($took - $quantum) / 16);
    };

    my %costs = (engine => $engine->name, quantum => $quantum);
    my $p8  = $each->({}, 8);
    my $p48 = $each->({}, 48);
    $costs{partial} = max(0, ($p48 - $p8) / 40);
    $costs{voice}   = max(0, $p8 - 8 * $costs{partial});
    $costs{filter}  = max(0, ($each->({ filter => 'lp12', filter_cutoff => 2000 }, 48) - $p48) / 48);
    $costs{copy}    = max(0, $each->({}, 48, 1) - $costs{voice});
    $costs{string}  = max(0, $each->({ partials => [], string => 1, string_decay => 30 }, 48) - $costs{voice});
    $costs{fm}      = max(0, $each->({ partials => [], fm => 1 }, 48) - $costs{voice});
    $costs{band}    = max(0, $each->({ partials => [], noise => 1, noise_sustain => 1, noise_decay => 0 }, 48) - $costs{voice});

    # A program's or a drum's voices: beside their partials, what they cost.
    my $waves = $arg{waves} // ($engine->can('reads_waves') ? $engine->reads_waves : 1);
    my $own   = sub (%test) {
        my ($took, $partials, $n) = $timer->(%test, bank => $arg{bank}, partials => $arg{partials} // 48, waves => $waves);
        return undef if $took > 1e9 || !$n;
        return max(0, ($took - $quantum) / $n - $partials / $n * $costs{partial});
    };
    for my $program (@{ $arg{programs} // [] }) {
        my $c = $own->(program => $program, keys => [ map { 48 + 2 * $_ } 0 .. 7 ]);
        $costs{programs}{$program} = $c if defined $c;
    }
    for my $key (@{ $arg{drums} // [] }) {
        my $c = $own->(channel => 9, keys => [ ($key) x 8 ]);
        $costs{drums}{$key} = $c if defined $c;
    }
    return \%costs;
}

# A test of 16 held notes of a plain patch (one partial-for-partial
# sustained sound) with these changes, at most $partials partials.
sub _plain ($edits, $partials, $waves = 0) {
    my %plain = (
        %{ Peta::Synth::Patch::defaults() },
        attack  => 0.001,
        sustain => 1,
        decay   => 0,
        release => 0.1,
        cutoff  => 20000,
        noise   => 0,
        unison  => 1,
        vibrato => 0,
        tremolo => 0,
    );
    return (
        bank     => { programs => { 0 => { %plain, %$edits } } },
        program  => 0,
        partials => $partials,
        keys     => [ map { 36 + 2 * $_ } 0 .. 15 ],
        waves    => $waves,
    );
}

# The quickest quantum of notes held (so long as they all sound): its
# seconds, the partials turned one by one, and how many notes sounded
# (drums of a class cut each other off).
sub _quickest ($engine, $rate, %test) {
    my $synth = Peta::Synth::Synth->new(rate => $rate, partials => $test{partials} // 48, engine => $engine, waves => $test{waves});
    $synth->apply_edits($test{bank}) if $test{bank};

    my $ch = $test{channel} // 0;
    $synth->play({ type => 'program', channel => $ch, program => $test{program} }) if defined $test{program};
    $synth->play({ type => 'note_on', channel => $ch, key => $_, velocity => 100 }) for @{ $test{keys} };
    $synth->render_arrays(QUANTUM);    # the notes made: not counted

    my $partials = sum0(map { $_->{wave} ? 0 : $_->partials } @{ $synth->{active} });
    my $sounding = $synth->active;
    my ($best, $spent) = (9**9**9, 0);
    for (1 .. 8) {
        last if $synth->active < $sounding;

        my $started = Time::HiRes::time();
        $synth->render_arrays(QUANTUM);
        my $took = Time::HiRes::time() - $started;
        $best = $took if $took < $best;
        last if ($spent += $took) > 0.3;
    }
    return ($best, $partials, $sounding);
}

# What rendering the piece takes, measured: rendered by an engine as
# Peta::Synth plays it, quantum by quantum; the seconds spent in each step:
# [ { at, load } ].
sub measure ($self, $engine, $step = 1) {
    my $rate  = $self->{rate};
    my $synth = Peta::Synth::Synth->new(rate => $rate, partials => $self->{partials}, engine => $engine, waves => $self->{waves});
    $synth->apply_edits($self->{bank}) if $self->{bank};
    $synth->schedule($self->{timeline});

    my $until = int($self->{until} * $rate);
    my @spent;
    while ($synth->busy && $synth->now < $until) {
        my $at      = $synth->now / $rate;
        my $started = Time::HiRes::time();
        $synth->render_arrays(QUANTUM);
        $spent[ int($at / $step) ] += Time::HiRes::time() - $started;
    }
    return [ map { { at => $_ * $step, load => ($spent[$_] // 0) / $step } } 0 .. $#spent ];
}

1;

__END__

=head1 NAME

Peta::Synth::Profile - what a piece will cost to render, second by second, before it is rendered

=head1 VERSION

version 0.2610180

=head1 SYNOPSIS

    use Peta::Synth::Profile;
    my $profile = Peta::Synth::Profile->new(timeline => \@events, length => $seconds);
    my $costs   = Peta::Synth::Profile::calibrate(engine => $engine);
    for my $s (@{ $profile->predict($costs, 1) }) { printf "%4d s  %.2f\n", $s->{at}, $s->{load} }
    my $notes = $profile->notes;      # the notes it plays, most seconds first

=head1 DESCRIPTION

A piece's voices are known before it sounds: L<Peta::Synth::Synth/foresee>
runs its events as rendering does, without rendering, and each voice says
when it will fall silent (L<Peta::Synth::Voice/ends>). What sounds at each
moment, and the costs of an engine measured, say how long each second of
it takes to render: where it keeps up with real time and where not, and
which notes are worth preparing ahead.

The cost model: a quantum (1024 samples) costs the synthesizer's own work
(events, mixing, reverb, limiter), and each voice in it its controls and
what it is made of: its partials (more under a moving filter), its string,
its FM, its bands of noise.

=head1 METHODS

=head2 new

C<< new(timeline => \@events, length => $s, tail => 30, rate => 48000, partials => 48, bank => ..., waves => 1) >>:
the piece's voices, each C<< { start, end, channel, program, key, velocity,
partials, copies, filter, string, fm, bands } >> (seconds; program undef on
the drums; partials those turned one by one, copies those read from wave
sequences), to where rendering would stop (C<length> and C<tail>). C<waves>
as L<Peta::Synth::Synth> takes it: a store given is filled with the
sequences the piece needs (made ahead).

=head2 voices, seconds

The voices; where the events end (seconds).

=head2 load

C<load($step = 1)>: for each step, the mean of what sounds: C<< { at,
voices, partials, filtered, strings, fm, bands } >>.

=head2 predict

C<predict($costs, $step = 1)>: C<< [ { at, load } ] >>, the seconds of
rendering a second of sound takes at each step (1: just in real time).

=head2 notes

The notes played, C<< { program, key, velocity, count, seconds } >>, most
seconds first.

=head2 programs, drums

The programs the piece plays, and its drums (their keys), each once, in
order.

=head2 measure

C<measure($engine, $step = 1)>: the piece rendered by the engine as
L<Peta::Synth> plays it, the seconds each step took: C<< [ { at, load } ] >>.

=head1 FUNCTIONS

=head2 calibrate

C<< calibrate(engine => $engine, rate => 48000, programs => [...], drums => [...], waves => 1) >>:
the engine's costs in seconds a quantum: C<< { engine, quantum, voice,
partial, filter, copy, string, fm, band, programs => { n => ... }, drums => { key => ... } } >>.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
