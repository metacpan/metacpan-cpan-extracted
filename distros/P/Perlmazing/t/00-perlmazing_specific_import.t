use lib 'lib';
use lib '../lib';
use 5.006;
use strict;
use warnings;
use Test::More tests => 1;
use Perlmazing qw(pl);

my $exists = exists $main::{pl};
my $not_exists = exists $main::{copy};
my $result = $exists && !$not_exists;

is $result, 1, 'Importing only one symbol';

