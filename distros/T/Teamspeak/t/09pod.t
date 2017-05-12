#!/usr/bin/perl -w
# $Id: 09pod.t 37 2008-03-09 01:10:00Z maletin $
# $URL: http://svn.berlios.de/svnroot/repos/cpan-teamspeak/cpan/trunk/t/09pod.t $

use strict;
use Teamspeak;
use Test::More;

#eval 'use Test::Pod 1.00';
#plan( skip_all => 'Test::Pod 1.00 required for testing POD' ) if $@;
#all_pod_files_ok();

eval 'use Test::Pod::Coverage 1.04';
plan( skip_all => 'Test::Pod::Coverage 1.04 required for testing POD coverage') if $@;
all_pod_coverage_ok( );
