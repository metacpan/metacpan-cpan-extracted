# test various aspects of the distribution

use strict;
use Test::More 'no_plan';

# list of all modules
my @modules = (
    'SQL::Interp',
    'DBIx::Interp'
);

my %version_exist;
for my $module (@modules) {
    eval "require $module" || die $@;
    my $version = $module->VERSION;
    $version_exist{$version} = 1;
}
ok(keys %version_exist == 1, 'module versions match');

