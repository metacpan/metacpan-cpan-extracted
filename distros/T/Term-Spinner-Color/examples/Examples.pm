#!/usr/bin/env perl

package Term::Spinner::Color::Examples;

use 5.010.001;
use lib "../lib";
use Term::Spinner::Color;
use Time::HiRes qw( sleep );
use utf8;

sub main {
  my $s0 = Term::Spinner::Color->new(
    'colorcycle' => 1,
    'seq' => 'uni_circle'
  );
  $s0->run_ok("sleep 5", "doot circle");

  my $s1 = Term::Spinner::Color->new(
    'color' => 'yellow',
    'seq' => [ qw(dooot odoot oodot ooodt ooood ooodt oodot odoot) ],
    );
  $s1->run_ok( [
    "sleep 0.2",
    "sleep 0.2",
    "sleep 0.2",
    "sleep 0.2",
    "sleep 0.2",
    "false"],"doot doot oh no!");

  my $s2 = Term::Spinner::Color->new(
    'colorcycle' => 1,
    'seq' => 'uni_dots'
  );
  $s2->run_ok("sleep 5", "single doot");

  my $s3 = Term::Spinner::Color->new();
  $s3->run_ok("sleep 5", "default doot");

  my $s4 = Term::Spinner::Color->new(
    'color' => 'magenta',
    'seq' => 'uni_trigram_bounce'
  );
  $s4->run_ok("sleep 5", "trigram_bounce");

  my $s5 = Term::Spinner::Color->new(
    'color' => 'green',
    'seq' => 'uni_dots7'
  );
  $s5->run_ok("sleep 5", "uni_dots7");
}

exit main( \@ARGV );
