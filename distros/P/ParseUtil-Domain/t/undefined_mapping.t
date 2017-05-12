#!/usr/bin/perl

use lib qw{ ./t/lib blib/lib };

$ENV{TEST_METHOD} = '.*undefined_mappings';

use ParseDomain;
ParseDomain->runtests();

