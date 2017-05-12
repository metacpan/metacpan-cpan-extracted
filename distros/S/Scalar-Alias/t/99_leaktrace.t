#!perl -w

use strict;
use constant HAS_LEAKTRACE => eval{ require Test::LeakTrace };
use Test::More HAS_LEAKTRACE ? (tests => 4) : (skip_all => 'Testing leaktrace');
use Test::LeakTrace;

use Scalar::Alias;

sub f{
	return $_[0]; # returns temporary (mortal) SV
}

# scalar alias


no_leaks_ok{
	my $x = 10;
	my alias $y = $x;

	$x++;
	$y++;
} 'scalar alias';

sub inc{
	my alias $x = f(shift);
	$x++;
}

no_leaks_ok{
	my $i = 0;
	inc($i);
} 'scalar alias';

# list alias


no_leaks_ok{
	my $x = 10;
	my alias($y) = $x;
	$y++;
} 'list alias';

no_leaks_ok{
	my $x = 10;
	my alias($y) = f($x);
	$y++;
} 'list alias';

