use strict;

use Test::More;

BEGIN {
   use_ok('Parse::Netstat::Colorizer');
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
							{
							 'foreign_host' => '*',
							 'recvq' => '44',
							 'local_port' => '123',
							 'local_host' => 'fe80::1:%lo0',
							 'foreign_port' => '*',
							 'state' => '',
							 'proto' => 'udp6',
							 'sendq' => '33'
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

my $pnc=Parse::Netstat::Colorizer->new;

# port resolve test
my $port_resolve=$pnc->get_port_resolve;
ok( $port_resolve eq '1', 'port resolve, 1')or diag('"'.$port_resolve.'" returned for default port resolve value and not "1"');
$pnc->set_port_resolve(0);
$port_resolve=$pnc->get_port_resolve;
ok( $port_resolve eq '0', 'port resolve, 2')or diag('"'.$port_resolve.'" returned for the new port resolve value instead of "0"');
$pnc->set_port_resolve;
$port_resolve=$pnc->get_port_resolve;
ok( !defined($port_resolve) , 'port resolve, 3')or diag('"'.$port_resolve.'" returned for the new port resolve reset instead of "undef"');

# invert test
my $invert=$pnc->get_invert;
ok( !defined($invert) , 'invert, 1')or diag('"'.$invert.'" returned for default invert instead of "undef"');
$pnc->set_invert(1);
$invert=$pnc->get_invert;
ok( (defined($invert) && ( $invert eq '1' )) , 'invert, 2')or diag('"'.$invert.'" returned for invert instead of "1"');
$pnc->set_invert;
$invert=$pnc->get_invert;
ok( !defined($invert) , 'invert, 1')or diag('"'.$invert.'" returned for invert reset instead of "undef"');

my $colorized=$pnc->colorize($res);
ok( $pnc->error  eq '', 'colorize, 1')or diag('"'.$pnc->error.'" set for a error code when attempting to colorize');
ok( defined($colorized), 'colorize, 2')or diag('Undef returned upon attempting to colorize $res');

done_testing(10);
