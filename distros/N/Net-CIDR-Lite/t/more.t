# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
use strict;
$|++;
BEGIN { plan tests => 2 };
use Net::CIDR::Lite;
ok(1); # If we made it this far, we are ok.

#########################


# Testing RT Tickets that caused fatal errors
# TODO: Could probably also test for results

my $cidr = Net::CIDR::Lite->new();
$cidr->add_range(":: - 2001:1ff:ffff:ffff:ffff:ffff:ffff:ffff");

my $ipobj1 = Net::CIDR::Lite->new;

$ipobj1->clean;
$ipobj1->add('1.2.3.4/32');

my $ipobj2 = Net::CIDR::Lite->new;

$ipobj2->list;
$ipobj2->add('1.2.3.4/32');

ok(1);
