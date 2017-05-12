#!perl

use strict;
use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan(skip_all => <<"MESSAGE"), exit if $@;
Test::Pod::Coverage 1.04 required for testing POD coverage
MESSAGE

# all_pod_coverage_ok() is buggy in 1.06 when there are modules
# in arch/. Let's reimplement it here:

my $Test = Test::Builder->new;
my @modules = Test::Pod::Coverage::all_modules();
map {s/^arch::// } @modules; # Bug waz zere
if ( @modules ) {
    $Test->plan( tests => scalar @modules );

    for my $module ( @modules ) {
        pod_coverage_ok( $module, "Pod coverage on $module");
    }
} else {
    $Test->plan( tests => 1 );
    $Test->ok( 1, "No modules found." );
}
