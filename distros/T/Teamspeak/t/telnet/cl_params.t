#!/usr/bin/perl -w
# $Id: 03sl.t 7 2005-01-19 15:54:19Z maletin $
# $URL: svn+ssh://svn.berlios.de/svnroot/repos/cpan-teamspeak/cpan/trunk/t/03sl.t $

use strict;
use Teamspeak;
use Test::Simple tests => 4;

my $tsh = Teamspeak->new( type => 'telnet' );
$tsh->connect();
ok( $tsh->sl == 2,        'two servers' );
ok( $tsh->sel(8767) == 1, 'select server' );
ok( $tsh->cl,             'channel list' );
my $can_method = 1;
my @cmd        = Teamspeak::Channel->parameter;
foreach my $ch_id ( sort $tsh->channels ) {
  my $ch = $tsh->{channel}{$ch_id};
  foreach my $cmd (@cmd) {
    $can_method = 0 if ( !$ch->can($cmd) );
  }
}
ok( $tsh->cl, 'channel methods' );
