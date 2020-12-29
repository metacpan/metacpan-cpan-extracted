use strict;
use warnings;

use Test::More;

use Sys::Linux::KernelVersion qw/is_linux_kernel get_kernel_version stringify_kernel_version is_development_kernel/;

ok(is_linux_kernel(), "Must be running on linux");

my $version = get_kernel_version();
my $str = stringify_kernel_version($version);
my $is_development = is_development_kernel();

print STDERR "\nThis is running on Linux kernel version: $str\n";
print STDERR "This kernel is a ",($is_development?"development":"release")," kernel\n";

done_testing;
