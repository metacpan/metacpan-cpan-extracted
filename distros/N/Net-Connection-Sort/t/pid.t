#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Net::Connection;

my @objects=(
			 Net::Connection->new({
								   'foreign_host' => '3.3.3.3',
								   'local_host' => '4.4.4.4',
								   'foreign_port' => '22',
								   'local_port' => '11132',
								   'sendq' => '1',
								   'recvq' => '0',
								   'state' => 'LISTEN',
								   'proto' => 'tcp6',
								   'uid' => 1000,
								   'pid' => 2,
								  }),
			 Net::Connection->new({
								   'foreign_host' => '1.1.1.1',
								   'local_host' => '2.2.2.2',
								   'foreign_port' => '22',
								   'local_port' => '11132',
								   'sendq' => '1',
								   'recvq' => '0',
								   'state' => 'FIN_WAIT_2',
								   'proto' => 'udp4',
								   'uid' => 33,
								   'pid' => 0,
								  }),
			 Net::Connection->new({
								   'foreign_host' => '5.5.5.5',
								   'local_host' => '6.6.6.6',
								   'foreign_port' => '22',
								   'local_port' => '11132',
								   'sendq' => '1',
								   'recvq' => '0',
								   'state' => 'TIME_WAIT',
								   'proto' => 'udp6',
								   'uid' => 0,
								   'pid' => 1,
								  }),
			 Net::Connection->new({
								   'foreign_host' => '3.3.3.3',
								   'local_host' => '4.4.4.4',
								   'foreign_port' => '22',
								   'local_port' => '11132',
								   'sendq' => '1',
								   'recvq' => '0',
								   'state' => 'ESTABLISHED',
								   'proto' => 'tcp4',
								  }),
			 );

BEGIN {
    use_ok( 'Net::Connection::Sort::pid' ) || print "Bail out!\n";
}

diag( "Testing Net::Connection::Sort::pid $Net::Connection::Sort::pid::VERSION, Perl $], $^X" );

my $sorter;
my $worked=0;
eval{
	$sorter=Net::Connection::Sort::pid->new;
	$worked=1;
};
ok( $worked eq 1, 'sorter init') or die ('Net::Connection::Sort::pid->new resulted in... '.$@);

my @sorted;
$worked=0;
eval{
	@sorted=$sorter->sorter( \@objects );
	$worked=1;
};
ok( $worked eq 1, 'sort') or die ('Net::Connection::Sort::proto->sorter(@objects) resulted in... '.$@);

# 0 and 1 can end up in any order, make sure they are as expected
my $is_defined=1;
if( !defined( $sorted[0]->{pid} ) ||
	!defined( $sorted[1]->{pid} )
   ){
	$is_defined=0;
}
my $is_zero=0;
if( (
	 defined( $sorted[0]->{pid} ) &&
	 ( $sorted[0]->{pid} eq '0' )
	 ) || (
		   defined( $sorted[1]->{pid} ) &&
		   ( $sorted[1]->{pid} eq '0' )
	 )
   ){
	$is_zero=1;
}

ok( $is_defined eq '0', 'sort order 0') or die ('The PID for 0/1 is not 0');
ok( $is_zero eq '1', 'sort order 1') or die ('The PID for 0/1 is not 0');
ok( $sorted[2]->{pid} eq '1', 'sort order 2') or die ('The PID for 2 is not 33');
ok( $sorted[3]->{pid} eq '2', 'sort order 2') or die ('The PID for 3 is not 1000');

done_testing(7);
