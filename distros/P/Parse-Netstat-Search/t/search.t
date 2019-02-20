use strict;

use Test::More;
use Data::Dumper;

BEGIN {
   use_ok('Parse::Netstat::Search');
}

my $res=[ '0', '1',
		  {
		   'active_conns'=>[
							{
							 'foreign_host'=>'10.0.0.1',
							 'local_host'=>'10.0.0.2',
							 'foreign_port'=>'22222',
							 'local_port'=>'22',
							 'sendq'=>'0',
							 'recvq'=>'0',
							 'state' => 'ESTABLISHED',
							 'proto' => 'tcp4',
							 },
							{
							 'foreign_host'=>'10.0.0.1',
							 'local_host'=>'10.0.0.2',
							 'foreign_port'=>'22',
							 'local_port'=>'2222',
							 'sendq'=>'0',
							 'recvq'=>'0',
							 'state' => 'TIME_WAIT',
							 'proto' => 'tcp4',
							 },
							{
							 'foreign_host'=>'10.0.0.1',
							 'local_host'=>'192.168.0.1',
							 'foreign_port'=>'22',
							 'local_port'=>'2222',
							 'sendq'=>'0',
							 'recvq'=>'0',
							 'state' => 'ESTABLISHED',
							 'proto' => 'tcp4',
							 },
							{
							 'foreign_host'=>'10.0.0.1',
							 'local_host'=>'10.0.0.2',
							 'foreign_port'=>'22',
							 'local_port'=>'2222',
							 'sendq'=>'0',
							 'recvq'=>'0',
							 'state' => 'ESTABLISHED',
							 'proto' => 'tcp4',
							 },
							{
							 'foreign_host' => '*',
							 'recvq' => '0',
							 'local_port' => '389',
							 'local_host' => '127.0.0.1',
							 'foreign_port' => '*',
							 'state' => 'LISTEN',
							 'proto' => 'udp4',
							 'sendq' => '0'
							 },
							{
							 'foreign_host' => '*',
							 'recvq' => '0',
							 'local_port' => '22',
							 'local_host' => '*',
							 'foreign_port' => '*',
							 'state' => 'LISTEN',
							 'proto' => 'tcp4',
							 'sendq' => '0'
							},
							{
							 'inode' => '0',
							 'address' => 'fffff8004ca0ca00',
							 'addr' => '/var/run/dovecot/stats-writer',
							 'conn' => 'fffff8004c9ae500',
							 'proto' => 'unix',
							 'sendq' => '0',
							 'type' => 'stream',
							 'recvq' => '0',
							 'refs' => '0',
							 'nextref' => '0'
							 },
							],
		   }
		 ];

# does a quick test to make sure we have the basics required for the following tests to work
my $res_good=1;
if (
	( ref( $res ) ne 'ARRAY' ) ||
	( ! defined( $res->[2] )  ) ||
	( ! defined( $res->[2]->{active_conns} ) )
	){
	$res_good=0;
}
ok( $res_good eq '1', 'res test') or diag("Test data is bad");

my $search=Parse::Netstat::Search->new;

#return all non-unix connections
my @found=$search->search($res);
ok( $#found eq '5', 'search, all') or diag('"'.$#found.'" number of returned connections for a empty search instead of "5"');

# set a state and make sure returns only those
$search->set_states( ['LISTEN'] );
@found=$search->search($res);
ok( $#found eq '1', 'search, LISTEN state') or diag('"'.$#found.'" number of returned connections for LISTEN state search instead of "2"');
$search->set_states;
@found=$search->search($res);
ok( $#found eq '5', 'search, state reset') or diag('"'.$#found.'" number of returned connections for a empty search instead of "5"... failed to reset the states');

# makes sure searching based on CIDR works
# set a state and make sure returns only those
$search->set_cidrs( ['10.0.0.0/24'] );
@found=$search->search($res);
ok( $#found eq '3', 'search, CIDR 1') or diag('"'.$#found.'" number of returned connections for CIDR 10.0.0.0/24 search instead of "3"');
$search->set_cidrs( ['127.0.0.1/32'] );
@found=$search->search($res);
ok( $#found eq '0', 'search, CIDR 2') or diag('"'.$#found.'" number of returned connections for CIDR 127.0.0.1/32 search instead of "0"');
$search->set_cidrs( ['10.0.0.0/24','127.0.0.1/32'] );
@found=$search->search($res);
ok( $#found eq '4', 'search, CIDR 3') or diag('"'.$#found.'" number of returned connections for CIDR 127.0.0.1/32 10.0.0.0/24 search instead of "4"');
$search->set_cidrs;
@found=$search->search($res);
ok( $#found eq '5', 'search, CIDR reset') or diag('"'.$#found.'" number of returned connections for a empty search instead of "5"... failed to reset the CIDRs');

#make sure we can match multiple items
$search->set_cidrs( ['127.0.0.0/24'] );
$search->set_states( ['LISTEN'] );
@found=$search->search($res);
ok( $#found eq '0', 'search, CIDR+state') or diag('"'.$#found.'" number of returned connections for CIDR 127.0.0.0/24 + LISTEN state search instead of "0"');
$search->set_cidrs;
$search->set_states;
@found=$search->search($res);
ok( $#found eq '5', 'search, CIDR+state reset') or diag('"'.$#found.'" number of returned connections for a empty search instead of "5"... failed to reset the CIDRs and states');

#make sure we cans search based on protocols
$search->set_protocols(['udp4']);
@found=$search->search($res);
ok( $#found eq '0', 'search, Protocol 1') or diag('"'.$#found.'" number of returned connections for udp4 protocol instead of "0"');
$search->set_protocols(['tcp4']);
@found=$search->search($res);
ok( $#found eq '4', 'search, Protocol 2') or diag('"'.$#found.'" number of returned connections for tcp4 protocol instead of "4"');
$search->set_states( ['LISTEN'] );
@found=$search->search($res);
ok( $#found eq '0', 'search, Protocol+Listen') or diag('"'.$#found.'" number of returned connections for tcp4 protocol + LISTEN state instead of "0"');
$search->set_states;
$search->set_protocols;
@found=$search->search($res);
ok( $#found eq '5', 'search, protocol+state reset') or diag('"'.$#found.'" number of returned connections for a empty search instead of "5"... failed to reset the protocols and states');

#make sure we can search based on ports
$search->set_ports(['22']);
@found=$search->search($res);
ok( $#found eq '4', 'search, Port 1') or diag('"'.$#found.'" number of returned connections for port 22 instead of "4"');
$search->set_ports(['ssh']);
@found=$search->search($res);
ok( $#found eq '4', 'search, Port 2') or diag('"'.$#found.'" number of returned connections for port ssh instead of "4"');
$search->set_ports(['ssh', 22]);
@found=$search->search($res);
ok( $#found eq '4', 'search, Port 3') or diag('"'.$#found.'" number of returned connections for port ssh, 22 instead of "4"');
$search->set_states( ['LISTEN'] );
@found=$search->search($res);
ok( $#found eq '0', 'search, port+state') or diag('"'.$#found.'" number of returned connections for port 22, ssh and LISTEN state  instead of "0"');
$search->set_states;
$search->set_ports;
@found=$search->search($res);
ok( $#found eq '5', 'search, port+state reset') or diag('"'.$#found.'" number of returned connections for a empty search instead of "5"... failed to reset the ports and states');

done_testing(20);
