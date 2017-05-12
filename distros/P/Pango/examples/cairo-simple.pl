#!/usr/bin/perl

# This is adopted from the cairosimple.c example in the pango distribution
# written by Behdad Esfahbod.

use strict;
use warnings;

use Math::Trig qw(pi);
use Cairo;
use Glib qw(TRUE FALSE);
use Gtk2 -init;
use Gtk2::Pango;

use constant RADIUS => 150;
use constant N_WORDS => 10;
use constant FONT => "Sans Bold 27";

sub draw_text {
  my ($cr) = @_;

  $cr -> translate(RADIUS, RADIUS);

  my $layout = Pango::Cairo::create_layout($cr);
  $layout -> set_text("Text");

  my $desc = Pango::FontDescription -> from_string(FONT);
  $layout -> set_font_description($desc);

  # Draw the layout N_WORDS times in a circle
  foreach (0 .. N_WORDS) {
    my $angle = (360. * $_) / N_WORDS;

    $cr -> save();

    # Gradient from red at angle == 60 to blue at angle == 300
    my $red = (1 + cos(($angle - 60) * pi / 180.)) / 2;
    $cr -> set_source_rgb($red, 0, 1.0 - $red);

    $cr -> rotate($angle * pi / 180.);

    # Inform Pango to re-layout the text with the new transformation
    Pango::Cairo::update_layout($cr, $layout);

    my ($width, $height) = $layout -> get_size();
    $cr -> move_to(- ($width / PANGO_SCALE) / 2, - RADIUS);
    Pango::Cairo::show_layout($cr, $layout);

    $cr -> restore();
  }
}

my $window = Gtk2::Window -> new();
$window -> signal_connect(delete_event => sub { Gtk2 -> main_quit(); });

my $area = Gtk2::DrawingArea -> new();
$area -> signal_connect(expose_event => sub {
  my ($widget, $event) = @_;

  my $cr = Gtk2::Gdk::Cairo::Context -> create($widget -> window());
  $cr -> set_source_rgb(1.0, 1.0, 1.0);
  $cr -> rectangle(0, 0, 2 * RADIUS, 2 * RADIUS);
  $cr -> fill();

  draw_text($cr);

  return FALSE;
});

$window -> set_default_size(2 * RADIUS, 2 * RADIUS);
$window -> add($area);
$window -> show_all();

Gtk2 -> main();
