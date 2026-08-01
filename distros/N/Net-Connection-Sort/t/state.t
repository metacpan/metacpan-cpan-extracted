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
								   'proto' => 'tcp4'
								  }),
			 Net::Connection->new({
								   'foreign_host' => '1.1.1.1',
								   'local_host' => '2.2.2.2',
								   'foreign_port' => '22',
								   'local_port' => '11132',
								   'sendq' => '1',
								   'recvq' => '0',
								   'state' => 'FIN_WAIT_2',
								   'proto' => 'tcp4'
								  }),
			 Net::Connection->new({
								   'foreign_host' => '5.5.5.5',
								   'local_host' => '6.6.6.6',
								   'foreign_port' => '22',
								   'local_port' => '11132',
								   'sendq' => '1',
								   'recvq' => '0',
								   'state' => 'TIME_WAIT',
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
    use_ok( 'Net::Connection::Sort::state' ) || print "Bail out!\n";
}

diag( "Testing Net::Connection::Sort::state $Net::Connection::Sort::state::VERSION, Perl $], $^X" );

my $sorter;
my $worked=0;
eval{
	$sorter=Net::Connection::Sort::state->new;
	$worked=1;
};
ok( $worked == 1, 'sorter init') or die ('Net::Connection::Sort::state->new resulted in... '.$@);

my @sorted;
$worked=0;
eval{
	@sorted=$sorter->sorter( \@objects );
	$worked=1;
};
ok( $worked == 1, 'sort') or die ('Net::Connection::Sort::state->sorter(@objects) resulted in... '.$@);

ok( $sorted[0]->state eq 'ESTABLISHED', 'sort order 0') or die ('The state for 0 is not ESTABLISHED');
ok( $sorted[1]->state eq 'FIN_WAIT_2', 'sort order 1') or die ('The state for 1 is not FIN_WAIT_2');
ok( $sorted[2]->state eq 'LISTEN', 'sort order 2') or die ('The state for 2 is not LISTEN');
ok( $sorted[3]->state eq 'TIME_WAIT', 'sort order 3') or die ('The state for 3 is not TIME_WAIT');


# UDP entries come through with a empty state and wildcards for the remote
# end, which must sort ahead of the real states without warning
my @edge=(
		  Net::Connection->new({
								'foreign_host' => '1.1.1.1',
								'local_host' => '2.2.2.2',
								'foreign_port' => '53',
								'local_port' => '123',
								'state' => 'LISTEN',
								'proto' => 'udp4',
							   }),
		  Net::Connection->new({
								'foreign_host' => '*',
								'local_host' => '*',
								'foreign_port' => '*',
								'local_port' => '123',
								'state' => '',
								'proto' => 'udp4',
							   }),
		  Net::Connection->new({
								'foreign_host' => '3.3.3.3',
								'local_host' => '4.4.4.4',
								'foreign_port' => '80',
								'local_port' => '123',
								'state' => 'ESTABLISHED',
								'proto' => 'tcp4',
							   }),
		  );

my @warnings;
$worked=0;
eval{
	local $SIG{__WARN__}=sub{ push( @warnings, $_[0] ) };
	@sorted=$sorter->sorter( \@edge );
	$worked=1;
};
ok( $worked == 1, 'empty state sort') or die ('Sorting a empty state resulted in... '.$@);
ok( ! @warnings, 'empty state sort is warning free') or die ('Sorting a empty state warned... '.join('', @warnings));
ok( $sorted[0]->state eq '', 'empty state sort order 0') or die ('The first state was not empty');
ok( $sorted[2]->state eq 'LISTEN', 'empty state sort order 1') or die ('The last state was not LISTEN');

done_testing(11);
