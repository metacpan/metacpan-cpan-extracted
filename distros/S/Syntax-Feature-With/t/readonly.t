use strict;
use warnings;
use Test::Most;

use Syntax::Feature::With qw(with_hash);

my %H = ( foo => 1, bar => 2 );
my ($foo, $bar, $x);

# -------------------------------------------------------------------------
# Basic readonly
# -------------------------------------------------------------------------

with_hash -readonly => \%H, sub {
	is $foo, 1, 'readonly: $foo aliased';
	dies_ok { $foo = 10 } 'readonly: writing to $foo dies';
};

is $H{foo}, 1, 'readonly: write-through prevented';

# -------------------------------------------------------------------------
# readonly + rename
# -------------------------------------------------------------------------

with_hash
	-readonly,
	-rename => { foo => 'x' },
	\%H,
	sub {
		is $x, 1, 'readonly+rename: alias works';
		dies_ok { $x = 20 } 'readonly+rename: write dies';
	};

# -------------------------------------------------------------------------
# readonly + strict: missing lexical still dies
# -------------------------------------------------------------------------

dies_ok {
	with_hash -readonly, -strict, -rename => { foo => 'missing_lex' }, \%H, sub { };
} 'readonly+strict: missing lexical still dies';

done_testing;
