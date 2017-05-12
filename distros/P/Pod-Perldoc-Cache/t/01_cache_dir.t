use strict;
use Test::More;
use Pod::Perldoc::Cache;
use File::Temp qw(tempdir);

my $tmpdir = tempdir(CLEANUP => 1);
my $got = Pod::Perldoc::Cache::_cache_dir($tmpdir);
is $got, $tmpdir;

done_testing;
