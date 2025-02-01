package Music::Percussion::Tabla;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Play the tabla!

our $VERSION = '0.0701';

use Moo;
use File::ShareDir qw(dist_dir);
use List::Util qw(any);
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
            ga   => [qw(65)],
            ge   => [qw(66 76)],
            ke   => [qw(64 77 79)],
            na   => [qw(78 81)],
            ta   => [qw(71 75 85)],
            ti   => [qw(61 68 70 72 82 86)],
            tin  => [qw(60 63 83 87)],
            tun  => [qw(88)],
            # double strikes
            dha  => [qw(ge ta)],
            dhin => [qw(ge tin)],
            dhit => [qw(ge ti)],
            dhun => [qw(ge tun)],
        }
    },
);


sub BUILD {
    my ($self, $args) = @_;
    $self->set_channel(0);
}


sub strike {
    my ($self, $bol, $dura, $return) = @_;
    $dura ||= $self->quarter;
    my $bols = $self->patches->{$bol};
    if (ref $bol eq 'ARRAY') {
        my $patches = $self->patches->{ $bol->[0] };
        if (any { /[a-z]/ } @$patches) {
            _double($self, $patches, $dura);
        }
        else {
            _single($self, $patches, $dura);
        }
        $patches = $self->patches->{ $bol->[1] };
        if (any { /[a-z]/ } @$patches) {
            _double($self, $patches, $dura);
        }
        else {
            _single($self, $patches, $dura);
        }
    }
    elsif (any { /[a-z]/ } @$bols) {
        _double($self, $bols, $dura);
    }
    else {
        _single($self, $bols, $dura);
    }
}

sub _double {
    my ($self, $bols, $dura) = @_;
    my $patches = $self->patches->{ $bols->[0] };
    my $baya = $patches->[ int rand @$patches ];
    $patches = $self->patches->{ $bols->[1] };
    my $daya = $patches->[ int rand @$patches ];
    $self->note($dura, $baya, $daya);
}

sub _single {
    my ($self, $bols, $dura) = @_;
    my $patch = $bols->[ int rand @$bols ];
    $self->note($dura, $patch);
}


sub teentaal {
    my ($self, $dura) = @_;
    $dura ||= $self->quarter;
    for (1 .. 2) {
        $self->strike('dha', $dura);
        $self->strike('dhin', $dura);
        $self->strike('dhin', $dura);
        $self->strike('dha', $dura);
    }
    $self->strike('dha', $dura);
    $self->strike('tin', $dura);
    $self->strike('tin', $dura);
    $self->strike('ta', $dura);
    $self->strike('ta', $dura);
    $self->strike('dhin', $dura);
    $self->strike('dhin', $dura);
    $self->strike('dha', $dura);
}

sub keherawa {
    my ($self, $dura) = @_;
    $dura ||= $self->quarter;
    $self->strike('dha', $dura);
    $self->strike('ge', $dura);
    $self->strike('na', $dura);
    $self->strike('tin', $dura);
    $self->strike('na', $dura);
    $self->strike('ke', $dura);
    $self->strike('dhin', $dura);
    $self->strike('na', $dura);
}

sub jhaptaal {
    my ($self, $dura) = @_;
    $dura ||= $self->quarter;
    $self->strike('dhin', $dura);
    $self->strike('na', $dura);
    $self->strike('dhin', $dura);
    $self->strike('dhin', $dura);
    $self->strike('na', $dura);
    $self->strike('tin', $dura);
    $self->strike('na', $dura);
    $self->strike('dhin', $dura);
    $self->strike('dhin', $dura);
    $self->strike('na', $dura);
}

sub dadra {
    my ($self, $dura) = @_;
    $dura ||= $self->quarter;
    $self->strike('dha', $dura);
    $self->strike('dhin', $dura);
    $self->strike('na', $dura);
    $self->strike('dha', $dura);
    $self->strike('ti', $dura);
    $self->strike('na', $dura);
}

sub rupaktaal {
    my ($self, $dura) = @_;
    $dura ||= $self->quarter;
    $self->strike('tin', $dura);
    $self->strike('tin', $dura);
    $self->strike('na', $dura);
    $self->strike('dhin', $dura);
    $self->strike('na', $dura);
    $self->strike('dhin', $dura);
    $self->strike('na', $dura);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Music::Percussion::Tabla - Play the tabla!

=head1 VERSION

version 0.0701

=head1 SYNOPSIS

  use Music::Percussion::Tabla ();

  my $t = Music::Percussion::Tabla->new;

  for (1 .. $t->bars) {
    $t->strike('ta', $t->eighth);
    $t->strike('ta', $t->eighth);
    $t->strike('dha');
    $t->strike('ge');
    $t->rest($t->quarter);
  }

  $t->strike(['ge', 'ke']); # double-strike

  for (1 .. 2) {
    $t->strike('ke', $t->sixteenth) for 1 .. 3;
    $t->strike('ti', $t->sixteenth) for 1 .. 4;
  }

  $t->rest($t->quarter);

  $t->teentaal($t->eighth)  for 1 .. $t->bars;
  $t->keherawa($t->eighth)  for 1 .. $t->bars;
  $t->jhaptaal($t->eighth)  for 1 .. $t->bars;
  $t->dadra($t->eighth)     for 1 .. $t->bars;
  $t->rupaktaal($t->eighth) for 1 .. $t->bars;

  $t->play_with_timidity;
  # OR:
  $t->write; # save the score as a MIDI file
  $t->timidity_cfg('/Users/you/timidity.cfg');
  # then run timidity with that config and MIDI file

=head1 DESCRIPTION

C<Music::Percussion::Tabla> provides named associations between tabla
drum sounds and the included soundfont file (which is B<4.1MB>).

Here are my "non-tabla player" descriptions of the sounds:

   # MIDI Description
  ...
   1  60  ringing mid
   2  61  muted low
   3  62  slap
   4  63  ringing mid slap
   5  64  low knock
   6  65  muted ringing low
   7  66  lower
   8  67  low-up
   9  68  muted slap
  10  69  ringing low
  11  70  flam slap
  12  71  loud tap
  13  72  lowest mute
  14  73  ringing low
  15  74  muted low
  16  75  loud tap double
  17  76  high-low
  18  77  high slap
  19  78  tap
  20  79  high knock
  21  80  short low-up
  22  81  mid tap
  23  82  muted tap
  24  83  mid
  25  84  muted
  26  85  loud mid double
  27  86  slightly more muted
  28  87  low mid
  29  88  ringing mid
  ...

To play patches by number (e.g. for unknown bols), do this to add the
C<84>th MIDInum entry score:

  $tabla->note($tabla->eighth, 84);

To play patches simultaneously, that would be:

  $tabla->note($tabla->eighth, 84, 79);

=head1 ATTRIBUTES

=head2 soundfont

  $soundfont = $tabla->soundfont;

The file location, where the tabla soundfont resides.

Default: C<dist_dir()/Tabla.sf2>

=head2 patches

  $patches = $tabla->patches;

Each bol can be 1 or more patch numbers.

Default single strike bol patches:

  ga:   65
  ge:   66 76
  ke:   64 77 79
  na:   78 81
  ta:   71 75 85
  ti:   61 68 70 72 82 86
  tin:  60 63 83 87
  tun:  88

Default double strike bols:

  dha:  ge ta
  dhin: ge tin
  dhit: ge ti
  dhun: ge tun

=head1 METHODS

=head2 new

  $tabla = Music::Percussion::Tabla->new(%args);

Create a new C<Music::Percussion::Tabla> object. This uses the
constructor attributes of L<MIDI::Drummer::Tiny>.

=for Pod::Coverage BUILD

=head2 strike

  $tabla->strike($bol);
  $tabla->strike([$bol1, $bol2]);
  $tabla->strike($bol, $duration);

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

1. Single strike bols:

  ga, ge, ke, na, ta, ti, tin, tun

2. Double strike bols:

  dha, dhin, dhit, dhun

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

=head1 AUTHOR

Gene Boggs <gene.boggs@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023-2025 by Gene Boggs.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
