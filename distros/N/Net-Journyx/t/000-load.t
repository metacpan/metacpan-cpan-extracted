#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 3;

use_ok 'Net::Journyx';

my $j = Net::Journyx->new(
    site => 'https://services.journyx.com/jxadmin23/jtcgi/jxapi.pyc',
    wsdl => 'file:../jxapi.wsdl',
);

ok($j, "got a defined return value from Net::Journyx");
ok($j->isa('Net::Journyx'), "got a Net::Journyx object");

