use Test::More;
use Object::Iterate qw(imap igrep iterate);

# since we are using a prototype here, the sub definition needs to
# come before we use the sub
sub prototype_ok(\&$;$) {
	my( $sub, $prototype, $name ) = @_;
	$name ||= 'function prototype is correct';

	my $actual     = prototype( $sub );
	my $test       = $actual eq $prototype;

	unless( $test ) {
		diag( "Subroutine has prototype [$actual]; expected [$prototype]" );
		ok(0, $name);
		}
	else {
		ok(1, $name);
		}
	}

prototype_ok( &main::imap,    '&$' );
prototype_ok( &main::igrep,   '&$' );
prototype_ok( &main::iterate, '&$' );


done_testing();
