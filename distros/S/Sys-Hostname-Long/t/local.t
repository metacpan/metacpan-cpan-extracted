#!/usr/bin/perl -w
use strict;
use Test;

use lib '../lib';
use lib 'lib';

BEGIN { plan tests => 1 }

use Sys::Hostname::Long;

my $hostname = hostname_long(1,1);
ok($hostname ne "");

print "Your hostname = $hostname\n";
