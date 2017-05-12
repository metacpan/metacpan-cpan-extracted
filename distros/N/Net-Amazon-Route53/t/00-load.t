#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Net::Amazon::Route53');
use_ok('Net::Amazon::Route53::HostedZone');
use_ok('Net::Amazon::Route53::ResourceRecordSet');
use_ok('Net::Amazon::Route53::ResourceRecordSet::Change');
use_ok('Net::Amazon::Route53::Change');

done_testing;
