#!/usr/local/bin/perl

use Test::More;
use File::Spec;
use lib './lib';

eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD Coverage" if($@);

# dir may be zero length on win32 (indicating current directory)
my $dir = File::Spec->catdir
    ( (File::Spec->splitpath($0))[1], File::Spec->updir());
if(defined $dir && length $dir) {
    chdir($dir) or die "Couldn't change to project dir ($dir)";
}

#AppsIflRunner is a wrapper around ModperlRunner and CGIRunner, so its interface is documented in those modules
@modules = grep {$_ !~ /^AppsIflRunner$/} Test::Pod::Coverage::all_modules() or plan skip_all => "No modules to test";

plan tests => scalar @modules;
for my $module (@modules) {
    my @private = (qr/^[A-Z_]+$/);
    @private = (qr/^tests$/, qr/^ASSERT_/, qr/^TRACE|HAVE_ALARM$/) if($module eq 'Test::Assertions');
    @private = (qr/^deep_import$/) if($module eq 'Log::Trace');
    pod_coverage_ok($module, { also_private => \@private }); #Ignore all caps
}
