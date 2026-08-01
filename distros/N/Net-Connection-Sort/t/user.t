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
    use_ok( 'Net::Connection::Sort::user' ) || print "Bail out!\n";
}

diag( "Testing Net::Connection::Sort::user $Net::Connection::Sort::user::VERSION, Perl $], $^X" );

my $sorter;
my $worked=0;
eval{
	$sorter=Net::Connection::Sort::user->new;
	$worked=1;
};
ok( $worked == 1, 'sorter init') or die ('Net::Connection::Sort::user->new resulted in... '.$@);

my @sorted;
$worked=0;
eval{
	@sorted=$sorter->sorter( \@objects );
	$worked=1;
};
ok( $worked == 1, 'sort') or die ('Net::Connection::Sort::user->sorter(@objects) resulted in... '.$@);

# a missing username is treated as a empty string, so unlike the UID and PID
# sorters there is no tie here and the order is fixed
ok( ! defined( $sorted[0]->username ), 'sort order 0') or die ('The username for 0 is not undef');
ok( $sorted[1]->username eq 'foo', 'sort order 1') or die ('The username for 1 is not foo');
ok( $sorted[2]->username eq 'root', 'sort order 2') or die ('The username for 2 is not root');
ok( $sorted[3]->username eq 'toor', 'sort order 3') or die ('The username for 3 is not toor');

# a connection with no username must not collide with a user actually named 0
my @zero=(
		  Net::Connection->new({
								'foreign_host' => '1.1.1.1',
								'local_host' => '2.2.2.2',
								'foreign_port' => '22',
								'local_port' => '11132',
								'state' => 'ESTABLISHED',
								'proto' => 'tcp4',
								'username' => '0',
								'uid_resolve' => 0,
							   }),
		  Net::Connection->new({
								'foreign_host' => '1.1.1.1',
								'local_host' => '2.2.2.2',
								'foreign_port' => '22',
								'local_port' => '11132',
								'state' => 'ESTABLISHED',
								'proto' => 'tcp4',
								'uid_resolve' => 0,
							   }),
		  );

@sorted=$sorter->sorter( \@zero );

ok( ! defined( $sorted[0]->username ), 'no username sorts first') or die ('The connection without a username did not sort first');
ok( ( defined( $sorted[1]->username ) && ( $sorted[1]->username eq '0' ) ), 'a user named 0 sorts second') or die ('The user named 0 did not sort second');

done_testing(9);
