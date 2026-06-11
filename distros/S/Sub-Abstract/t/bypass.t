use strict;
use warnings;
use Test::Most;
use Sub::Abstract;

# $BYPASS and HARNESS_ACTIVE each independently suppress the abstract croak.

local $ENV{HARNESS_ACTIVE}   = 0;
local $Sub::Abstract::BYPASS = 0;

{
	package Flyable;
	use Sub::Abstract;
	sub new { bless {}, shift }
	sub fly :Abstract { }
}

{
	package Penguin;
	our @ISA = ('Flyable');
	sub new { bless {}, shift }
	# Penguin does not implement fly
}

my $p = Penguin->new;

# Baseline: calling abstract method without bypass croaks
throws_ok { $p->fly }
	qr/abstract method/,
	'baseline: abstract method croaks with both bypasses off';

# $BYPASS=1 alone suppresses the croak
{
	local $Sub::Abstract::BYPASS = 1;
	lives_ok { $p->fly } '$BYPASS=1 suppresses the abstract croak';
}

# Confirm $BYPASS scope restored
throws_ok { $p->fly }
	qr/abstract method/,
	'$BYPASS restored to 0 after scope exits';

# HARNESS_ACTIVE=1 alone suppresses the croak
{
	local $ENV{HARNESS_ACTIVE} = 1;
	lives_ok { $p->fly } 'HARNESS_ACTIVE=1 suppresses the abstract croak';
}

# Confirm HARNESS_ACTIVE scope restored
throws_ok { $p->fly }
	qr/abstract method/,
	'HARNESS_ACTIVE restored to 0 after scope exits';

# harness_bypass=0 disables the HARNESS_ACTIVE shortcut
{
	local $ENV{HARNESS_ACTIVE}                 = 1;
	local $Sub::Abstract::config{harness_bypass} = 0;
	throws_ok { $p->fly }
		qr/abstract method/,
		'harness_bypass=0 re-enables enforcement even when HARNESS_ACTIVE=1';
}

done_testing;
