#!perl
use strict;
use warnings;
use 5.10.1;

BEGIN { chdir 't' if -d 't'; }
use lib '../lib';

use Test::More; END { done_testing; }

use NetObj::MacAddress;

my $mac = NetObj::MacAddress->new('012345'); # 6 bytes raw MAC address

is(
    $mac->to_string(),
    '303132333435',
    'conversion to string',
);

is("$mac", '303132333435', 'implicit stringification');
