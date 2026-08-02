#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;
use Test::More;
use Path::Tiny;

my $self = path($0)->basename('.t');
my $input = "t/input/$self.pl.pp";
my $output = "t/input/$self.pl";
my $expected = "t/expected/$self.pl";

unlink "$output";
is 0, system("$^X blib/script/pp $input"), "run pp.pl $input";
ok -f "$output", "$output created";
is 0, system("diff $expected $output"), "run diff $expected $output";
unlink "$output";

done_testing;
