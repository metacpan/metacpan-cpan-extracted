package MyTest;

use Syntax::Collector q/
use strict 0;
use warnings 0 FATAL => 'all';
use Test::More 0.96;
use Test::Fatal 0;
use Scalar::Util 1.20 qw( reftype blessed );
/;

# Convenience function similar to isa_ok($thing, $class)
our @EXPORT = qw( does_ok );

sub does_ok {
	my ($thing, $role, $message) = @_;
	$message = "$thing does $role" unless defined $message;
	
	@_ = ( $thing->DOES($role), $message );
	goto \&Test::More::ok;
}

1;
