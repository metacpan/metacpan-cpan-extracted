#!/usr/bin/env perl

# THIS IS A FUCKING CHEESY HACK. DON'T RUN IT ON ANYTHING YOU CARE ABOUT
# (and don't have in svn at least. Oh, and it breaks horribly on with)

use strict;
use warnings;

my $data;

foreach my $file (@ARGV) {
  open IN, $file;
  { local $/; $data = <IN>; }
  close IN;
  unless ($data =~ m/(.*?\n)(?:extends (.*?);)?\n+?(has.*)\n(1;\s*\n.*)/s) {
    warn "Failed to match for ${file}\n";
    next;
  }
  my ($front, $super_list, $body, $rest) = ($1, $2, $3, $4);
  my @supers = split(/\s*,\s*/, $super_list);
  my $pkg = (split(/\//, $file))[-1];
  $pkg =~ s/\.pm//;
  $body =~ s/^sub (\S+) {$/method $1 => sub {/mg;
  $body =~ s/^}$/};/mg;
  $body =~ s/^(\S+) '([^\+]\S+)' =>/$1 $2 =>/mg;
  $body =~ s/^/  /mg;
  my $is_list = join('', map { "is $_, " } @supers);
  open OUT, '>', $file;
  print OUT "${front}class ${pkg} ${is_list}which {\n${body}\n};\n\n${rest}";
  close OUT;
}

exit 0;
