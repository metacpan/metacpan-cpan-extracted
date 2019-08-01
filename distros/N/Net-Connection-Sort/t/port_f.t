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
								   'foreign_port' => '1',
								   'local_port' => '11132',
								   'sendq' => '1',
								   'recvq' => '0',
								   'state' => 'ESTABLISHED',
								   'proto' => 'tcp4',
								   'ports' => 0,
								  }),
			 Net::Connection->new({
								   'foreign_host' => '1.1.1.1',
								   'local_host' => '2.2.2.2',
								   'foreign_port' => '80',
								   'local_port' => '11132',
								   'sendq' => '1',
								   'recvq' => '0',
								   'state' => 'ESTABLISHED',
								   'proto' => 'tcp4',
								   'ports' => 0,
								  }),
			 Net::Connection->new({
								   'foreign_host' => '5.5.5.5',
								   'local_host' => '6.6.6.6',
								   'foreign_port' => '22',
								   'local_port' => '11132',
								   'sendq' => '1',
								   'recvq' => '0',
								   'state' => 'ESTABLISHED',
								   'proto' => 'tcp4',
								   'ports' => 0,
								  }),
			 Net::Connection->new({
								   'foreign_host' => '3.3.3.3',
								   'local_host' => '4.4.4.4',
								   'foreign_port' => '21',
								   'local_port' => '11132',
								   'sendq' => '1',
								   'recvq' => '0',
								   'state' => 'ESTABLISHED',
								   'proto' => 'tcp4',
								   'ports' => 0,
								  }),
			 );

BEGIN {
    use_ok( 'Net::Connection::Sort::port_f' ) || print "Bail out!\n";
}

diag( "Testing Net::Connection::Sort::port_f $Net::Connection::Sort::port_f::VERSION, Perl $], $^X" );

my $sorter;
my $worked=0;
eval{
	$sorter=Net::Connection::Sort::port_f->new;
	$worked=1;
};
ok( $worked eq 1, 'sorter init') or die ('Net::Connection::Sort::port_f->new resulted in... '.$@);

my @sorted;
$worked=0;
eval{
	@sorted=$sorter->sorter( \@objects );
	$worked=1;
};
ok( $worked eq 1, 'sort') or die ('Net::Connection::Sort::host_f->sorter(@objects) resulted in... '.$@);

ok( $sorted[0]->foreign_port eq '1', 'sort order 0') or die ('The first foreign port value was not 1');
ok( $sorted[1]->foreign_port eq '21', 'sort order 1') or die ('The last foreign port value was not 21');
ok( $sorted[2]->foreign_port eq '22', 'sort order 2') or die ('The middle foreign port value was not 22');
ok( $sorted[3]->foreign_port eq '80' , 'sort order 2') or die ('The middle foreign port value was not 80');

done_testing(7);
