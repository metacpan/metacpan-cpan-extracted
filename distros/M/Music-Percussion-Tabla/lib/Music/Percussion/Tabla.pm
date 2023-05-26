package Music::Percussion::Tabla;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Play the tabla!

our $VERSION = '0.0200';

use Moo;
use File::Slurper qw(write_text);
use MIDI::Util qw(dura_size reverse_dump);
use File::ShareDir qw(dist_dir);
use strictures 2;
use namespace::clean;

extends 'MIDI::Drummer::Tiny';


has soundfont => (is => 'lazy');

sub _build_soundfont {
    my ($self) = @_;
    my $dir = eval { dist_dir('Music-Percussion-Tabla') };
    $dir ||= 'share';
    return $dir . '/Tabla.sf2';
}


has tun_num => (is => 'ro', default => sub { 60 });


has ta_num => (is => 'ro', default => sub { 71 });


has tin_num => (is => 'ro', default => sub { 82 });


has tu_num => (is => 'ro', default => sub { 87 });


has te_num => (is => 'ro', default => sub { 62 });


has tete_num => (is => 'ro', default => sub { 77 });


has ka_num => (is => 'ro', default => sub { 68 });


has ga_num => (is => 'ro', default => sub { 63 });


has ga_slide_num => (is => 'ro', default => sub { 67 });


sub BUILD {
    my ($self, $args) = @_;
    $self->set_channel(0);
}


sub tun {
    my ($self, $dura) = @_;
    $self->_strike($dura, $self->tun_num);
}


sub ta {
    my ($self, $dura) = @_;
    $self->_strike($dura, $self->ta_num);
}


sub tin {
    my ($self, $dura) = @_;
    $self->_strike($dura, $self->tin_num);
}


sub tu {
    my ($self, $dura) = @_;
    $self->_strike($dura, $self->tu_num);
}


sub te {
    my ($self, $dura) = @_;
    $self->_strike($dura, $self->te_num);
}


sub tete {
    my ($self, $dura) = @_;
    $dura ||= $self->quarter;
    $dura = dura_size($dura) / 2;
    my $dump = reverse_dump('length');
    $self->te($dump->{$dura});
    $self->_strike($dump->{$dura}, $self->tete_num);
}


sub ka {
    my ($self, $dura) = @_;
    $self->_strike($dura, $self->ka_num);
}


sub ga {
    my ($self, $dura) = @_;
    $self->_strike($dura, $self->ga_num);
}


sub ga_slide {
    my ($self, $dura) = @_;
    $self->_strike($dura, $self->ga_slide_num);
}


sub dha {
    my ($self, $dura) = @_;
    $self->_double_strike($dura, $self->ga_num, $self->ta_num);
}


sub dhin {
    my ($self, $dura) = @_;
    $self->_double_strike($dura, $self->ga_num, $self->tin_num);
}


sub tirkit {
    my ($self, $dura) = @_;
    $dura ||= $self->quarter;
    $dura = dura_size($dura) / 2;
    my $dura2 = $dura / 2;
    my $dump = reverse_dump('length');
    $self->tete($dump->{$dura});
    $self->ka($dump->{$dura2});
    $self->te($dump->{$dura2});
}

sub _strike {
    my ($self, $dura, $pitch) = @_;
    $dura  ||= $self->quarter;
    $pitch ||= 60;
    $self->note($dura, $pitch);
}

sub _double_strike {
    my ($self, $dura, $pitch1, $pitch2) = @_;
    $dura   ||= $self->quarter;
    $pitch1 ||= 60;
    $pitch2 ||= 61;
    $self->note($dura, $pitch1, $pitch2);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Music::Percussion::Tabla - Play the tabla!

=head1 VERSION

version 0.0200

=head1 SYNOPSIS

  use Music::Percussion::Tabla ();

  my $tabla = Music::Percussion::Tabla->new;

  for my $i (1 .. 3) {
      $tabla->ta;
      $tabla->ta;
      $tabla->tun;
      $tabla->ga;
      $tabla->rest($tabla->quarter);
  }

  say $tabla->soundfont;

  $tabla->timidity_cfg('/tmp/timidity.cfg'); # save the cfg
  $tabla->write; # save the score as a MIDI file

  # OR:
  $tabla->play_with_timidity; # play the score with timidity

=head1 DESCRIPTION

C<Music::Percussion::Tabla> provides named associations between tabla
drum sounds and the included soundfont file.

Here are my "non-tabla player" descriptions of the sounds:

  # MIDI Description
  ...
   1 60  ringing mid
   2 61  muted low
   3 62  slap
   4 63  ringing mid slap
   5 64  low knock
   6 65  muted ringing low
   7 66  lower
   8 67  low-up
   9 68  muted slap
  10 69  ringing low
  11 70  flam slap
  12 71  loud tap
  13 72  lowest mute
  14 73  ringing low
  15 74  muted low
  16 75  loud tap double
  17 76  high-low
  18 77  high slap
  19 78  tap
  20 79  high knock
  21 80  short low-up
  22 81  mid tap
  23 82  muted tap
  24 83  mid
  25 84  muted
  26 85  loud mid double
  27 86  slightly more muted
  28 87  low mid
  29 88  ringing mid
  ...

Only a few are named in this module. To play the others, just do this to add to the score:

  $tabla->note($tabla->eighth, 79);

For baya and daya simultaneously, that would be:

  $tabla->note($tabla->eighth, 79, 87);

=head1 ATTRIBUTES

=head2 soundfont

  $soundfont = $tabla->soundfont;

The file location, where the tabla soundfont resides.

Default: F<dist_dir()/Tabla.sf2>

=head2 tun_num

  $tun_num = $tabla->tun_num;

Default: C<60>

=head2 ta_num

  $ta_num = $tabla->ta_num;

Default: C<71>

=head2 tin_num

  $tin_num = $tabla->tin_num;

Default: C<82>

=head2 tu_num

  $tu_num = $tabla->tu_num;

Default: C<87>

=head2 te_num

  $te_num = $tabla->te_num;

Default: C<62>

=head2 tete_num

  $tete_num = $tabla->tete_num;

Default: C<77>

=head2 ka_num

  $ka_num = $tabla->ka_num;

Default: C<68>

=head2 ga_num

  $ga_num = $tabla->ga_num;

Default: C<63>

=head2 ga_slide_num

  $ga_slide_num = $tabla->ga_slide_num;

Default: C<67>

=head1 METHODS

=head2 new

  $tabla = Music::Percussion::Tabla->new(%args);

Create a new C<Music::Percussion::Tabla> object. This uses all the
possible properties of L<MIDI::Drummer::Tiny>.

=for Pod::Coverage BUILD

=head2 tun

  $tabla->tun;
  $tabla->tun($tabla->sixteenth);

Daya bol: tun

=head2 ta

  $tabla->ta;
  $tabla->ta($tabla->sixteenth);

Daya bol: ta/na

=head2 tin

  $tabla->tin;
  $tabla->tin($tabla->sixteenth);

Daya bol: tin

=head2 tu

  $tabla->tu;
  $tabla->tu($tabla->sixteenth);

Daya bol: tu

=head2 te

  $tabla->te;
  $tabla->te($tabla->sixteenth);

Daya bol: te

=head2 tete

  $tabla->tete;
  $tabla->tete($tabla->sixteenth);

Daya bol: tete = C<te> + C<tete_num>

=head2 ka

  $tabla->ka;
  $tabla->ka($tabla->sixteenth);

Baya bol: ka/ki/ke/kath

=head2 ga

  $tabla->ga;
  $tabla->ga($tabla->sixteenth);

Baya bol: ga/gha/ge/ghe

=head2 ga_slide

  $tabla->ga_slide;
  $tabla->ga_slide($tabla->sixteenth);

Baya bol: ga/gha/ge/ghe with wrist slide to syahi

=head2 dha

  $tabla->dha;
  $tabla->dha($tabla->sixteenth);

Baya bol: dha = C<ga> + C<ta>

=head2 dhin

  $tabla->dhin;
  $tabla->dhin($tabla->sixteenth);

Baya bol: dhin = C<ga> + C<tin>

=head2 tirkit

  $tabla->tirkit;
  $tabla->tirkit($tabla->sixteenth);

Baya bol: tirkit = C<tete> + C<ka> + C<te>

=head1 SEE ALSO

L<File::Slurper>

L<MIDI::Util>

L<Moo>

L<File::ShareDir>

L<https://gleitz.github.io/midi-js-soundfonts/Tabla/Tabla.sf2>

L<https://www.wikihow.com/Play-Tabla>

L<https://www.taalgyan.com/theory/basic-bols-on-tabla/>

L<https://kksongs.org/tabla/chapter02.html> &
L<https://kksongs.org/tabla/chapter03.html>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Gene Boggs.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
