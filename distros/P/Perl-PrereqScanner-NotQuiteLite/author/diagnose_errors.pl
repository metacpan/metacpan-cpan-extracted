#!perl

use strict;
use warnings;
use author::Util;

for my $file (tmpdir('errors')->children) {
  say "processing $file";
  my $c = scan("$file");

  say dump($c->{stash});
  if (@{$c->{errors}}) {
    say "HAD ERROR\n".join "\n", @{$c->{errors}};
    say "$file";
    last;
  } else {
    $file->remove;
  }
}
