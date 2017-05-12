package main;

use Test::More qw[no_plan];

BEGIN {
	use_ok( 'POE', 'Session::MultiDispatch' );
}

my $session = POE::Session::MultiDispatch->create(
	inline_states => {
		_start => \&_start,
	},
	package_states => [
		One => [ qw[_start count] ],
	],
	object_states => [
		Two->new, [ qw[_start count] ],
	],
);

isa_ok( $session, 'POE::Session::MultiDispatch' );

sub _start {
	my ($kernel, $session, $heap) = @_[KERNEL, SESSION, HEAP];
	isa_ok( $session, 'POE::Session::MultiDispatch', 'state main::_start session' );
	$heap->{count} = 0;
	$kernel->yield( 'count' );
}

package One;

use Test::More;
use POE;

sub _start {
	my ($session) = $_[SESSION];
	isa_ok( $session, 'POE::Session::MultiDispatch', 'state One::_start session' );
	
	ok( $session->swap( count => qw[One Two] ), 'swap successful' );
}

sub count {
	my ($heap) = $_[HEAP];
	$heap->{count} -= 1;
	is( $heap->{count}, 1, 'One::count called second' );
}

package Two;

use Test::More;
use POE;

sub new { return bless { }, shift }

sub _start {
	my ($session,$object) = @_[SESSION,OBJECT];
	isa_ok( $session, 'POE::Session::MultiDispatch', 'state Two::_start session' );
	isa_ok( $object,  'Two' );
}

sub count {
	my ($heap) = $_[HEAP];
	$heap->{count} += 2;
	is( $heap->{count}, 2, 'Two->count called first' );
}

package main;

$poe_kernel->run;
exit(0);
