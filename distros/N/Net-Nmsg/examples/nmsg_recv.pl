#!/usr/bin/perl

use strict;
use warnings;

use Net::Nmsg::Input;
use Net::Nmsg::Output;

my $n = Net::Nmsg::Input->open('127.0.0.1/9430');
my $o = Net::Nmsg::Output->open_pres(\*STDOUT);

$o->write while <$n>;
