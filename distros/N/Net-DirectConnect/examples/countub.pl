#!/usr/bin/perl
#my $Id = '$Id: countub.pl 787 2011-05-25 21:41:28Z pro $';

=copyright
counting users-bytes from dchub for mrtg or cacti (snmpd)
=cut
use strict;
use lib::abs '../lib';
use Net::DirectConnect;
print("usage: $0 [adc|dchub://]host[:port] [bot_nick] [share_delim]\n"), exit if !$ARGV[0];
$ARGV[0] =~ m|^(?:\w+\://)?(.+?)(?:\:(\d+))?$|;
my $dc = Net::DirectConnect->new(
  'host'       => $ARGV[0],
  'Nick'       => ( $ARGV[1] or 'dcpppCnt' ),    #'log' => sub { },    # no logging
  auto_GetINFO => 1,
);
my ($share) = 0;
$dc->wait_connect();                             #for 1 .. 3;
#$dc->cmd('GetINFO') if $dc->{nmdc};
$dc->work(5);
if   ( $dc->{nmdc} ) { $share += $dc->{'NickList'}{$_}{'sharesize'} for keys %{ $dc->{'NickList'} }; }
else                 { $share += $dc->{'peers'}{$_}{INF}{'SS'}      for keys %{ $dc->{'peers'} }; }
$share /= $ARGV[2] if $ARGV[2];
print( ( scalar keys %{ $dc->{'NickList'} } or scalar keys %{ $dc->{'peers'} } or 0 ), "\n$share\n$ARGV[0]\nz\n" );
