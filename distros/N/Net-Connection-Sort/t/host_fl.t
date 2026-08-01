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
								   'local_host' => '4.4.4.5',
								   'foreign_port' => '22',
								   'local_port' => '11132',
								   'sendq' => '1',
								   'recvq' => '0',
								   'state' => 'ESTABLISHED',
								   'proto' => 'tcp4'
								  }),
			 );

BEGIN {
    use_ok( 'Net::Connection::Sort::host_fl' ) || print "Bail out!\n";
}

diag( "Testing Net::Connection::Sort::host_fl $Net::Connection::Sort::host_fl::VERSION, Perl $], $^X" );

my $sorter;
my $worked=0;
eval{
	$sorter=Net::Connection::Sort::host_fl->new;
	$worked=1;
};
ok( $worked == 1, 'sorter init') or die ('Net::Connection::Sort::host_fl->new resulted in... '.$@);

my @sorted;
$worked=0;
eval{
	@sorted=$sorter->sorter( \@objects );
	$worked=1;
};
ok( $worked == 1, 'sort') or die ('Net::Connection::Sort::host_fl->sorter(@objects) resulted in... '.$@);

ok( $sorted[0]->foreign_host eq '1.1.1.1', 'sort order 0') or die ('The first foreign host value was not 1.1.1.1');
ok( $sorted[3]->foreign_host eq '5.5.5.5', 'sort order 1') or die ('The last foreign host value was not 5.5.5.5');
ok( $sorted[1]->local_host eq '4.4.4.4', 'sort order 2') or die ('The middle local host value was not 4.4.4.4');
ok( $sorted[2]->local_host eq '4.4.4.5', 'sort order 3') or die ('The middle local host value was not 4.4.4.5');


# link local addresses arrive with a zone id attached and must still sort by
# the address rather than all collapsing together
my @zoned=map {
	Net::Connection->new({
						  'foreign_host' => $_,
						  'local_host' => $_,
						  'foreign_port' => '22',
						  'local_port' => '11132',
						  'state' => 'ESTABLISHED',
						  'proto' => 'tcp6',
						  })
} ( 'fe80::3%eth0', 'fe80::1%eth0', 'fe80::2%em0' );

@sorted=$sorter->sorter( \@zoned );

ok( $sorted[0]->foreign_host eq 'fe80::1%eth0', 'zone id sort order 0') or die ('The first host was not fe80::1%eth0');
ok( $sorted[1]->foreign_host eq 'fe80::2%em0', 'zone id sort order 1') or die ('The middle host was not fe80::2%em0');
ok( $sorted[2]->foreign_host eq 'fe80::3%eth0', 'zone id sort order 2') or die ('The last host was not fe80::3%eth0');

done_testing(10);
