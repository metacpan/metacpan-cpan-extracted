use strict;
use Test::More;
use Cwd qw(abs_path);
use Pod::Perldoc::Cache;

my $got = Pod::Perldoc::Cache::_calc_pod_md5(abs_path($0));
like $got, qr/\S{32}/;

done_testing;
