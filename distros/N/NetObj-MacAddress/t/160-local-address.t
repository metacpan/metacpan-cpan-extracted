#!perl
use strict;
use warnings FATAL => 'all';

BEGIN { chdir 't' if -d 't'; }
use lib '../lib';

use Test::More; END { done_testing; }

use NetObj::MacAddress;

# the second least significant bit of the first byte of a MAC address
# indicates whether it is global (0) or local (1)

my @global_list = qw(
    000000000000
    00ffffffffff
    fdffffffffff
    fdffffffffff
);
for my $global (@global_list) {
    my $mac = NetObj::MacAddress->new($global);
    ok( ($mac->is_global()), "$mac is global" );
    ok( not ($mac->is_local()), "$mac is not local" );
}

my @local_list = qw(
    020000000000
    02ffffffffff
    ff0000000000
    ffffffffffff
);
for my $local (@local_list) {
    my $mac = NetObj::MacAddress->new($local);
    ok( not ($mac->is_global()), "$mac is not global" );
    ok( $mac->is_local(), "$mac is local" );
}
