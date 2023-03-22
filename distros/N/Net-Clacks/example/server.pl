#!/usr/bin/env perl
#---AUTOPRAGMASTART---
use v5.36;
use strict;
use diagnostics;
use mro 'c3';
use English qw(-no_match_vars);
use Carp qw[carp croak confess cluck longmess shortmess];
our $VERSION = 27;
use autodie qw( close );
use Array::Contains;
use utf8;
use Encode qw(is_utf8 encode_utf8 decode_utf8);
use Data::Dumper;
use builtin qw[true false is_bool];
no warnings qw(experimental::builtin); ## no critic (TestingAndDebugging::ProhibitNoWarnings)
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
