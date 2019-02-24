#!perl

use strict;
use warnings;
use t::lib::Utils qw/mock_linux_hostip base_tests/;

use Test::More;
use Sys::HostIP;

if ($^O =~ qr/(linux)/x) {
    plan tests =>  11;
    my $hostip = mock_linux_hostip('ip-linux.txt');
    base_tests($hostip);
}
else {
    plan skip_all => 'these tests are only for Linux';
}
