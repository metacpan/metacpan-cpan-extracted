use strict;
use warnings;

use Test::More;

use Sys::Linux::KernelVersion qw/is_linux_kernel get_kernel_version stringify_kernel_version is_development_kernel is_at_least_kernel_version/;

ok(is_linux_kernel(), "Must be running on linux");

my $version = get_kernel_version();
my $str = stringify_kernel_version($version);
my $is_development = is_development_kernel();
my $test_kernel = is_at_least_kernel_version("1.0.0");

ok($test_kernel, "We're on at least kernel 1.0.0");

print STDERR "\nThis is running on Linux kernel version: $str\n";
print STDERR "This kernel is a ",($is_development?"development":"release")," kernel\n";

done_testing;
