use strict;
use warnings;

use File::Temp qw(tempdir);

use Test::More;
use Test::Warn;

plan tests => 2;

use_ok('Parallel::Scoreboard');

# create temporary directory
my $base_dir = tempdir(CLEANUP => 1);

# instantiate
my $sb = Parallel::Scoreboard->new(
    base_dir => $base_dir,
);

$sb->update('X');

# simulate global destruction by deleting this attribute before DESTROY is
# called
delete $sb->{base_dir};

warning_is(sub { undef $sb }, undef,
    'no warnings when object is destroyed and base_dir is undef');
