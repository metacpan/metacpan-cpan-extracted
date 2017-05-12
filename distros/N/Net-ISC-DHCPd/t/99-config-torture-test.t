#!perl

use strict;
use warnings;
use lib './lib';
use Test::More;
use Benchmark;
use File::Temp;


plan skip_all => 'set environment variable DHCP_TORTURE_TEST to run this test' unless ($ENV{'DHCP_TORTURE_TEST'});

my $count  = $ENV{'COUNT'} || 1;
plan tests => 2 + 3 * $count;

use_ok("Net::ISC::DHCPd::Config");

my $fh = File::Temp->new();
my $data = do {local $/;<DATA>};

my $data_repeat = $ENV{'DHCP_TORTURE_TEST'} > 1 ? $ENV{'DHCP_TORTURE_TEST'} : 20000;
my $file_size = length($data) * $data_repeat;
my $subnet_count = $data_repeat;

for(1..$data_repeat) {
    print $fh $data;
}

seek $fh, 0, 0;
is(($fh->stat)[7], $file_size, 'Is file size correct?');

my $time = timeit($count, sub {

    seek $fh, 0, 0;
    my $config = Net::ISC::DHCPd::Config->new(fh => $fh);
    $config->parse();

    is(scalar(@_=$config->subnets), $subnet_count, 'Are there xxx distinct subnets?');
    is(scalar(@_=$config->groups), $subnet_count, 'Are there xxx distinct groups?');
    is(scalar(@_=$config->includes), $subnet_count, 'Are there xxx distinct includes?');
});

__DATA__

# this file doesn't have to exist.  Just testing the parser
include "test.conf";

subnet 127.0.0.0 netmask 255.255.255.0 {
    pool
    {
        range 127.0.0.1;
    }
}

group "Cats" {

    option root-path "EST";
    dynamic-bootp-lease-length 3600;
    min-lease-time 1800;
    default-lease-time 43200;

    subnet 127.0.0.0 netmask 255.255.255.0 {
        pool
        {
            range 127.0.0.1;
        }
    }

    shared-network "Kittens" {

        subnet 127.1.0.0 netmask 255.255.255.0 {
            pool
            {
                range 127.1.0.1 127.1.0.2;
            }
        }

        subnet 127.2.0.0 netmask 255.255.255.0 {
            pool
            {
                range 127.2.0.1 127.2.0.2;
            }
        }

        host hostything
        {
            hardware ethernet 00:ff:ff:ff:ff:ff;
            fixed-address 127.0.0.1;
        }

    }

}

