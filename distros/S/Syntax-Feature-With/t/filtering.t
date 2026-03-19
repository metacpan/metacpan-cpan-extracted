use strict;
use warnings;
use Test::Most;

use Syntax::Feature::With qw(with_hash);

{
	package Dummy;
	our %H = (
		foo	=> 1,
		bar	=> 2,
		baz	=> 3,
		debug  => 99,
		unused => 42,
	);
}

# Lexicals that with()/with_hash will alias
my ($foo, $bar, $baz, $debug, $unused);
my ($a, $b, $c);  # for the H2 test

# -------------------------------------------------------------------------
# -only => [...]
# -------------------------------------------------------------------------

with_hash -only => [qw/foo baz/], \%Dummy::H, sub {

	is $foo, 1, 'only: $foo is aliased';
	is $baz, 3, 'only: $baz is aliased';

	ok !defined $bar,   'only: $bar is NOT aliased';
	ok !defined $debug, 'only: $debug is NOT aliased';

	$foo = 10;
	$baz = 30;
};

is $Dummy::H{foo}, 10, 'only: write-through works for $foo';
is $Dummy::H{baz}, 30, 'only: write-through works for $baz';

# -------------------------------------------------------------------------
# -except => [...]
# -------------------------------------------------------------------------

with_hash -except => [qw/debug unused/], \%Dummy::H, sub {

	is $foo, 10, 'except: $foo is aliased';
	is $bar, 2,  'except: $bar is aliased';
	is $baz, 30, 'except: $baz is aliased';

	ok !defined $debug,  'except: $debug is NOT aliased';
	ok !defined $unused, 'except: $unused is NOT aliased';

	$bar = 200;
};

is $Dummy::H{bar}, 200, 'except: write-through works for $bar';

# -------------------------------------------------------------------------
# -only + -except together should croak
# -------------------------------------------------------------------------

dies_ok {
	with_hash -only => ['foo'], -except => ['bar'], \%Dummy::H, sub { }
} '-only + -except together croaks';

# -------------------------------------------------------------------------
# -only => non-arrayref should croak
# -------------------------------------------------------------------------

dies_ok {
	with_hash -only => 'foo', \%Dummy::H, sub { }
} '-only => non-arrayref croaks';

# -------------------------------------------------------------------------
# -except => non-arrayref should croak
# -------------------------------------------------------------------------

dies_ok {
	with_hash -except => 'foo', \%Dummy::H, sub { }
} '-except => non-arrayref croaks';

# -------------------------------------------------------------------------
# Filtering with hashref form (H2)
# -------------------------------------------------------------------------

my %H2 = ( a => 1, b => 2, c => 3 );

with_hash -only => ['b'], \%H2, sub {
	is $b, 2, 'H2: -only => [b] aliases $b';
	ok !defined $a, 'H2: $a not aliased';
	ok !defined $c, 'H2: $c not aliased';

	$b = 22;
};

is $H2{b}, 22, 'H2: write-through works';

done_testing();
