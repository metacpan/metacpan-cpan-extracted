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
			 );

BEGIN {
    use_ok( 'Net::Connection::Sort' ) || print "Bail out!\n";
}

diag( "Testing Net::Connection::Sort $Net::Connection::Sort::VERSION, Perl $], $^X" );

my $sorter;
my $worked=0;
eval{
	$sorter=Net::Connection::Sort->new({ type=>'host_f' });
	$worked=1;
};
ok( $worked == 1, 'sorter init') or die ('Net::Connection::Sort->new resulted in... '.$@);

my @sorted;
$worked=0;
eval{
	@sorted=$sorter->sorter( \@objects );
	$worked=1;
};
ok( $worked == 1, 'sort') or die ('Net::Connection::Sort->sorter(@objects) resulted in... '.$@);

ok( $sorted[0]->foreign_host eq '1.1.1.1', 'sort order 0') or die ('The first foreign host value was not 1.1.1.1');
ok( $sorted[2]->foreign_host eq '5.5.5.5', 'sort order 1') or die ('The last foreign host value was not 5.5.5.5');

# the same sort, inverted
my $inverted;
$worked=0;
eval{
	$inverted=Net::Connection::Sort->new({ type=>'host_f', invert=>1 });
	$worked=1;
};
ok( $worked == 1, 'inverted sorter init') or die ('Net::Connection::Sort->new resulted in... '.$@);

my @inverted;
$worked=0;
eval{
	@inverted=$inverted->sorter( \@objects );
	$worked=1;
};
ok( $worked == 1, 'inverted sort') or die ('Net::Connection::Sort->sorter(@objects) resulted in... '.$@);

ok( $inverted[0]->foreign_host eq '5.5.5.5', 'invert order 0') or die ('The first foreign host value was not 5.5.5.5');
ok( $inverted[2]->foreign_host eq '1.1.1.1', 'invert order 1') or die ('The last foreign host value was not 1.1.1.1');

# a type that does not exist should die and not leave a usable object behind
my $missing;
eval{
	$missing=Net::Connection::Sort->new({ type=>'this_does_not_exist' });
};
ok( ! defined( $missing ), 'missing type dies') or die ('A non-existent type did not result in a die');

# the type is used to build a module name, so it must not be usable for
# smuggling in code to run
our $injected=0;
my $injection;
eval{
	$injection=Net::Connection::Sort->new({ type=>'host_f; $main::injected=1; #' });
};
ok( $injected == 0, 'no code injection via type') or die ('The type was able to run arbitrary code');
ok( ! defined( $injection ), 'injected type dies') or die ('A type holding more than a module name did not result in a die');

# anything that is not a array ref must die here the same as it does in the
# modules doing the actual sorting, instead of quietly returning nothing
foreach my $bad ( undef, 'foo', {} ){
	$worked=0;
	eval{
		$sorter->sorter( $bad );
		$worked=1;
	};
	ok( $worked == 0, 'sorter dies on a non-array') or die ('sorter did not die when passed a non-array');
}

done_testing(15);
