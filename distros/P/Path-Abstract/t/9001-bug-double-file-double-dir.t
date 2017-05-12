#!perl -T

use strict;
use warnings;

use Test::More;
use Path::Abstract qw/path/;

plan skip_all => "Path::Class needed to run this test" and exit unless eval "require Path::Class;"; 

Path::Class->import;

plan qw/no_plan/;

my $path = path qw/1 2 3/;
is($path->file, file(qw/1 2 3/));
is($path->dir, dir(qw/1 2 3 /));
