#!/usr/bin/perl
#my $Id = '$Id: ddltest.pl 990 2012-12-28 20:35:04Z pro $';

=copyright
test direct downloading (without hub)
=cut
use strict;
#use Time::HiRes;
eval { use Time::HiRes qw(time sleep); };
use lib '../lib';
use Net::DirectConnect;
print("usage: $0 [dchub://]hub[:port]/nick[/path]/file [bot_nick] [fileas]\n"), exit if !$ARGV[0];
#$ARGV[0] =~ m|^([^:]+):((?:\w+\.?)+)(?:\:(\d+))(/.+)$|;
$ARGV[0] =~ m|^(?:\w+\://)?(.+?)(?:\:(\d+))?/(.+?)/(.+)$|;
#print"[$ARGV[0]] 1=$1 2=$2 3=$3 4=$4 ; \n";
my ( $user_nick, $file ) = ( $3, $4 );
my $dc = Net::DirectConnect->new(
  #'host' => $1,
  #( $2 ? ( 'port' => $2 ) : () ),
  'host' => $ARGV[0], 'Nick' => ( $ARGV[1] or 'dcpppDl' . int( rand(100) ) ), 'log' => sub { },    # no logging
);
$dc->get( $user_nick, $file, $ARGV[2] || $file );                                                  #.get
#$dc->recv(); sleep(5); $dc->recv();
