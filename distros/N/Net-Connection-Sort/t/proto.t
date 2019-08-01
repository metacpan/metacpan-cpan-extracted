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
								   'proto' => 'tcp6'
								  }),
			 Net::Connection->new({
								   'foreign_host' => '1.1.1.1',
								   'local_host' => '2.2.2.2',
								   'foreign_port' => '22',
								   'local_port' => '11132',
								   'sendq' => '1',
								   'recvq' => '0',
								   'state' => 'FIN_WAIT_2',
								   'proto' => 'udp4'
								  }),
			 Net::Connection->new({
								   'foreign_host' => '5.5.5.5',
								   'local_host' => '6.6.6.6',
								   'foreign_port' => '22',
								   'local_port' => '11132',
								   'sendq' => '1',
								   'recvq' => '0',
								   'state' => 'TIME_WAIT',
								   'proto' => 'udp6'
								  }),
			 Net::Connection->new({
								   'foreign_host' => '3.3.3.3',
								   'local_host' => '4.4.4.4',
								   'foreign_port' => '22',
								   'local_port' => '11132',
								   'sendq' => '1',
								   'recvq' => '0',
								   'state' => 'ESTABLISHED',
								   'proto' => 'tcp4'
								  }),
			 );

BEGIN {
    use_ok( 'Net::Connection::Sort::proto' ) || print "Bail out!\n";
}

diag( "Testing Net::Connection::Sort::proto $Net::Connection::Sort::proto::VERSION, Perl $], $^X" );

my $sorter;
my $worked=0;
eval{
	$sorter=Net::Connection::Sort::proto->new;
	$worked=1;
};
ok( $worked eq 1, 'sorter init') or die ('Net::Connection::Sort::proto->new resulted in... '.$@);

my @sorted;
$worked=0;
eval{
	@sorted=$sorter->sorter( \@objects );
	$worked=1;
};
ok( $worked eq 1, 'sort') or die ('Net::Connection::Sort::proto->sorter(@objects) resulted in... '.$@);

ok( $sorted[0]->proto =~ 'tcp4', 'sort order 0') or die ('The proto for 0 is not tcp4');
ok( $sorted[1]->proto =~ 'tcp6', 'sort order 1') or die ('The proto for 1 is not tcp6');
ok( $sorted[2]->proto =~ 'udp4', 'sort order 2') or die ('The proto for 2 is not udp4');
ok( $sorted[3]->proto =~ 'udp6', 'sort order 2') or die ('The proto for 3 is not udp6');

done_testing(7);
