#!/usr/bin/perl -w
# $Id: connect.t 33 2007-09-21 01:03:27Z maletin $
# $URL: http://svn.berlios.de/svnroot/repos/cpan-teamspeak/cpan/trunk/t/web/connect.t $

use strict;
use Teamspeak;
use Test::Simple tests => 1;

my $tsh = Teamspeak->new( type => 'web' );
ok( $tsh->connect( slogin => 'sa', pwd => 'sa' ), 'connect' );
