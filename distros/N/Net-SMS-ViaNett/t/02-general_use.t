use strict;
use Net::SMS::ViaNett;
use Test::More tests => 2;

my ( $user, $pass ) = qw/boo boo/;
my $obj = Net::SMS::ViaNett->new( username => $user, password => $pass );

can_ok( $obj, qw/
  agent
  send
  _to_url
  _call
  _validate
/ );


my $agent = 'dummy';
$obj->agent( $agent );
is( $obj->agent, $agent, 'user-agent-check' );

