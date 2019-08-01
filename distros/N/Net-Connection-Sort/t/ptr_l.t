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
								   'username' => 'toor',
								   'uid_resolve' => 0,
								   'ptrs' => 0,
								   'local_ptr' => 'a.foo',
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
								   'username' => 'root',
								   'uid_resolve' => 0,
								   'ptrs' => 0,
								   'local_ptr' => 'c.foo',
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
								   'username'=> 'foo',
								   'uid_resolve' => 0,
								   'ptrs' => 0,
								   'local_ptr' => 'b.foo',
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
    use_ok( 'Net::Connection::Sort::ptr_l' ) || print "Bail out!\n";
}

diag( "Testing Net::Connection::Sort::ptr_l $Net::Connection::Sort::ptr_l::VERSION, Perl $], $^X" );

my $sorter;
my $worked=0;
eval{
	$sorter=Net::Connection::Sort::ptr_l->new;
	$worked=1;
};
ok( $worked eq 1, 'sorter init') or die ('Net::Connection::Sort::ptr_l->new resulted in... '.$@);

my @sorted;
$worked=0;
eval{
	@sorted=$sorter->sorter( \@objects );
	$worked=1;
};
ok( $worked eq 1, 'sort') or die ('Net::Connection::Sort::proto->sorter(@objects) resulted in... '.$@);

my $is_defined=1;
if ( !defined( $sorted[0]->local_ptr ) ){
	$is_defined=0;
}

ok( $is_defined eq '0', 'sort order 0') or die ('The first ptr should be undef.');
ok( $sorted[1]->local_ptr =~ 'a.foo', 'sort order 1') or die ('The ptr for 1 is not a.foo ');
ok( $sorted[2]->local_ptr =~ 'b.foo', 'sort order 2') or die ('The ptr for 2 is not b.foo');
ok( $sorted[3]->local_ptr =~ 'c.foo', 'sort order 2') or die ('The ptr for 3 is not c.foo');

done_testing(7);
