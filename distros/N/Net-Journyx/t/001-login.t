#!/usr/bin/env perl

use strict;
use warnings;
use lib 't/lib';
use Test::More tests => 1;

use Net::Journyx;

my $jx = Net::Journyx->new(
    site => 'https://services.journyx.com/jxadmin23/jtcgi/jxapi.pyc',
    wsdl => 'file:../jxapi.wsdl',
    username => $ENV{'JOURNYX_USER'},
    password => $ENV{'JOURNYX_PASSWORD'},
);

ok $jx->session, "logged in";


