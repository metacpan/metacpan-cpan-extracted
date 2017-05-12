#!/usr/bin/perl

use warnings;
use strict;

use PortageXS;
use Path::Tiny qw(path);

my $pxs=PortageXS->new();
print "CFLAGS are set to: ";

my $content = '';
$content .=  path($pxs->{MAKE_GLOBALS_PATH})->slurp;
$content .=  path($pxs->{MAKE_CONF_PATH})->slurp;
print join(' ',$pxs->getParamFromFile($content,'CFLAGS','lastseen'))."\n";
