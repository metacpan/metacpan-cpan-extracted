#!/usr/bin/env perl
BEGIN {
  use Cwd qw(abs_path);
  use File::Basename;
  my $path = dirname abs_path __FILE__;
  unshift @INC, "$path/lib";
}
use Term::Tmux::StatusBar qw(main);

main;
