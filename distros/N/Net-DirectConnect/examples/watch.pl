#!/usr/bin/perl
#$Id: watch.pl 990 2012-12-28 20:35:04Z pro $ $URL: svn://svn.setun.net/dcppp/trunk/examples/watch.pl $

=readme

chat watch 

=cut
use strict;
eval { use Time::HiRes qw(time sleep); };
use lib::abs '../lib';
use Net::DirectConnect;    #::clihub;
print("usage: $0 [adc|dchub://]host[:port] [bot_nick]\n"), exit if !$ARGV[0];
#print "Arg=",$ARGV[0],"\n";
#$ARGV[0] =~ m|^(?:\w+\://)?(.+?)(?:\:(\d+))?$|;
my $dc = Net::DirectConnect->new(
  #'host' => $1,
  'host' => $ARGV[0],
  #( $2 ? ( 'port' => $2 ) : () ),
  'Nick' => ( $ARGV[1] or int( rand(100000000) ) ),
  #'Nick'		=>	'xxxx',
  'sharesize' => int( rand 100000000000 ) + int( rand 10000000000 ) * int( rand 100 ),
  #'log'		=>	sub {},	# no logging
  'client'      => '++',
  'V'           => '0.698',
  'description' => '',
  'M'           => 'P',
  'handler'     => {
    map {
      my $msg = $_;
      $msg => sub {
        my $dc = shift;
        #print join ' ', $msg, @_, "\n";
        $dc->say( $msg, @_ );    #print with console encoding
        },
    } qw(welcome chatline To)
  },
);
while ( $dc->active() ) { $dc->work(); }
$dc->destroy();
sleep(1);
