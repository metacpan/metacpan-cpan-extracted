#!perl

use strict;
use warnings;
use author::Util;

$_->remove for tmpdir('errors')->children;
$_->remove for tmpdir('slow')->children;

my $target = shift || "$ENV{HOME}/minicpan_extracted";

my $ct = 0;
my $root = path($target);
my $iter = $root->iterator({recurse => 1, follow_symlinks => 0});
my $err = 0;
while(my $file = $iter->()) {
  next unless $file =~ /\.pm$/;
  if ($file =~ /\._\w+\.pm$/) {
    $file->remove;
    next;
  }
  log(info => "scanning $file");
  my $start = time;
  my $c;
  eval {
    local $SIG{ALRM} = sub {die "alarm\n"};
    # alarm 2;
    $c = scan("$file");
    alarm 0;
  };
  log(error => "$@: $file") if $@;
  my $end = time - $start;
  if ($end > 1) {
    log(warn => "[SLOW]: $end $file");
    $file->spew(scalar $file->slurp ."\n# $file\n");
    if (-s $file > 100000) {
      $file->copy(tmpdir("slow"));
    } else {
      $file->copy(tmpdir("errors"));
    }
    # $err++
  } elsif (@{$c->{errors}}) {
    log(warn => "had errors: $file ".dump($c->{stash}));
    $file->spew(scalar $file->slurp ."\n# $file\n");
    $file->copy(tmpdir("errors"));
    $err++;
  }
  #exit if $err > 100;
}
