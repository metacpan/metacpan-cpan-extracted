#!/usr/bin/env perl

package Term::Spinner::Color::AllFramesDemo;

use 5.010.001;
use lib "../lib";
use Term::Spinner::Color;
use Time::HiRes qw( sleep );
use utf8;

sub main {
  my $s = Term::Spinner::Color->new();
  my @colors = $s->available_colors();
  for my $frame (keys %{$s->available_frames()}) {
    print "\033[2J";    #clear the screen
    print "\033[0;0H"; #jump to 0,0
    print $color;
    my $loopspin = Term::Spinner::Color->new(
      'seq' => $frame,
      'color' => $colors[0],
    );
    my $cols = (30 - length($frame)) - $loopspin->frame_length();
    print "$frame" . " " x $cols;
    $loopspin->auto_start();
    sleep 5;
    $loopspin->auto_done();
    push @colors, shift @colors;
  }
}

exit main ( \@ARGV );
