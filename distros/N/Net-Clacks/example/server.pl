#!/usr/bin/env perl
#---AUTOPRAGMASTART---
use 5.020;
use strict;
use warnings;
use diagnostics;
use mro 'c3';
use English;
use Carp;
our $VERSION = 23;
use autodie qw( close );
use Array::Contains;
use utf8;
use Encode qw(is_utf8 encode_utf8 decode_utf8);
use feature 'signatures';
no warnings qw(experimental::signatures);
#---AUTOPRAGMAEND---

my $isDebugging = 0;
if(defined($ARGV[1]) && $ARGV[1] eq "--debug") {
    $isDebugging = 1;
}

use Net::Clacks::Server;

my $configfile = shift @ARGV;
croak("No Config file parameter") if(!defined($configfile) || $configfile eq '');

my $worker = Net::Clacks::Server->new($isDebugging, $configfile);
$worker->init;
$worker->run;
