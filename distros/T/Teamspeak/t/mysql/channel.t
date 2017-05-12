#!/usr/bin/perl -w
# $Id: channel.t 33 2007-09-21 01:03:27Z maletin $
# $URL: http://svn.berlios.de/svnroot/repos/cpan-teamspeak/cpan/trunk/t/mysql/channel.t $

use strict;
use Teamspeak;
use Test::Simple tests => 2;

my $tsh = Teamspeak->new(
  type => 'sql',
  host => 'localhost',
  db   => 'teamspeak'
);
$tsh->connect( 'teamspeak', 'teamspeak' );
my $c = $tsh->get_channel;
ok( $c->[0]->parameter > 5, 'sql get_channel parameter' );
ok( $c->[0]->store, 'sql channel store' );
