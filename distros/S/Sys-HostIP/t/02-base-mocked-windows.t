#!perl

use strict;
use warnings;
use lib '.';
use t::lib::Utils qw/base_tests mock_win32_hostip/;
use Test::More;

my @ipconfigs = qw(
  ipconfig-2k.txt
  ipconfig-win10.txt
  ipconfig-win2008-sv_SE.txt
  ipconfig-win7-de_DE.txt
  ipconfig-win7-empty-name.txt
  ipconfig-win7-fi_FI.txt
  ipconfig-win7-fr_FR.txt
  ipconfig-win7-it_IT.txt
  ipconfig-win7.txt
  ipconfig-xp.txt
);


my $num_base_tests = 11;
# this is the number of times the mocked _run_ipconfig() method is called
# per call to base_tests()
my $num_windows_mocking_checks = 4;
plan tests => ( $num_base_tests + $num_windows_mocking_checks ) * scalar @ipconfigs;

# run mocked windows base tests
for my $ipconfig ( @ipconfigs ) {
    note $ipconfig;

    # Mock Windows
    local $Sys::HostIP::IS_WIN = 1;

    my $hostip = mock_win32_hostip($ipconfig);
    base_tests($hostip);
}
