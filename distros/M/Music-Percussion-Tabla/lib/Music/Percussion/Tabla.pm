package Music::Percussion::Tabla;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Play the tabla!

our $VERSION = '0.0405';

use Moo;
use File::ShareDir qw(dist_dir);
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
            dhun => [qw(67 80)],
            ge   => [qw(65 66 76)],
            ke   => [qw(64 77 79)],
            na   => [qw(78 81)],
            ta   => [qw(71 75 85 88)],
            ti   => [qw(61 68 70 72 82 86)],
            tin  => [qw(60 63 83 87)],
            tun  => [qw(73)],
        }
    },
);


sub BUILD {
    my ($self, $args) = @_;
    $self->set_channel(0);
}


sub strike {
    my ($self, $bol, $dura, $patch) = @_;
    $dura ||= $self->quarter;
    my $patches = $self->patches->{$bol};
    $patch = $patches->[ int rand @$patches ]
        if $patches && (!defined $patch || $patch < 0);
    $self->note($dura, $patch);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Music::Percussion::Tabla - Play the tabla!

=head1 VERSION

version 0.0405

=head1 SYNOPSIS

  use Music::Percussion::Tabla ();

  my $t = Music::Percussion::Tabla->new;

  $t->timidity_cfg('/tmp/timidity.cfg'); # optional

  say $t->soundfont;

  for (1 .. $t->bars) {
    $t->strike('ta', $t->eighth);
    $t->strike('ta', $t->eighth);
    $t->strike('tun');
    $t->strike('ge');
    $t->rest($t->quarter);
  }

  $t->play_with_timidity;
  # OR:
  $t->write; # save the score as a MIDI file

=head1 DESCRIPTION

C<Music::Percussion::Tabla> provides named associations between tabla
drum sounds and the included soundfont file (which is B<4.1MB>).

Here are my "non-tabla player" descriptions of the sounds:

   # MIDI Bol  - Description
  ...
   1  60  tin  - ringing mid
   2  61  ti   - muted low
   3  62  ?    - slap
   4  63  tin  - ringing mid slap
   5  64  ke   - low knock
   6  65  ge   - muted ringing low
   7  66  ge   - lower
   8  67  dhun - low-up
   9  68  ti   - muted slap
  10  69  ?    - ringing low
  11  70  ti   - flam slap
  12  71  ta   - loud tap
  13  72  ti   - lowest mute
  14  73  tun  - ringing low
  15  74  ?    - muted low
  16  75  ta   - loud tap double
  17  76  ge   - high-low
  18  77  ke   - high slap
  19  78  na   - tap
  20  79  ?    - high knock
  21  80  dhun - short low-up
  22  81  na   - mid tap
  23  82  ti   - muted tap
  24  83  tin  - mid
  25  84  ?    - muted
  26  85  ta   - loud mid double
  27  86  ti   - slightly more muted
  28  87  tin  - low mid
  29  88  ta   - ringing mid
  ...

To play patches by number (for the unknown bols, for instance), do
this to add to the C<84>th MIDInum entry score:

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

Default bol patches:

  dhun: 67 80
  ge:   65 66 76
  ke:   64 77 79
  na:   78 81
  ta:   71 75 85 88
  ti:   61 68 70 72 82 86
  tin:  60 63 83 87
  tun:  73

=head1 METHODS

=head2 new

  $tabla = Music::Percussion::Tabla->new(%args);

Create a new C<Music::Percussion::Tabla> object. This uses the
constructor attributes of L<MIDI::Drummer::Tiny>.

=for Pod::Coverage BUILD

=head2 strike

  $tabla->strike('dhun');
  $tabla->strike('ge', $duration);
  $tabla->strike('ti', $duration, $patch);

Bols:

  dhun, ge, ke, na, ta, ti, tin, tun

The B<duration> is a note length like C<$tabla-E<gt>eighth> (or
C<'en'> in MIDI-Perl notation).

Each bol can be 1 or more patch numbers. For bols with more than one
patch possibility, calling that method with either no B<patch> or a
B<patch> of C<-1> will play one of the patches at random.

=head1 SEE ALSO

The F<t/01-methods.t> and F<eg/*> programs in this distribution.

L<Moo>

L<File::ShareDir>

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
