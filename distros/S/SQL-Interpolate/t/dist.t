# test various aspects of the distribution

use strict;
use Test::More 'no_plan';

# list of all modules
my @modules = (
    'SQL::Interpolate',
    'SQL::Interpolate::Macro',
    'SQL::Interpolate::Filter',
    'DBIx::Interpolate'
);

my %version_exist;
for my $module (@modules) {
    eval "require $module";
    my $version = $module->VERSION;
    $version_exist{$version} = 1;
}
ok(keys %version_exist == 1, 'module versions match');

