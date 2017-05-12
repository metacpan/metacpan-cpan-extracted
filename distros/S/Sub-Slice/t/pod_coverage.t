#!/usr/local/bin/perl

use Test::More;
eval "use Test::Pod::Coverage 1.00";
if ( $@ ) {
    plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD Coverage";
}
else {
    plan tests => 1;
    # This test script doesn't work if you're in the t/ directory - you need to be above it
    unless (-e 't') { require File::Spec; chdir( File::Spec->updir() ); }
}
for my $module ( Test::Pod::Coverage::all_modules() ) {
    next if ( $module =~ m/::Backend::Filesystem/ );
    pod_coverage_ok($module, { also_private => [ qr/^[A-Z_]+$/ ] }); #Ignore all caps
}

