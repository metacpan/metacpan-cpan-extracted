#!/usr/local/bin/perl

use strict;
use warnings;

use lib '../lib';

use Net::Twitter::Cabal;

my $c = Net::Twitter::Cabal->new( { config => 'samplecfg.yml' } );

$c->run;
