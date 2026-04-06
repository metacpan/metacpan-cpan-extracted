package Music::SimpleDrumMachine;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Simple 16th-note-phrase Drummer

our $VERSION = '0.0403';

use v5.36;
use feature 'try';

use Moo;
use strictures 2;
use Carp qw(croak);
use Data::Dumper::Compact qw(ddc);
use IO::Async::Loop ();
use IO::Async::Timer::Periodic ();
use MIDI::RtMidi::FFI::Device ();
use Music::Duration::Partition ();
use namespace::clean;

no warnings 'experimental::try';


has add_drums => (
    is      => 'rw',
    isa     => sub { croak "$_[0] is not an array-ref" unless ref($_[0]) eq 'ARRAY' },
    default => sub { [] },
);


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
        fillcrash => { num => 49, chan => $self->chan < 0 ? 3 : $self->chan, pat => [] },
    };
    return $drums;
}


has fill_crash => (
    is      => 'rw',
    isa     => sub { croak "$_[0] is not a boolean" unless $_[0] =~ /^[01]$/ },
    default => sub { 1 },
);


has fills => (
    is      => 'lazy',
    builder => '_build_fills',
);
sub _build_fills {
    my ($self) = @_;
    return { _default_fill => sub { $self->_default_fill } };
}


has filling => (
    is      => 'rw',
    isa     => sub { croak "$_[0] is not a boolean" unless $_[0] =~ /^[01]$/ },
    default => sub { 1 },
);


has next_fill => (
    is      => 'rw',
    default => sub { '_default_fill' },
);


has next_part => (
    is      => 'rw',
    default => sub { '_default_part' },
);


has notes => (
    is      => 'rw',
    isa     => sub { croak "$_[0] is not an array-ref" unless ref($_[0]) eq 'ARRAY' },
    default => sub { [qw(60 64 67)] },
);


has parts => (
    is      => 'lazy',
    builder => '_build_parts',
);
sub _build_parts {
    my ($self) = @_;
    return { _default_part => sub { $self->_default_part } };
}


has port_name => (
    is       => 'ro',
    default  => sub { 'usb' },
    required => 1,
);


has ppqn => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not an integer" unless $_[0] =~ /^\d+$/ },
    default => sub { 24 },
);


has prefill_part => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not an code-ref" unless ref($_[0]) eq 'CODE' },
    default => sub { \&_default_part },
);


has verbose => (
    is      => 'ro',
    isa     => sub { croak "$_[0] is not a boolean" unless $_[0] =~ /^[01]$/ },
    default => sub { 0 },
);


has velo_max => (
    is      => 'rw',
    isa     => sub { croak "$_[0] is not valid" unless $_[0] =~ /^\d+$/ },
    default => sub { 10 },
);


has velo_min => (
    is      => 'rw',
    isa     => sub { croak "$_[0] is not valid" unless $_[0] =~ /^-?\d+$/ },
    default => sub { -10 },
);


has velo_off => (
    is      => 'rw',
    isa     => sub { croak "$_[0] is not valid" unless $_[0] =~ /^\d+$/ },
    default => sub { 110 },
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
        _hats       => 0, # 1st hihat beat bit
        _trigger    => 0, # trigger a fill
        _filled     => 0, # we just filled
    },
);
for my $is (keys %attrs) {
    for my $attr (keys $attrs{$is}->%*) {
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
        say "\nStop" if $self->verbose;
        try {
            $self->_midi_out->stop;
            $self->_midi_out->panic;
        }
        catch ($e) {
            warn "Can't halt the MIDI out device: $e\n";
        }
        exit;
    };

    # any drums to add?
    my $n = keys $self->drums->%*;
    for my $drum ($args->{add_drums}->@*) {
        my $chan = defined $drum->{chan} ? $drum->{chan} : $self->chan < 0 ? $n++ : $self->chan;
        $self->drums->{ $drum->{drum} } = { num => $drum->{num}, chan => $chan, pat  => [] };
    }

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
                        push $self->_queue->@*, { drum => $drum, velocity => $self->velocity };
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
    if ($self->fill_crash) {
        if ($self->_filled) {
            $self->drums->{fillcrash}{pat}[0] = 1; # crash on one
            $self->drums->{hihat}{pat}[0] = 0; # mutually exclusive
        }
        else {
            $self->drums->{fillcrash}{pat}[0] = 0; # not crashing
            $self->drums->{hihat}{pat}[0] = $self->_hats; # restore hihat bit
        }
    }
    $self->_filled(0);
}

sub _adjust_drums($self, $fill_flag) {
    say 'Beats: ' . $self->_beat_count if $self->verbose;
    my ($next, $patterns);
    # play a fill or a part
    if ($self->filling && $fill_flag) {
        my $fill = $self->fills->{ $self->next_fill };
        ($next, $patterns) = $fill->();
        $self->next_fill($next);
    }
    else {
        my $part = $self->parts->{ $self->next_part };
        ($next, $patterns) = $part->();
        $self->next_part($next);
    }
    # add the patterns to the drums
    for my $drum (keys %$patterns) {
        $self->drums->{$drum}{pat} = $patterns->{$drum};
    }
    # add zero-patterns to the unused drums
    for my $drum (keys $self->drums->%*) {
        unless (exists $patterns->{$drum}) {
            $self->drums->{$drum}{pat} = [ (0) x $self->beats ];
        }
    }
    if ($self->filling) {
        $self->_hats($self->drums->{hihat}{pat}[0]); # save bit
        $self->drums->{fillcrash}{pat} = [ (0) x ($self->beats * $self->divisions) ];
        $self->_adjust_cymbals;
    }
}

sub _default_part($self) {
    say '_default_part' if $self->verbose;
    my %patterns = (
        hihat => [qw(1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0)],
        kick  => [qw(1 0 0 0 0 0 0 0 1 0 1 0 0 0 0 0)],
        snare => [qw(0 0 0 0 1 0 0 0 0 0 0 0 1 0 0 0)],
    );
    my $next = '_default_part';
    return $next, \%patterns;
}

sub _default_fill($self) {
    say '_default_fill' if $self->verbose;
    my $size = rand() < 0.5 ? $self->divisions / 2 : $self->divisions;
    say "size: $size" if $self->verbose;
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
    my %patterns;
    if ($size < $self->divisions) {
        my $div = $self->beats / $size;
        my ($next, $pats) = $self->prefill_part->($self);
        for my $drum (keys $self->drums->%*) {
            if ($drum eq 'snare') {
                $patterns{$drum} = [ $pats->{$drum}->@[0 .. $div - 1], @converted[0 .. $div - 1] ]
            }
            else {
                $patterns{$drum} = [ $pats->{$drum}->@[0 .. $div - 1], (0) x $div ];
            }
        }
    }
    else {
        for my $drum (keys $self->drums->%*) {
            if ($drum eq 'snare') {
                $patterns{$drum} = \@converted;
            }
            else {
                $patterns{$drum} = [ (0) x $self->beats ];
            }
        }
    }
    my $next = '_default_fill';
    return $next, \%patterns;
}


sub velocity($self) {
    my $random = $self->velo_off + int(rand($self->velo_max - $self->velo_min + 1)) + $self->velo_min;
    return $random;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Music::SimpleDrumMachine - Simple 16th-note-phrase Drummer

=head1 VERSION

version 0.0403

=head1 SYNOPSIS

  use Music::SimpleDrumMachine ();

  my $dm = Music::SimpleDrumMachine->new( # use defaults
    port_name => 'midi device', # required
  );

  # OR:
  $dm = Music::SimpleDrumMachine->new(
    port_name => 'midi device',
    bpm       => 100,
    parts     => {
        part_A => \&part_A,
        part_B => \&part_B,
    },
    next_part => 'part_A',
    fills     => { fill_A => \&fill_A },
    next_fill => 'fill_A',
    verbose   => 1,
  );

  sub part_A {
      print "part A\n";
      my %patterns = (
          hihat => [qw(1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0)],
          kick  => [qw(1 0 0 0 0 0 0 0 1 0 0 0 0 0 0 1)],
          snare => [qw(0 0 0 0 1 0 0 0 0 0 0 0 1 0 1 0)],
      );
      my $next = 'part_B';
      return $next, \%patterns;
  }
  sub part_B {
      print "part B\n";
      my %patterns = (
          hihat => [qw(1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1)],
          kick  => [qw(1 0 0 0 0 0 0 0 1 0 1 0 0 0 0 0)],
          snare => [qw(0 0 0 0 1 0 0 0 0 0 0 0 1 0 0 0)],
      );
      my $next = 'part_A';
      return $next, \%patterns;
  }
  sub fill_A {
      print "fill_A\n";
      my %patterns = (
          snare => [qw(1 0 1 0 1 1 1 1 0 1 0 1 1 0 1 0)],
      );
      my $next = 'fill_A';
      return $next, \%patterns;
  }

=head1 DESCRIPTION

C<Music::SimpleDrumMachine> is a simple 16th-note-phrase drummer. By
invoking this module, your MIDI device will begin playing in
real-time.

* Triplets are not supported. Boo!

* Use the extra-handy eg/list_devices.pl program to see the names of
the open MIDI ports on the system.

=head1 ATTRIBUTES

=head2 add_drums

  add_drums => \%drums,

Add an array-ref of hash-refs of the form
C<[{ drum =E<gt> 'name', num =E<gt> midi_num, chan =E<gt> channel }]>
to the known drums in the constructor. The B<chan> key is optional
and is only necessary if you want to assign a drum to a specific
channel.

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
  $dm->drums($drums);

The known drums.

Default:

  kick  => { num => 36, chan => ..., pat => [] },
  snare => { num => 38, chan => ..., pat => [] },
  hihat => { num => 42, chan => ..., pat => [] },
  fillcrash => { num => 49, chan => ..., pat => [] },

=head2 fill_crash

  $fill_crash = $dm->fill_crash;
  $dm->fill_crash($boolean);

Should we crash after a fill?

Default: C<1>

=head2 fills

  $fills = $dm->fills;
  $dm->fills($fills);

List of code-refs of the fills to play.

Default: C<[_default_fill()]>

=head2 filling

  $filling = $dm->filling;
  $dm->filling($boolean);

Should we fill between parts?

Default: C<1>

=head2 next_fill

  $next_fill = $dm->next_fill;
  $dm->next_fill($next_fill);

Name of the fill to play first and set subsequently in a fill.

Default: C<'_default_fill'>

=head2 next_part

  $next_part = $dm->next_part;
  $dm->next_part($next_part);

Name of the part to play first and set subsequently in a part.

Default: C<'_default_part'>

=head2 notes

  $notes = $dm->notes;
  $dm->notes($notes);

The notes to set for each drum - why not?

Default: C<[60, 64, 67]>

=head2 parts

  $parts = $dm->parts;
  $dm->parts($parts);

List of code-refs of the parts to play.

Default: C<[_default_part()]>

=head2 port_name

  $port = $dm->port_name;

The name of the MIDI output port.

Default: C<usb>

=head2 ppqn

  $ppqn = $dm->ppqn;

The "pulses per quarter-note" or "clocks per beat."

Default: C<24>

=head2 prefill_part

  $prefill_part = $dm->prefill_part;

Code-ref of the part to play for 1/2-bar fills.

Default: C<\&_default_part>

=head2 verbose

  $verbose = $dm->verbose;

Show progress.

Default: C<0>

=head2 velo_max

  $velo_max = $dm->velo_max;
  $dm->velo_max($max);

The maximum allowed relative velocity from the B<velo_off> offset.

Default: C<10>

=head2 velo_min

  $velo_min = $dm->velo_min;
  $dm->velo_min($min);

The minimum allowed relative velocity from the B<velo_off> offset.

Default: C<-10>

=head2 velo_off

  $velo_off = $dm->velo_off;
  $dm->velo_off($offset);

The velocity offset.

Default: C<110>

=head1 METHODS

=head2 new

  $dm = Music::SimpleDrumMachine->new(%arguments);

Create a new C<Music::SimpleDrumMachine> object.

=for Pod::Coverage BUILD

=head2 velocity

  $dm->velocity;

Return a random velocity between the B<velo_min> (minimum) and
B<velo_max> (maximum), starting at the B<velo_off> offset.

So, for C<-10, 10, 110> (the default), a number between C<100> and
C<120> will be returned. The triple C<0, 0, 127> will return C<127>
every time.

=head1 SEE ALSO

The F<eg/*.pl> programs in this distribution.

L<IO::Async::Loop>

L<IO::Async::Timer::Periodic>

L<MIDI::RtMidi::FFI::Device>

L<Moo>

L<Music::Duration::Partition>

=head1 AUTHOR

Gene Boggs <gene.boggs@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
