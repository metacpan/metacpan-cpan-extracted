#!/usr/bin/perl

use warnings;
use strict;

use Test::More no_plan =>;

use Shebangml::State;

my $input = "foo\nbar\nbaz\n";
open(my $fh, '<', \$input) or die $!;
my $state = Shebangml::State->new($fh);

my @getting;
while(my $CL = $state->next) {
  $$CL =~ s/^(.*$)//;
  my $content = $1;
  push(@getting, [$content, ${$state->current}]);
}
is_deeply(\@getting, [[foo => "\n"], [bar => "\n"], [baz => "\n"]]);

# vim:ts=2:sw=2:et:sta
