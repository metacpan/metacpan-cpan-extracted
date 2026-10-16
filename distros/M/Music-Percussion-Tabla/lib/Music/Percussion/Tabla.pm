package Music::Percussion::Tabla;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Play the tablas!

our $VERSION = '0.0803';

use Moo;
use File::ShareDir qw(dist_dir);
use List::Util qw(any);
use MIDI::Util qw(dura_size ticks);
use strictures 2;
use namespace::clean;

extends 'MIDI::Drummer::Tiny';


has soundfont => (
    is      => 'ro',
    builder => 1,
);

sub _build_soundfont {
    my ($self) = @_;
    my $dir = eval { dist_dir('Music-Percussion-Tabla') };
    $dir ||= 'share';
    return $dir . '/Tabla.sf2';
}


has patches => (
    is      => 'ro',
    default => sub {
        {
            # single strikes
            de   => [qw(62)],
            din  => [qw(63)],
            ge   => [qw(61 65 66 67 69 73 76 80)],
            ke   => [qw(64 68 70 74)],
            na   => [qw(71 75 78)],
            ne   => [qw(72)],
            re   => [qw(77)],
            te   => [qw(82 84)],
            ti   => [qw(86)],
            thap => [qw(85)],
            tin  => [qw(79 87)],
            tu   => [qw(60)],
            sur  => [qw(81 83)],
            # double strikes
            dha  => [qw(ge te)],
            dhin => [qw(ge tin)],
            dhit => [qw(ge ti)],
            dhun => [qw(ge tu)],
        }
    },
);


sub BUILD {
    my ($self, $args) = @_;
    $self->set_channel(0); # XXX what?
}


sub strike {
    my ($self, $bol, $dura) = @_;
    $dura ||= $self->quarter;
    my @patches = map { _pick($self, $_) } ref $bol eq 'ARRAY' ? @$bol : $bol;
    $self->note($dura, @patches);
    return [ [ $dura, @patches ] ];   # same shape as before for single/double bols
}

sub _pick {
    my ($self, $name) = @_;
    my $patches = $self->patches->{$name} // die "Unknown bol '$name'\n";
    return map { _pick($self, $_) } @$patches   # double bol: both members
        if any { /[a-z]/ } @$patches;
    return $patches->[ int rand @$patches ];    # single bol: one patch
}

sub _double {
    my ($self, $bols, $dura) = @_;
    my $patches = $self->patches->{ $bols->[0] };
    my $baya = $patches->[ int rand @$patches ];
    $patches = $self->patches->{ $bols->[1] };
    my $daya = $patches->[ int rand @$patches ];
    $self->note($dura, $baya, $daya);
    return [ $dura, $baya, $daya ];
}

sub _single {
    my ($self, $bols, $dura) = @_;
    my $patch = $bols->[ int rand @$bols ];
    $self->note($dura, $patch);
    return [ $dura, $patch ];
}


sub teentaal {
    my ($self, $dura) = @_;
    $dura ||= $self->quarter;
    my @strikes;
    for (1 .. 2) {
        push @strikes, $self->strike('dha', $dura);
        push @strikes, $self->strike('dhin', $dura);
        push @strikes, $self->strike('dhin', $dura);
        push @strikes, $self->strike('dha', $dura);
    }
    push @strikes, $self->strike('dha', $dura);
    push @strikes, $self->strike('tin', $dura);
    push @strikes, $self->strike('tin', $dura);
    push @strikes, $self->strike('te', $dura);
    push @strikes, $self->strike('te', $dura);
    push @strikes, $self->strike('dhin', $dura);
    push @strikes, $self->strike('dhin', $dura);
    push @strikes, $self->strike('dha', $dura);
    return \@strikes;
}

sub keherawa {
    my ($self, $dura) = @_;
    $dura ||= $self->quarter;
    my @strikes;
    push @strikes, $self->strike('dha', $dura);
    push @strikes, $self->strike('ge', $dura);
    push @strikes, $self->strike('na', $dura);
    push @strikes, $self->strike('tin', $dura);
    push @strikes, $self->strike('na', $dura);
    push @strikes, $self->strike('ke', $dura);
    push @strikes, $self->strike('dhin', $dura);
    push @strikes, $self->strike('na', $dura);
    return \@strikes;
}

sub jhaptaal {
    my ($self, $dura) = @_;
    $dura ||= $self->quarter;
    my @strikes;
    push @strikes, $self->strike('dhin', $dura);
    push @strikes, $self->strike('na', $dura);
    push @strikes, $self->strike('dhin', $dura);
    push @strikes, $self->strike('dhin', $dura);
    push @strikes, $self->strike('na', $dura);
    push @strikes, $self->strike('tin', $dura);
    push @strikes, $self->strike('na', $dura);
    push @strikes, $self->strike('dhin', $dura);
    push @strikes, $self->strike('dhin', $dura);
    push @strikes, $self->strike('na', $dura);
    return \@strikes;
}

sub dadra {
    my ($self, $dura) = @_;
    $dura ||= $self->quarter;
    my @strikes;
    push @strikes, $self->strike('dha', $dura);
    push @strikes, $self->strike('dhin', $dura);
    push @strikes, $self->strike('na', $dura);
    push @strikes, $self->strike('dha', $dura);
    push @strikes, $self->strike('ti', $dura);
    push @strikes, $self->strike('na', $dura);
    return \@strikes;
}

sub rupaktaal {
    my ($self, $dura) = @_;
    $dura ||= $self->quarter;
    my @strikes;
    push @strikes, $self->strike('tin', $dura);
    push @strikes, $self->strike('tin', $dura);
    push @strikes, $self->strike('na', $dura);
    push @strikes, $self->strike('dhin', $dura);
    push @strikes, $self->strike('na', $dura);
    push @strikes, $self->strike('dhin', $dura);
    push @strikes, $self->strike('na', $dura);
    return \@strikes;
}

sub ektaal {
    my ($self, $dura) = @_;
    $dura ||= $self->quarter;
    my @strikes;
    my $ticks = ticks($self->score);
    my $dura4 = 'd' . ($ticks * dura_size($dura) / 4);
    push @strikes, $self->strike('dhin', $dura);
    push @strikes, $self->strike('dhin', $dura);
    push @strikes, $self->strike('dha', $dura);
    push @strikes, $self->tirakita($dura4);
    push @strikes, $self->strike('ti', $dura);
    push @strikes, $self->strike('na', $dura);
    push @strikes, $self->strike('ke', $dura);
    push @strikes, $self->strike('te', $dura);
    push @strikes, $self->strike('dha', $dura);
    push @strikes, $self->tirakita($dura4);
    push @strikes, $self->strike('dhin', $dura);
    push @strikes, $self->strike('na', $dura);
    return \@strikes;
}

sub arachartaal {
    my ($self, $dura) = @_;
    $dura ||= $self->quarter;
    my $ticks = ticks($self->score);
    my $dura4 = 'd' . ($ticks * dura_size($dura) / 4);
    my @strikes;
    push @strikes, $self->strike('dhin', $dura);
    push @strikes, $self->tirakita($dura4);
    push @strikes, $self->strike('dhit', $dura);
    push @strikes, $self->strike('na', $dura);
    push @strikes, $self->strike('ti', $dura);
    push @strikes, $self->strike('na', $dura);
    push @strikes, $self->strike('ke', $dura);
    push @strikes, $self->strike('te', $dura);
    push @strikes, $self->tirakita($dura4);
    push @strikes, $self->strike('dhit', $dura);
    push @strikes, $self->strike('na', $dura);
    push @strikes, $self->strike('dhit', $dura);
    push @strikes, $self->strike('dhit', $dura);
    push @strikes, $self->strike('na', $dura);
    return \@strikes;
}

sub tirakita {
    my ($self, $dura) = @_;
    $dura ||= $self->quarter;
    my @strikes;
    push @strikes, $self->strike('ti', $dura);
    push @strikes, $self->strike('na', $dura);
    push @strikes, $self->strike('ke', $dura);
    push @strikes, $self->strike('te', $dura);
    return \@strikes;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Music::Percussion::Tabla - Play the tablas!

=head1 VERSION

version 0.0803

=head1 SYNOPSIS

  use Music::Percussion::Tabla ();

  my $t = Music::Percussion::Tabla->new(file => 'tablas.mid');

  print 'Soundfont: ', $t->soundfont, "\n"; # sf2 file location

  for (1 .. $t->bars) {
    $t->strike('te', $t->eighth); # write to the score
    $t->strike('te', $t->eighth);
    $t->strike('dha');
    $t->strike('ge');
    $t->rest($t->quarter);
  }

  my @strikes; # optionally save the notes for other purposes

  push @strikes, $t->strike(['ge', 'ke']); # double-strike

  for (1 .. 2) {
    push @strikes, $t->strike('ke', $t->sixteenth) for 1 .. 3;
    push @strikes, $t->strike('ti', $t->sixteenth) for 1 .. 4;
  }

  print "Strikes: @strikes\n";

  $t->rest($t->quarter);

  $t->tirakita($t->sixteenth) for 1 .. 2;

  push @strikes, $t->teentaal; # as above
  $t->keherawa($t->eighth)  for 1 .. $t->bars;
  $t->jhaptaal($t->eighth)  for 1 .. $t->bars;
  $t->dadra($t->eighth)     for 1 .. $t->bars;
  $t->rupaktaal($t->eighth) for 1 .. $t->bars;
  $t->rupaktaal($t->eighth) for 1 .. $t->bars;
  $t->ektaal;
  $t->arachartaal;

  $t->write; # save the score as tablas.mid

=head1 DESCRIPTION

C<Music::Percussion::Tabla> provides named associations between tabla
drum sounds and the included soundfont file (which is B<4.1MB>).

To play F<tablas.mid> with fluidsynth and the soundfont file (as
printed above), do this:

  fluidsynth -i <the tabla sf2 file> tablas.mid

Here are the names and descriptions of the sounds:

     # Number Name Description
    ...
     1  60  tu   "ringing mid"
     2  61  ge   "muted low"
     3  62  de   "slap"
     4  63  din  "ringing mid slap"
     5  64  ke   "low knock"
     6  65  ge   "muted ringing low"
     7  66  ge   "lower"
     8  67  ge   "low-up"
     9  68  ke   "muted slap"
    10  69  ge   "ringing low"
    11  70  ke   "flam slap"
    12  71  na   "loud tap"
    13  72  ne   "lowest mute"
    14  73  ge   "ringing low open"
    15  74  ke   "muted low"
    16  75  na   "loud tap"
    17  76  ge   "high-low"
    18  77  re   "high slap"
    19  78  na   "sharp tap"
    20  79  tin  "high knock"
    21  80  ge   "short low-up sliding"
    22  81  sur  "mid tap"
    23  82  te   "muted tap"
    24  83  sur  "mid"
    25  84  te   "muted"
    26  85  thap "loud mid double"
    27  86  ti   "slightly more muted"
    28  87  tin  "low mid"
    29  88  tu   "ringing mid"
  ...

To play patches by number instead of name (e.g. for the C<*> unknown
bols), do this to add the C<84>th MIDInum entry score:

  $tabla->note($tabla->eighth, 84);

To play patches simultaneously, that would be:

  $tabla->note($tabla->eighth, 84, 80);

=head1 ATTRIBUTES

=head2 soundfont

  $soundfont = $tabla->soundfont;

The file location, where the tabla soundfont resides.

Default: C<dist_dir()/Tabla.sf2>

=head2 patches

  $patches = $tabla->patches;

Each bol can have 1 or more patch numbers.

Default single strike bol patches:

  de:   62
  din:  63
  ge:   61 65 66 67 69 73 76 80
  ke:   64 68 70 74
  na:   71 75 78
  ne:   72
  re:   77
  te:   82 84
  thap: 85
  ti:   86
  tin:  79 87
  tu:   60
  sur:  81 83

Default double strike bols:

  dha:  ge te
  dhin: ge tin
  dhit: ge ti
  dhun: ge tu

=head1 METHODS

=head2 new

  $tabla = Music::Percussion::Tabla->new(%args);

Create a new C<Music::Percussion::Tabla> object. This uses the
constructor attributes of L<MIDI::Drummer::Tiny>.

=for Pod::Coverage BUILD

=head2 strike

  $tabla->strikes($bol);
  $tabla->strikes([$bol1, $bol2]);
  $tabla->strikes($bol, $duration);

Add to the strike to the score and also return a MIDI note
specification C<[$duration, @note_list]> for external handling.

This method handles two types of strikes: single and double.

A named B<bol> can have one or more B<patches> associated with it. For
single strikes, the method will play one of the B<bol> patches at
random.

A B<bol> that is an array reference of two named bols, signifies a
double-strike on the given members.

The B<duration> is a note length like C<$tabla-E<gt>eighth> (or
C<'en'> in MIDI-Perl notation).

(If specific patches are desired, use the C<note> method, as shown
above.)

For a double strike, play both the baya and daya drums for the given
B<bol> and B<duration>.

Each of the individual bol patches, comprising the double-strike, are
chosen at random, as with the single-strike.

=head2 thekas

Traditional "groove patterns":

=over

=item teentaal([$duration])

16 beats

=item keherawa([$duration])

8 beats

=item jhaptaal([$duration])

10 beats

=item dadra([$duration])

6 beats

=item rupaktaal([$duration])

7 beats

=item ektaal([$duration])

12 beats

=item arachartaal([$duration])

14 beats

=item tirakita([$duration])

4 beats

=back

=head1 SEE ALSO

The F<t/01-methods.t> and F<eg/*> programs in this distribution.

L<Moo>

L<File::ShareDir>

L<List::Util>

L<https://gleitz.github.io/midi-js-soundfonts/Tabla/Tabla.sf2> (4.1MB)

L<https://www.wikihow.com/Play-Tabla>

L<https://www.taalgyan.com/theory/basic-bols-on-tabla/>

L<https://kksongs.org/tabla/chapter02.html> &
L<https://kksongs.org/tabla/chapter03.html>

L<https://www.fluidsynth.org/>

=head1 AUTHOR

Gene Boggs <gene.boggs@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023-2026 by Gene Boggs.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
