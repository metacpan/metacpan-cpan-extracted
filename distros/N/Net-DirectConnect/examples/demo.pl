#!/usr/bin/perl -w
#$Id: demo.pl 754 2011-03-07 01:07:15Z pro $ $URL: svn://svn.setun.net/dcppp/trunk/examples/demo.pl $
use strict;
no warnings qw(uninitialized);
use Data::Dumper;    #dev only
$Data::Dumper::Sortkeys = 1;
use lib::abs '../lib';
use Net::DirectConnect;
my $dc = Net::DirectConnect->new(
  'host'         => $ARGV[0],
  'M'            => 'P',               #passive mode
  'sharesize'    => 10_000_000_000,    # 10G
  'auto_connect' => 0,                 # dont connect in ->new
  'auto_say'     => 1,                 # auto print welcome, chat, pvt
);
print 'available commands:',      ( join ', ', sort keys %{ $dc->{'cmd'} } ),   "\n";
print 'some available handlers:', ( join ', ', sort keys %{ $dc->{'parse'} } ), "\n";
$dc->{'handler'}{'MyINFO'} = sub {
  ($_) = $_[1] =~ /\S+\s+(\S+)\s+(.*)/;
  print "my cool info parser gets info about $1 [$2]\n";
};
$dc->{'handler'}{'chatline'} = sub {
  my $dc = shift;
  my ( $nick, $text ) = $_[0] =~ /^<([^>]+)> (.+)$/;
  print "My chatline handler [$nick,$text]\n";
  if ( $text =~ /^\s*!moo/i ) {        # if you type  !moo  in main chat
    $dc->cmd( 'chatline', 'meow!' );    # via cmd,     can be written as $dc->chatline( ...
    $dc->To( $nick, 'woof!' );          # private msg, can be written as $dc->cmd('To', $nick, ...
  }
};
#$dc->connect( $ARGV[0] );               # connect can parse dchub://hub:port/
$dc->wait_connect();
$dc->work(10);                          # seconds
$dc->chatline('hello world');
{                                       # fine tuned getinfo with send buffer
  local $dc->{'sendbuf'} = 1;           #enable buffer
  $dc->sendcmd( 'GetINFO', $_, $dc->{'Nick'} )
    for grep { $dc->{'NickList'}{$_}{'online'} and !$dc->{'NickList'}{$_}{'info'} } keys %{ $dc->{'NickList'} };
  $dc->sendcmd();                       #flush buffer (actual send)
}
$dc->sendcmd('GetINFO');
$dc->search('3P7MBNO5COD4TLTVXLJB53ZJBVIL2QRHIGZ2N5A');
$dc->search('xxx');
#get all filelists
$dc->get( $_, 'files.xml.bz2', $_ . '.xml.bz2' ), $dc->work() for grep $_ ne $dc->{'Nick'}, keys %{ $dc->{'NickList'} };
#$dc->get('user', 'TTH/I2VAVWYGSVTBHSKN3BOA6EWTXSP4GAKJMRK2DJQ', 'file.zip'); # get file by tth from user
$dc->work(10);
$dc->wait_finish();                     # wait unfinished transfers
#$dc->work() while  $dc->active() ; # stay
$dc->disconnect();
#print Dumper $dc; #you can redefine any key
