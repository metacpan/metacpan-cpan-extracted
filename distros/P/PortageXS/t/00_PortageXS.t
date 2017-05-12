#!/usr/bin/perl -w

use Test::Simple tests => 3;

use lib '../lib/';
use lib 'lib/';
use PortageXS;

my $pxs = PortageXS->new();
ok(defined $pxs,'check if PortageXS->new() works');
ok(-d $pxs->portdir,'portdir: '.$pxs->portdir);
ok(-d $pxs->{'PKG_DB_DIR'},'PKG_DB_DIR: '.$pxs->{'PKG_DB_DIR'});
