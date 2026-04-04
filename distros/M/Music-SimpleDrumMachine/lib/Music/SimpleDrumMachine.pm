package Music::SimpleDrumMachine;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Simple 16th-note-phrase Drummer

our $VERSION = '0.0100';

use v5.36;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use strictures 2;
use Carp qw(croak);
use Data::Dumper::Compact qw(ddc);
use IO::Async::Loop ();
use IO::Async::Timer::Periodic ();
use MIDI::RtMidi::FFI::Device ();
use Music::Duration::Partition ();
use namespace::clean;


has beats => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not an integer" unless $_[0] =~ /^\d+$/ },
    default => sub { 16 },
);


has bpm => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not an integer" unless $_[0] =~ /^\d+$/ },
    default => sub { 120 },
);


has chan => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not valid" unless $_[0] =~ /^-?\d+$/ },
    default => sub { 9 },
);


has divisions => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not an integer" unless $_[0] =~ /^\d+$/ },
    default => sub { 4 },
);


has drums => (
    is      => 'rw',
    isa     => sub { croak "$_[0] is not a hash-ref" unless ref($_[0]) eq 'HASH' },
    builder => '_build_drums',
);

sub _build_drums {
    my ($self) = @_;
    my $drums = {
        kick  => { num => 36, chan => $self->chan < 0 ? 0 : $self->chan, pat => [] },
        snare => { num => 38, chan => $self->chan < 0 ? 1 : $self->chan, pat => [] },
        hihat => { num => 42, chan => $self->chan < 0 ? 2 : $self->chan, pat => [] },
        crash => { num => 49, chan => $self->chan < 0 ? 3 : $self->chan, pat => [] },
    };
    return $drums;
}


has fill_part => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not an code-ref" unless ref($_[0]) eq 'CODE' },
    default => sub { \&_default_part },
);


has next_part => (
    is      => 'rw',
    default => sub { '_default_part' },
);


has notes => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not an array-ref" unless ref($_[0]) eq 'ARRAY' },
    default => sub { [qw(60 64 67)] },
);


has parts => (
    is      => 'rw',
    default => sub { { _default_part => \&_default_part } },
);


has port_name => (
    is      => 'ro',
    default => sub { 'usb' },
);


has ppqn => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not an integer" unless $_[0] =~ /^\d+$/ },
    default => sub { 24 },
);


has verbose => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a boolean" unless $_[0] =~ /^[01]$/ },
    default => sub { 0 },
);

has _queue => (
    is      => 'rw',
    default => sub { [] },
);

has _midi_out => (
    is      => 'lazy',
    builder => '_build__midi_out',
);

sub _build__midi_out {
    my ($self) = @_;
    my $midi_out = RtMidiOut->new;
    try { # this will die on windows but is needed on the mac
        $midi_out->open_virtual_port('RtMidiOut');
    }
    catch ($e) {}
    my $name = $self->port_name;
    $midi_out->open_port_by_name(qr/\Q$name/i);
    return $midi_out;
}

has _interval => (
    is      => 'lazy',
    builder => '_build__interval',
);

sub _build__interval {
    my ($self) = @_;
    return 60 / $self->bpm / $self->ppqn;
}

has _nth => ( # clocks per 16th-note
    is      => 'lazy',
    builder => '_build__nth',
);

sub _build__nth {
    my ($self) = @_;
    return $self->ppqn / $self->divisions;
}

# keep track of things
my %attrs = (
    rw => {
        _ticks      => 0, # how many clock ticks?
        _beat_count => 0, # how many beats?
        _bar_count  => 0, # how many measures?
        _toggle     => 0, # part A, B, C, ...?
        _hats       => 0, # 1st hihat beat bit
        _trigger    => 0, # trigger a fill
        _filled     => 0, # we just filled
    },
);
for my $is ( keys %attrs ) {
    for my $attr ( keys $attrs{$is}->%* ) {
        has $attr => (
            is      => $is,
            default => sub { $attrs{$is}{$attr} },
        );
    }
}

has _loop => (
    is      => 'ro',
    default => sub { IO::Async::Loop->new },
);


sub BUILD {
    my ($self, $args) = @_;

    $SIG{INT} = sub {
        say "\nStop";
        try {
            $self->_midi_out->panic;
            $self->_midi_out->stop;
        }
        catch ($e) {
            warn "Can't halt the MIDI out device: $e\n";
        }
        exit;
    };

    my $timer = IO::Async::Timer::Periodic->new(
        interval => $self->_interval,
        on_tick  => sub {
            $self->_midi_out->clock; # send a clock tick
            $self->_ticks($self->_ticks + 1);

            if ($self->_ticks % $self->_nth == 0) {
                if (($self->_beat_count + $self->beats - $self->_trigger) % ($self->beats * $self->divisions - 1) == 0) {
                    $self->_adjust_drums(1); # fill!
                    $self->_filled($self->_filled + 1);
                }
                if ($self->_beat_count % ($self->beats * $self->divisions) == 0) {
                    $self->_adjust_drums(0); # normal part
                    $self->_trigger($self->_trigger + 1);
                }
                for my $drum (keys $self->drums->%*) { # fill the queue
                    if ($self->drums->{$drum}{pat}[ $self->_beat_count % scalar($self->drums->{$drum}{pat}->@*) ]) {
                        push $self->_queue->@*, { drum => $drum, velocity => $self->_velocity(-10, 10, 110) };
                    }
                }
                for my $drum ($self->_queue->@*) { # play the queue
                    $self->_midi_out->note_on(
                        $self->drums->{ $drum->{drum} }{chan},
                        $self->drums->{ $drum->{drum} }{num},
                        $drum->{velocity}
                    );
                }
                $self->_beat_count($self->_beat_count + 1);
            }
            else { # drain the queue
                while (my $drum = pop $self->_queue->@*) {
                    $self->_midi_out->note_off(
                        $self->drums->{ $drum->{drum} }{chan},
                        $self->drums->{ $drum->{drum} }{num},
                        0
                    );
                }
            }
            if ($self->_ticks % ($self->ppqn * $self->divisions) == 0) {
                $self->_bar_count($self->_bar_count + 1);
            }
        },
    );
    $timer->start;

    $self->_loop->add($timer);
    $self->_loop->run;
}

sub _adjust_cymbals($self) {
    if ($self->_filled) {
        $self->drums->{crash}{pat}[0] = 1; # crash on one
        $self->drums->{hihat}{pat}[0] = 0; # mutually exclusive
    }
    else {
        $self->drums->{crash}{pat}[0] = 0; # not crashing
        $self->drums->{hihat}{pat}[0] = $self->_hats; # restore hihat bit
    }
    $self->_filled(0);
}

sub _adjust_drums($self, $fill_flag) {
    if ($fill_flag) {
        say 'fill' if $self->verbose;
        my $size = rand() < 0.5 ? $self->divisions / 2 : $self->divisions;
        say "S: $size" if $self->verbose;
        my %durations = (
            sn => [1],
            en => [1,0],
            qn => [1,0,0,0],
        );
        my $mdp = Music::Duration::Partition->new(
            size    => $self->divisions,
            pool    => [qw(qn en sn)],
            weights => [1, 2, 1],
            groups  => [0, 0, 2],
        );
        my $motif = $mdp->motif;
        my @converted = map { $durations{$_}->@* } @$motif;
        if ($size < $self->divisions) {
            my $div = $self->beats / $size;
            my ($next, $pats) = $self->fill_part->();
            $self->drums->{hihat}{pat} = [ $pats->{hihat}->@[0 .. $div - 1], (0) x $div ];
            $self->drums->{kick}{pat}  = [ $pats->{kick}->@[0 .. $div - 1],  (0) x $div ];
            $self->drums->{snare}{pat} = [ $pats->{snare}->@[0 .. $div - 1], @converted[0 .. $div - 1] ]
        }
        else {
            $self->drums->{hihat}{pat} = [ (0) x $self->beats ];
            $self->drums->{kick}{pat}  = [ (0) x $self->beats ];
            $self->drums->{snare}{pat} = \@converted;
        }
    }
    else {
        my $part = $self->parts->{ $self->next_part };
        my ($next, $patterns) = $part->();
        $self->next_part($next);
        for my $drum (keys %$patterns) {
            $self->drums->{$drum}{pat} = $patterns->{$drum};
        }
    }
    $self->_hats($self->drums->{hihat}{pat}[0]); # save bit
    $self->drums->{crash}{pat} = [ (0) x ($self->beats * $self->divisions) ];
    $self->_adjust_cymbals;
    # $drums->{hihat}{num} = $self->_random_note($notes);
    # $drums->{kick}{num}  = $self->_random_note($notes);
    # $drums->{snare}{num} = $self->_random_note($notes);
    # $drums->{crash}{num} = $self->_random_note($notes);
}

sub _velocity($self, $min, $max, $offset) {
    my $random = $offset + int(rand($max - $min + 1)) + $min;
    return $random;
}

sub _random_note($self) {
    my $random = $self->notes->[ int rand $self->notes->@* ] - 24;
    return $random;
}

sub _default_part {
    say 'Default part!';
    my %patterns = (
        hihat => [qw(1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0)],
        kick  => [qw(1 0 0 0 0 0 0 0 1 0 1 0 0 0 0 0)],
        snare => [qw(0 0 0 0 1 0 0 0 0 0 0 0 1 0 0 0)],
    );
    my $next = '_default_part';
    return $next, \%patterns;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Music::SimpleDrumMachine - Simple 16th-note-phrase Drummer

=head1 VERSION

version 0.0100

=head1 SYNOPSIS

  use Music::SimpleDrumMachine ();

  my $dm = Music::SimpleDrumMachine->new(verbose => 1);

=head1 DESCRIPTION

C<Music::SimpleDrumMachine> is a simple 16th-note-phrase drummer.

=head1 ATTRIBUTES

=head2 beats

  $beats = $dm->beats;

The number of beats in a phrase.

Default: C<16>

=head2 bpm

  $bpm = $dm->bpm;

The beats per minute.

Default: C<120>

=head2 chan

  $chan = $dm->chan;

The MIDI channel.

If the channel is set to C<-1>, multi-timbral mode is turned on and
channels C<0>, C<1>, ... and up are used, instead of a single channel
for all the percussion.

Default: C<9>

=head2 divisions

  $divisions = $dm->divisions;

The number of divisions of a quarter-note into the number of
beat-notes. For the default, this is the number of divisions of a
quarter-note to get 16ths.

Default: C<4>

=head2 drums

  $drums = $dm->drums;

The known drums.

Default:

  kick  => { num => 36, chan => ..., pat => [] },
  snare => { num => 38, chan => ..., pat => [] },
  hihat => { num => 42, chan => ..., pat => [] },
  crash => { num => 49, chan => ..., pat => [] },

=head2 fill_part

  $fill_part = $dm->fill_part;

Code-ref of the part to play for 1/2-bar fills.

Default: \&_default_part

=head2 next_part

  $next_part = $dm->next_part;

Name of the part to play first.

Default: '_default_part'

=head2 notes

  $notes = $dm->notes;

The notes to set for each drum - why not?

Default: [60, 64, 67]

=head2 parts

  $parts = $dm->parts;

List of code-refs of the parts to play.

Default: C<[\&_default_part]>

=head2 port_name

  $port = $dm->port_name;

The name of the MIDI output port.

Default: C<usb>

=head2 ppqn

  $ppqn = $dm->ppqn;

The "pulses per quarter-note" or "clocks per beat."

Default: C<24>

=head2 verbose

  $verbose = $dm->verbose;

Show progress.

=head1 METHODS

=head2 new

  $dm = Music::SimpleDrumMachine->new(verbose => 1);

Create a new C<Music::SimpleDrumMachine> object.

=for Pod::Coverage BUILD

=head1 SEE ALSO

L<Moo>

L<http://somewhere.el.se>

=head1 AUTHOR

Gene Boggs <gene.boggs@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
