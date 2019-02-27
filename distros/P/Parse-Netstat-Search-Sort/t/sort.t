use strict;

use Test::More;
use Parse::Netstat::Search;

BEGIN {
	use_ok('Parse::Netstat::Search::Sort');
}

my @found=(
		 {
		  'foreign_host'=>'1.1.1.1',
		  'local_host'=>'2.2.2.1',
		  'foreign_port'=>'22221',
		  'local_port'=>'11',
		  'sendq'=>'5',
		  'recvq'=>'4',
		  'state' => 'ESTABLISHED',
		  'proto' => 'tcp4',
		  },
		 {
		  'foreign_host'=>'1.1.1.2',
		  'local_host'=>'2.2.2.5',
		  'foreign_port'=>'22',
		  'local_port'=>'2222',
		  'sendq'=>'33',
		  'recvq'=>'3',
		  'state' => 'TIME_WAIT',
		  'proto' => 'tcp4',
		  },
		 {
		  'foreign_host'=>'1.1.1.1',
		  'local_host'=>'2.2.2.3',
		  'foreign_port'=>'22',
		  'local_port'=>'444',
		  'sendq'=>'7',
		  'recvq'=>'2',
		  'state' => 'ESTABLISHED',
		  'proto' => 'tcp4',
		  },
		 {
		  'foreign_host'=>'1.1.1.5',
		  'local_host'=>'2.2.2.2',
		  'foreign_port'=>'22',
		  'local_port'=>'2222',
		  'sendq'=>'0',
		  'recvq'=>'1',
		  'state' => '',
		  'proto' => 'udp4',
		  },
);

my $sorter=Parse::Netstat::Search::Sort->new;

my @sorted=$sorter->sort( \@found );

ok( $sorted[0]->{foreign_host} eq '1.1.1.1', 'host_f, 1') or diag('"'.$sorted[0]->{foreign_host}.'" returned for $sorted[0]->{foreign_host} instead of "1.1.1.1"');
ok( $sorted[1]->{foreign_host} eq '1.1.1.1', 'host_f, 2') or diag('"'.$sorted[1]->{foreign_host}.'" returned for $sorted[1]->{foreign_host} instead of "1.1.1.2"');

$sorter->set_sort('host_l');
my ($sort_type, $invert)=$sorter->get_sort;
ok( $sort_type eq 'host_l', 'get_sort, type') or diag('"'.$sort_type.'" returned instead of "host_l"');

@sorted=$sorter->sort( \@found );
ok( $sorted[0]->{local_host} eq '2.2.2.1', 'host_l, 1') or diag('"'.$sorted[0]->{local_host}.'" returned for $sorted[0]->{local_host} instead of "2.2.2.1"');
ok( $sorted[1]->{local_host} eq '2.2.2.2', 'host_l, 2') or diag('"'.$sorted[1]->{local_host}.'" returned for $sorted[1]->{local_host} instead of "2.2.2.2"');

$sorter->set_sort('state');
@sorted=$sorter->sort( \@found );
ok( $sorted[0]->{state} eq '', 'state, 1') or diag('"'.$sorted[0]->{state}.'" returned for $sorted[0]->{state} instead of ""');
ok( $sorted[3]->{state} eq 'TIME_WAIT', 'state, 2') or diag('"'.$sorted[3]->{state}.'" returned for $sorted[3]->{state} instead of "TIME_WAIT"');

$sorter->set_sort('protocol');
@sorted=$sorter->sort( \@found );
ok( $sorted[0]->{proto} eq 'tcp4', 'protocol, 1') or diag('"'.$sorted[0]->{proto}.'" returned for $sorted[0]->{proto} instead of "tcp4"');
ok( $sorted[3]->{proto} eq 'udp4', 'protocol, 2') or diag('"'.$sorted[3]->{proto}.'" returned for $sorted[3]->{proto} instead of "udp4"');

$sorter->set_sort('port_l');
@sorted=$sorter->sort( \@found );
ok( $sorted[0]->{local_port} eq '11', 'port_l, 1') or diag('"'.$sorted[0]->{local_port}.'" returned for $sorted[0]->{local_port} instead of "11"');
ok( $sorted[3]->{local_port} eq '2222', 'port_l, 2') or diag('"'.$sorted[3]->{local_port}.'" returned for $sorted[3]->{local_port} instead of "2222"');

$sorter->set_sort('port_f');
@sorted=$sorter->sort( \@found );
ok( $sorted[0]->{foreign_port} eq '22', 'port_f, 1') or diag('"'.$sorted[0]->{foreign_port}.'" returned for $sorted[0]->{foreign_Port} instead of "22"');
ok( $sorted[3]->{foreign_port} eq '22221', 'port_f, 2') or diag('"'.$sorted[3]->{foreign_port}.'" returned for $sorted[3]->{foreign_port} instead of "22221"');

$sorter->set_sort('q_r');
@sorted=$sorter->sort( \@found );
ok( $sorted[0]->{recvq} eq '1', 'q_r, 1') or diag('"'.$sorted[0]->{recvq}.'" returned for $sorted[0]->{recvq} instead of "1"');
ok( $sorted[3]->{recvq} eq '4', 'q_r, 2') or diag('"'.$sorted[3]->{recvq}.'" returned for $sorted[3]->{recvq} instead of "4"');

$sorter->set_sort('q_s');
@sorted=$sorter->sort( \@found );
ok( $sorted[0]->{sendq} eq '0', 'q_s, 1') or diag('"'.$sorted[0]->{sendq}.'" returned for $sorted[0]->{recvq} instead of "5"');
ok( $sorted[3]->{sendq} eq '33', 'q_s, 2') or diag('"'.$sorted[3]->{sendq}.'" returned for $sorted[3]->{sendq} instead of "33"');

done_testing(18);
