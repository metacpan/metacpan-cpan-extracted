#!/usr/bin/perl -w
# $Id: connect.t 33 2007-09-21 01:03:27Z maletin $
# $URL: http://svn.berlios.de/svnroot/repos/cpan-teamspeak/cpan/trunk/t/telnet/connect.t $

use strict;
use Teamspeak;
use Test::Simple tests => 1;

my $tsh = Teamspeak->new( type => 'telnet' );
ok( $tsh->connect(), 'connect' );
