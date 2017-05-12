#!perl

use strict;
use warnings;

use SUPER;
use Test::More tests => 6;

# RT #21491 - weird class names
{

	package Pirate;
	sub chumbucket { return 'Ahoy!'; }
	sub four_bells { return 'Belay that order!'; }
	sub keelhaul   { return 'Rub some salt into it, ye scurvy dog.'; }
}

{
	# The '...' class has a method named 'chumbucket' and inherits from
	# Pirate.
	no strict 'refs';
	*{'...::chumbucket'} = sub { local *__ANON__ = 'chumbucket'; $_[0]->SUPER };
	@{'...::ISA'}        = 'Pirate';

	my $obj = bless [], '...';
	eval { is( $obj->chumbucket, Pirate->chumbucket, "Class '...'" ) };
	fail( "Class '...' ($@)" ) if $@;
}

{
	no strict 'refs';
	*{"\n::four_bells"} = sub { local *__ANON__ = 'four_bells'; $_[0]->SUPER };
	@{"\n::ISA"}        = 'Pirate';

	my $obj = bless [], "\n";
	eval { is( $obj->four_bells, Pirate->four_bells, "Class '\\n'" ); };
	fail( "Class '' ($@)" ) if $@;
}

{
	no strict 'refs';

	*{'0::keelhaul'} = sub { local *__ANON__ = 'keelhaul'; $_[0]->SUPER };
	@{'0::ISA'}      = 'Pirate';

	my $obj = bless [], '0';
	eval { is( $obj->keelhaul, Pirate->keelhaul, "Class '0'" ); };
	fail( "Class '0' ($@)" ) if $@;
}

# RT #21644 - poor recursion handling
package Mars;

sub rock_out { return 'Rrraaawwwr!'; }

package Venus;

use SUPER;
use warnings FATAL => 'recursion';

@Venus::ISA = 'Mars';

# A generic constructor.
sub new { return bless [], shift }

sub can
{
	my $obj = shift;

	# Delegate and make sure that accidental infinite
	# recursion is deadly for purposes of these tests.

	return $obj->SUPER( @_ );
}

package main;

my $obj = Venus->new();
my $out = eval { $obj->can('rock_out') };
ok( ! $@, 'No deep recursion' ) or diag( "Exception: '$@'" );
eval { is( Venus->can('rock_out'), \&Mars::rock_out, '$Class->can worked' ); };
fail('$Class->can failed') if $@;
is( $obj->rock_out, $out->(), '... and should get to right method' );
