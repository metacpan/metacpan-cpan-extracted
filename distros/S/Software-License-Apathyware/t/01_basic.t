#!/usr/local/bin/perl -w
use strict;use warnings;

use lib '../lib';
use lib 'lib';
use Test::More tests => 1;
#use Test::Exception;
use Data::Dumper;

my $expected = <<EOT;
This software is copyright (c) 2013 by Ariba, Inc. (An SAP Company).

This code is released as Apathyware:

"The code doesn't care what you do with it, and neither do I."

EOT

#use lib '/Users/mkandel/src/POC/dzil/Software-License-Apathyware/lib/';
use Software::License::Apathyware;

my $lic = Software::License::Apathyware->new({
    holder => 'Ariba, Inc. (An SAP Company)',
    year   => '2013',
});

my $out = $lic->fulltext;
print Dumper $out;

is ( $out, $expected, 'Basic usage' );
