use strict;
use warnings;

use Test::More ;

BEGIN {
    plan skip_all => 'This test needs NS_HOST, NS_USER & NS_PASS to be set in ENV'
        unless $ENV{NS_HOST} && $ENV{NS_USER} && $ENV{NS_PASS};

}   

use Term::ReadKey;
$^W = 1;

my $SESSION = Net::Telnet::Netscreen->new( Errmode   => 'return',	
        Host	   => $ENV{NS_HOST},
        Timeout   => 45,
        Input_log  => 'test.log',
        ) or die("Could not create session"));

ok($SESSION->login( $ENV{NS_USER}, $ENV{NS_PASS}), "Can't login to firewall with your login and pass.\n");
my @out = $SESSION->ping( 'www.perl.com' );
ok (!$SESSION->errmsg,'Can ping server from netscreen');
$SESSION->errmsg('');	# reset errmsg to noerr.
my @out = $SESSION->getValue( 'domain' );
ok (!$SESSION->errmsg,'getValue does not fail');
ok(@out,'getValue returns a value');
my $success = undef;
$SESSION->errmode( sub { $success = 1 } );
my @out = $SESSION->cmd( 'asdmnbvzvctoiubqwerhgadfhg' );
ok($sucess,'Commands can fail properly');
ok($SESSION->exit();,'Can exist session correctly');
