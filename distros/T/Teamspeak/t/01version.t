#!/usr/bin/perl -w
# $Id: 01version.t 3 2005-01-12 14:14:56Z maletin $
# $URL: http://svn.berlios.de/svnroot/repos/cpan-teamspeak/cpan/trunk/t/01version.t $

use strict;
use Teamspeak;
use Test::Simple tests => 1;

ok( $Teamspeak::VERSION > 0, 'version is positive' );
