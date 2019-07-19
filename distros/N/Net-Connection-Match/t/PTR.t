#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Net::Connection;

BEGIN {
    use_ok( 'Net::Connection::Match::PTR' ) || print "Bail out!\n";
}

my $connection_args={
					 foreign_host=>'10.0.0.1',
					 foreign_port=>'22',
					 local_host=>'10.0.0.2',
					 local_port=>'12322',
					 proto=>'tcp4',
					 state=>'LISTEN',
					 local_ptr=>'foo.bar',
					 foreign_ptr=>'test',
					 };

my %args=(
		  ptrs=>[
				 'foo.bar',
				 ],
		  );
my %largs=(
		  lptrs=>[
				 'foo.bar',
				 ],
		   );
my %fargs=(
		  fptrs=>[
				 'foo.bar',
				 ],
		  );
my $checker;

# makes sure we error with empty args
my $worked=0;
eval{
	$checker=Net::Connection::Match::PTR->new();
	$worked=1;
};
ok( $worked eq '0', 'empty init check') or diag('Calling new with empty args worked');

# makes sure we can init with general good args
$worked=0;
eval{
	$checker=Net::Connection::Match::PTR->new( \%args );
	$worked=1;
};
ok( $worked eq '1', 'init check, general') or diag('Calling Net::Connection::Match::PTR->new resulted in... '.$@);

# make sure it will not accept null input
my $returned=1;
eval{
	$returned=$checker->match;
};
ok( $returned eq '0', 'proto undef check') or diag('match accepted undefined input');

# make sure it will not accept a improper ref type
$returned=1;
eval{
	$returned=$checker->match($checker);
};
ok( $returned eq '0', 'match improper ref check') or diag('match accepted a ref other than Net::Connection');

# make sure the general PTR check works, testing local
$returned=0;
my $conn=Net::Connection->new( $connection_args );
eval{
	$returned=$checker->match( $conn );
};
ok( $returned eq '1', 'general PTR match check, local') or diag('failed to match a Net::Connection for a general PTR check when one of the two matches');

# make sure the general PTR check works, testing foreign
$connection_args->{local_ptr}='test';
$connection_args->{foreign_ptr}='foo.bar';
$conn=Net::Connection->new( $connection_args );
eval{
	$returned=$checker->match( $conn );
};
ok( $returned eq '1', 'general PTR match check, foriegn') or diag('failed to match a Net::Connection for a general PTR check when one of the two matches');

# makes sure we can init with local good args
$worked=0;
eval{
	$checker=Net::Connection::Match::PTR->new( \%largs );
	$worked=1;
};
ok( $worked eq '1', 'init check, local') or diag('Calling Net::Connection::Match::PTR->new resulted in... '.$@);

# make sure the local PTR check works, testing foreign
$returned=0;
eval{
	$returned=$checker->match( $conn );
};
ok( $returned eq '0', 'local PTR match check, foreign') or diag('matched a Net::Connection object when looking for local PTRs when the foreign matches');

# make sure the local PTR check works, testing local
$returned=0;
$connection_args->{foreign_ptr}='test';
$connection_args->{local_ptr}='foo.bar';
$conn=Net::Connection->new( $connection_args );
eval{
	$returned=$checker->match( $conn );
};
ok( $returned eq '1', 'local PTR match check, local') or diag('did not match a Net::Connection object when looking for local PTRs when the local matches');

# makes sure we can init with foreign good args
$worked=0;
eval{
	$checker=Net::Connection::Match::PTR->new( \%fargs );
	$worked=1;
};
ok( $worked eq '1', 'init check, foreign') or diag('Calling Net::Connection::Match::PTR->new resulted in... '.$@);

# make sure the foreign PTR check works, testing local
$returned=0;
eval{
	$returned=$checker->match( $conn );
};
ok( $returned eq '0', 'foreign PTR match check, local') or diag('matched a Net::Connection object when looking for foreign PTRs when the local matches');

# make sure the foreign PTR check works, testing foreign
$returned=0;
$connection_args->{local_ptr}='test';
$connection_args->{foreign_ptr}='foo.bar';
$conn=Net::Connection->new( $connection_args );
eval{
	$returned=$checker->match( $conn );
};
ok( $returned eq '1', 'local PTR match check, foreign') or diag('did not match a Net::Connection object when looking for foreign PTRs when the foreign matches');

done_testing(13);
