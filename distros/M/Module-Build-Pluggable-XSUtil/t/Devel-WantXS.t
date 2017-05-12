use strict;
use warnings;
use utf8;
use Test::More;
BEGIN { *describe = *it = *context = *Test::More::subtest }
use Devel::WantXS;

my @data = (
    # expected, PERL_ONLY, ARGUMENT, ARGV
    [ 1,        0,         0],
    [ 0,        0,         0,        '--pp'],
    [ 1,        0,         0,        '--xs'],
    [ 1,        0,         1],
    [ 0,        0,         1,        '--pp'],
    [ 1,        0,         1,        '--xs'],
    [ 0,        1,         0],
    [ 0,        1,         0,        '--pp'],
    [ 1,        1,         0,        '--xs'],
    [ 0,        1,         1],
    [ 0,        1,         1,        '--pp'],
    [ 1,        1,         1,        '--xs'],
);

for (@data) {
    my ($expected, $perl_only, $args, $argv) = @$_;
    local $Devel::WantXS::_CACHE;
    local $ENV{PERL_ONLY} = $perl_only;
    local @ARGV;
    push @ARGV, $argv if $argv;

    is(want_xs($args) || 0, $expected);
}

done_testing;

