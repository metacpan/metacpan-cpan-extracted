#!perl

use warnings;
use strict;

use Test::More;

use Prometheus::Tiny::Shared;
use File::Temp qw(tmpnam);
use File::stat;

my $filename = scalar tmpnam();

ok !-e $filename, "data file doesn't exist";

my $p = Prometheus::Tiny::Shared->new(filename => $filename);

ok -e $filename, "data file exists when object created";

my $inode = stat($filename)->ino;

my $p2 = Prometheus::Tiny::Shared->new(filename => $filename);

is $inode, stat($filename)->ino, 'data file is same file after second object';

my $p3 = Prometheus::Tiny::Shared->new(filename => $filename, init_file => 1);

isnt $inode, stat($filename)->ino, 'data file overwritten when requested';

done_testing;
