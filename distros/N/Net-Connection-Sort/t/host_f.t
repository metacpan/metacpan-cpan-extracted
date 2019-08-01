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
								   'state' => 'ESTABLISHED',
								   'proto' => 'tcp4'
								  }),
			 Net::Connection->new({
								   'foreign_host' => '1.1.1.1',
								   'local_host' => '2.2.2.2',
								   'foreign_port' => '22',
								   'local_port' => '11132',
								   'sendq' => '1',
								   'recvq' => '0',
								   'state' => 'ESTABLISHED',
								   'proto' => 'tcp4'
								  }),
			 Net::Connection->new({
								   'foreign_host' => '5.5.5.5',
								   'local_host' => '6.6.6.6',
								   'foreign_port' => '22',
								   'local_port' => '11132',
								   'sendq' => '1',
								   'recvq' => '0',
								   'state' => 'ESTABLISHED',
								   'proto' => 'tcp4'
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
    use_ok( 'Net::Connection::Sort::host_f' ) || print "Bail out!\n";
}

diag( "Testing Net::Connection::Sort::host_f $Net::Connection::Sort::host_f::VERSION, Perl $], $^X" );

my $sorter;
my $worked=0;
eval{
	$sorter=Net::Connection::Sort::host_f->new;
	$worked=1;
};
ok( $worked eq 1, 'sorter init') or die ('Net::Connection::Sort::host_f->new resulted in... '.$@);

my @sorted;
$worked=0;
eval{
	@sorted=$sorter->sorter( \@objects );
	$worked=1;
};
ok( $worked eq 1, 'sort') or die ('Net::Connection::Sort::host_f->sorter(@objects) resulted in... '.$@);

ok( $sorted[0]->foreign_host eq '1.1.1.1', 'sort order 0') or die ('The first foreign host value was not 1.1.1.1');
ok( $sorted[3]->foreign_host eq '5.5.5.5', 'sort order 1') or die ('The last foreign host value was not 5.5.5.5');
ok( $sorted[2]->foreign_host eq '3.3.3.3', 'sort order 2') or die ('The middle foreign host value was not 3.3.3.3');
ok( $sorted[1]->foreign_host eq '3.3.3.3', 'sort order 2') or die ('The middle foreign host value was not 3.3.3.3');

done_testing(7);
