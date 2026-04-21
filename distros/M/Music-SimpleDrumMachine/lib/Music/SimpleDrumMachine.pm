package Music::SimpleDrumMachine;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Simple 16th-note-phrase Drummer

our $VERSION = '0.0508';

use v5.36;
use feature 'try';

use Moo;
use strictures 2;
use Carp qw(croak);
# use Data::Dumper::Compact qw(ddc);
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
        kick         => { num => 36, chan => $self->chan < 0 ?  0 : $self->chan, pat => [] },
        snare        => { num => 38, chan => $self->chan < 0 ?  1 : $self->chan, pat => [] },
        closed       => { num => 42, chan => $self->chan < 0 ?  2 : $self->chan, pat => [] },
        fillcrash    => { num => 49, chan => $self->chan < 0 ?  3 : $self->chan, pat => [] },
        open         => { num => 46, chan => $self->chan < 0 ?  4 : $self->chan, pat => [] },
        rimshot      => { num => 37, chan => $self->chan < 0 ?  5 : $self->chan, pat => [] },
        clap         => { num => 39, chan => $self->chan < 0 ?  6 : $self->chan, pat => [] },
        shaker       => { num => 70, chan => $self->chan < 0 ?  7 : $self->chan, pat => [] },
        cowbell      => { num => 56, chan => $self->chan < 0 ?  8 : $self->chan, pat => [] },
        crash        => { num => 57, chan => $self->chan < 0 ? 10 : $self->chan, pat => [] }, # skip 9
        hi_tom       => { num => 48, chan => $self->chan < 0 ? 11 : $self->chan, pat => [] },
        mid_tom      => { num => 47, chan => $self->chan < 0 ? 12 : $self->chan, pat => [] },
        low_tom      => { num => 45, chan => $self->chan < 0 ? 13 : $self->chan, pat => [] },
        conga        => { num => 45, chan => $self->chan < 0 ? 14 : $self->chan, pat => [] },
        kick2        => { num => 35, chan => $self->chan < 0 ? 15 : $self->chan, pat => [] },
        snare2       => { num => 40, chan => $self->chan < 0 ? 16 : $self->chan, pat => [] }, # bogus channels now...
        pedal        => { num => 44, chan => $self->chan < 0 ? 19 : $self->chan, pat => [] },
        low_floor    => { num => 41, chan => $self->chan < 0 ? 17 : $self->chan, pat => [] },
        hi_floor     => { num => 43, chan => $self->chan < 0 ? 18 : $self->chan, pat => [] },
        hihi_tom     => { num => 50, chan => $self->chan < 0 ? 20 : $self->chan, pat => [] },
        ride         => { num => 51, chan => $self->chan < 0 ? 21 : $self->chan, pat => [] },
        ride_bell    => { num => 53, chan => $self->chan < 0 ? 22 : $self->chan, pat => [] },
        ride2        => { num => 59, chan => $self->chan < 0 ? 23 : $self->chan, pat => [] },
        china        => { num => 52, chan => $self->chan < 0 ? 24 : $self->chan, pat => [] },
        splash       => { num => 55, chan => $self->chan < 0 ? 25 : $self->chan, pat => [] },
        tamborine    => { num => 54, chan => $self->chan < 0 ? 26 : $self->chan, pat => [] },
        vibraslap    => { num => 58, chan => $self->chan < 0 ? 27 : $self->chan, pat => [] },
        hi_bongo     => { num => 60, chan => $self->chan < 0 ? 28 : $self->chan, pat => [] },
        low_bongo    => { num => 61, chan => $self->chan < 0 ? 29 : $self->chan, pat => [] },
        mute_conga   => { num => 62, chan => $self->chan < 0 ? 30 : $self->chan, pat => [] },
        low_conga    => { num => 64, chan => $self->chan < 0 ? 31 : $self->chan, pat => [] },
        hi_timbale   => { num => 65, chan => $self->chan < 0 ? 32 : $self->chan, pat => [] },
        low_timbale  => { num => 66, chan => $self->chan < 0 ? 33 : $self->chan, pat => [] },
        hi_agogo     => { num => 67, chan => $self->chan < 0 ? 34 : $self->chan, pat => [] },
        low_agogo    => { num => 67, chan => $self->chan < 0 ? 35 : $self->chan, pat => [] },
        cabasa       => { num => 69, chan => $self->chan < 0 ? 36 : $self->chan, pat => [] },
        whistle      => { num => 71, chan => $self->chan < 0 ? 37 : $self->chan, pat => [] },
        long_whistle => { num => 72, chan => $self->chan < 0 ? 38 : $self->chan, pat => [] },
        guiro        => { num => 73, chan => $self->chan < 0 ? 39 : $self->chan, pat => [] },
        long_guiro   => { num => 74, chan => $self->chan < 0 ? 40 : $self->chan, pat => [] },
        claves       => { num => 75, chan => $self->chan < 0 ? 41 : $self->chan, pat => [] },
        wood_block   => { num => 76, chan => $self->chan < 0 ? 42 : $self->chan, pat => [] },
        low_block    => { num => 77, chan => $self->chan < 0 ? 43 : $self->chan, pat => [] },
        mute_cuica   => { num => 78, chan => $self->chan < 0 ? 44 : $self->chan, pat => [] },
        open_cuica   => { num => 79, chan => $self->chan < 0 ? 45 : $self->chan, pat => [] },
        mute_tri     => { num => 80, chan => $self->chan < 0 ? 46 : $self->chan, pat => [] },
        open_tri     => { num => 81, chan => $self->chan < 0 ? 47 : $self->chan, pat => [] },
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
        _hats       => 0, # 1st hihat beat bit
        _part_inc   => 0, # number of next_part
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
                if (($self->filling || (ref($self->next_part) && $self->next_part->[ $self->_part_inc % $self->next_part->@* ] =~ /fill/))
                    && ($self->_beat_count + $self->beats - $self->_trigger) % ($self->beats * $self->divisions - 1) == 0
                ) {
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
            $self->drums->{closed}{pat}[0] = 0; # mutually exclusive
        }
        else {
            $self->drums->{fillcrash}{pat}[0] = 0; # not crashing
            $self->drums->{closed}{pat}[0] = $self->_hats; # restore hihat bit
        }
    }
}

sub _adjust_drums($self, $fill_flag) {
    say 'Beats: ' . $self->_beat_count if $self->verbose;
    my ($next, $patterns, $part, $name);
    if (ref $self->next_part eq 'ARRAY') {
        $name = $self->next_part->[ $self->_part_inc % $self->next_part->@* ];
        $part = $self->parts->{$name};
    }
    # play a fill or a part
    if (($self->filling || $name =~ 'fill') && $fill_flag) {
        $part ||= $self->fills->{ $self->next_fill };
        ($next, $patterns) = $part->();
        if ($next) {
            $self->next_fill($next);
        }
        else {
            $self->_part_inc($self->_part_inc + 1);
        }
    }
    else {
        $part ||= $self->parts->{ $self->next_part };
        ($next, $patterns) = $part->();
        if ($next) {
            $self->next_part($next);
        }
        else {
            $self->_part_inc($self->_part_inc + 1);
        }
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
        $self->_hats($self->drums->{closed}{pat}[0]); # save bit
        $self->drums->{fillcrash}{pat} = [ (0) x ($self->beats * $self->divisions) ];
        $self->_adjust_cymbals;
        $self->_filled(0);
    }
}

sub _default_part($self) {
    say '_default_part' if $self->verbose;
    my %patterns = (
        closed => [qw(1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0)],
        kick   => [qw(1 0 0 0 0 0 0 0 1 0 1 0 0 0 0 0)],
        snare  => [qw(0 0 0 0 1 0 0 0 0 0 0 0 1 0 0 0)],
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

version 0.0508

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
          closed => [qw(1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0)],
          kick   => [qw(1 0 0 0 0 0 0 0 1 0 0 0 0 0 0 1)],
          snare  => [qw(0 0 0 0 1 0 0 0 0 0 0 0 1 0 1 0)],
      );
      my $next = 'part_B';
      return $next, \%patterns;
  }
  sub part_B {
      print "part B\n";
      my %patterns = (
          closed => [qw(1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1)],
          kick   => [qw(1 0 0 0 0 0 0 0 1 0 1 0 0 0 0 0)],
          snare  => [qw(0 0 0 0 1 0 0 0 0 0 0 0 1 0 0 0)],
      );
      my $next = 'part_A';
      return $next, \%patterns;
  }
  sub fill_A {
      print "Fill A\n";
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

The known drums (with short, abbreviated names that I made up).

Default:

  kick         => 36 # Bass Drum 1
  snare        => 38 # Acoustic Snare
  closed       => 42 # Closed Hi Hat
  fillcrash    => 49 # Crash Cymbal 1
  open         => 46 # Open Hi Hat
  rimshot      => 37 # Side Stick
  clap         => 39 # Hand Clap
  shaker       => 70 # Maracas
  cowbell      => 56 # Cowbell
  crash        => 57 # Crash Cymbal 2
  hi_tom       => 48 # Hi Mid Tom
  mid_tom      => 47 # Low Mid Tom
  low_tom      => 45 # Low Tom
  conga        => 63 # Open Hi Conga
  kick2        => 35 # Acoustic Bass Drum
  snare2       => 40 # Electric Snare
  pedal        => 44 # Pedal Hi Hat
  low_floor    => 41 # Low Floor Tom
  hi_floor     => 43 # High Floor Tom
  hihi_tom     => 50 # High Tom
  ride         => 51 # Ride Cymbal 1
  ride_bell    => 53 # Ride Bell
  ride2        => 59 # Ride Cymbal 2
  china        => 52 # Chinese Cymbal
  splash       => 55 # Splash Cymbal
  tamborine    => 54 # Tambourine
  vibraslap    => 58 # Vibraslap
  hi_bongo     => 60 # Hi Bongo
  low_bongo    => 61 # Low Bongo
  mute_conga   => 62 # Mute Hi Conga
  low_conga    => 64 # Low Conga
  hi_timbale   => 65 # High Timbale
  low_timbale  => 66 # Low Timbale
  hi_agogo     => 67 # High Agogo
  low_agogo    => 68 # Low Agogo
  cabasa       => 69 # Cabasa
  whistle      => 71 # Short Whistle
  long_whistle => 72 # Long Whistle
  guiro        => 73 # Short Guiro
  long_guiro   => 74 # Long Guiro
  claves       => 75 # Claves
  wood_block   => 76 # Hi Wood Block
  low_block    => 77 # Low Wood Block
  mute_cuica   => 78 # Mute Cuica
  open_cuica   => 79 # Open Cuica
  mute_tri     => 80 # Mute Triangle
  open_tri     => 81 # Open Triangle

But literally B<any> name could be used, as long as the number is a
known MIDI percussion instrument number.

=head2 fill_crash

  $fill_crash = $dm->fill_crash;
  $dm->fill_crash($boolean);

Should we crash after a fill?

Default: C<1>

=head2 fills

  $fills = $dm->fills;
  $dm->fills($fills);

List of named code-refs of the fills to play.

Default: C<{ _default_fill =E<gt> \&_default_fill }>

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

Name of the part or list of parts to play first and also set
subsequently in a part.

If this is an array-reference, the named parts or fills are played in
succession.

Default: C<'_default_part'>

=head2 notes

  $notes = $dm->notes;
  $dm->notes($notes);

The notes to set for each drum - why not?

Default: C<[60, 64, 67]>

=head2 parts

  $parts = $dm->parts;
  $dm->parts($parts);

List of named code-refs of the parts to play.

If a part has C<'fill'> in the name, it will be played for a single
bar, on the 3rd bar of a 4-bar phrase iff the B<filling> attribute is
set to zero.

Default: C<{ _default_part =E<gt> \&_default_part }>

=head2 port_name

  $port = $dm->port_name;

The name of the MIDI output port. This can be the full name or a
unique part of the name, like C<'usb'> for C<'USB MIDI Interface'>,
for instance. Case is ignored.

Default: C<usb>

=head2 ppqn

  $ppqn = $dm->ppqn;

The "pulses per quarter-note" or "clocks per beat."

Default: C<24>

=head2 prefill_part

  $prefill_part = $dm->prefill_part;

Code-ref of the part to play for 1/2-bar fills.

Default: C<\&_default_part>

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

=head2 verbose

  $verbose = $dm->verbose;

Show progress.

Default: C<0>

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
