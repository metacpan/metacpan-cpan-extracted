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
								   'foreign_port' => 'FTP',
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
								   'foreign_port' => 'HTTP',
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
								   'foreign_port' => 'SSH',
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
								   'foreign_port' => 'HTTPS',
								   'local_port' => '11132',
								   'sendq' => '1',
								   'recvq' => '0',
								   'state' => 'ESTABLISHED',
								   'proto' => 'tcp4',
								   'ports' => 0,
								  }),
			 );

BEGIN {
    use_ok( 'Net::Connection::Sort::port_fa' ) || print "Bail out!\n";
}

diag( "Testing Net::Connection::Sort::port_fa $Net::Connection::Sort::port_fa::VERSION, Perl $], $^X" );

my $sorter;
my $worked=0;
eval{
	$sorter=Net::Connection::Sort::port_fa->new;
	$worked=1;
};
ok( $worked eq 1, 'sorter init') or die ('Net::Connection::Sort::port_fa->new resulted in... '.$@);

my @sorted;
$worked=0;
eval{
	@sorted=$sorter->sorter( \@objects );
	$worked=1;
};
ok( $worked eq 1, 'sort') or die ('Net::Connection::Sort::host_f->sorter(@objects) resulted in... '.$@);

ok( $sorted[0]->foreign_port =~ 'FTP', 'sort order 0') or die ('The first foreign port value was not FTP');
ok( $sorted[1]->foreign_port =~ 'HTTP', 'sort order 1') or die ('The last foreign port value was not HTTP');
ok( $sorted[2]->foreign_port =~ 'HTTPS', 'sort order 2') or die ('The middle foreign port value was not HTTPS');
ok( $sorted[3]->foreign_port =~ 'SSH' , 'sort order 2') or die ('The middle foreign port value was not SSH');

done_testing(7);
