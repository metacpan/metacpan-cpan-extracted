#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Net::Connection;

my @objects=(
			 Net::Connection->new({
								   'foreign_host' => '3.3.3.4',
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
    use_ok( 'Net::Connection::Sort::host_lf' ) || print "Bail out!\n";
}

diag( "Testing Net::Connection::Sort::host_lf $Net::Connection::Sort::host_lf::VERSION, Perl $], $^X" );

my $sorter;
my $worked=0;
eval{
	$sorter=Net::Connection::Sort::host_lf->new;
	$worked=1;
};
ok( $worked eq 1, 'sorter init') or die ('Net::Connection::Sort::host_lf->new resulted in... '.$@);

my @sorted;
$worked=0;
eval{
	@sorted=$sorter->sorter( \@objects );
	$worked=1;
};
ok( $worked eq 1, 'sort') or die ('Net::Connection::Sort::host_lf->sorter(@objects) resulted in... '.$@);

ok( $sorted[0]->local_host eq '2.2.2.2', 'sort order 0') or die ('The first local host value was not 2.2.2.2');
ok( $sorted[3]->local_host eq '6.6.6.6', 'sort order 1') or die ('The last local host value was not 6.6.6.6');
ok( $sorted[1]->foreign_host eq '3.3.3.3', 'sort order 2') or die ('The second foreign host value was not 3.3.3.3');
ok( $sorted[2]->foreign_host eq '3.3.3.4', 'sort order 3') or die ('The third foreign host value was not 3.3.3.4');

done_testing(7);
