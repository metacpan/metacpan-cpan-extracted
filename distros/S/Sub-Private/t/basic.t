use strict;
use warnings;
use Test::Most;
use Sub::Private;

# Tests for namespace mode (the default, backward-compatible mode).
# Disable both bypass mechanisms so any accidental enforce-mode checks fire.
local $ENV{HARNESS_ACTIVE}  = 0;
local $Sub::Private::BYPASS = 0;

{
	package NSFoo;
	use Sub::Private;

	sub new { bless {}, shift }
	sub foo { return 42 }
	sub bar :Private { return foo() + 1 }
	sub baz { return bar() + 1 }
}

{
	package NSExternal;
	sub probe_bar { NSFoo::bar() }
}

# can('bar') must return undef -- bar was removed from the namespace
ok !NSFoo->can('bar'), 'namespace mode: can("bar") returns undef after :Private';

# can('foo') must still work -- foo is not private
ok( NSFoo->can('foo'), 'namespace mode: can("foo") still works' );

# Plain function call chain: baz() calls bar() via compiled opcode
my $result;
lives_and { is $result = NSFoo->baz, 44 }
	'namespace mode: baz() calling bar() internally returns 44';

# Compiled external calls (fully-qualified) still work -- the opcode holds a
# direct ref to the CV, so cleanup of the glob entry doesn't affect them.
lives_ok { NSExternal::probe_bar() }
	'namespace mode: compiled fully-qualified call still works (opcode holds CV ref)';

# Method dispatch uses the symbol table at runtime and therefore fails.
throws_ok { NSFoo->new->bar }
	qr/Can't locate object method|Undefined subroutine/,
	'namespace mode: method dispatch fails (symbol table lookup at runtime)';

done_testing;
