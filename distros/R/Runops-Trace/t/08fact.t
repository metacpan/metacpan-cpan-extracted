#!perl

use strict;
use warnings;

use Test::More qw(no_plan);
use Runops::Trace;

use B::Concise;

B::Concise::compile("fact")->();
B::Concise::compile(-exec => "fact")->();

sub fact {
	my $n = $_[0];

	if ( $n <= 1 ) {
		return $n;
	} else {
		return ( $n * fact($n - 1) );
	}
}

Runops::Trace::set_tracer(sub {
	my ( $op, $arity, @args ) = @_;

	#warn "op name: ", $op->name, "($$op) arity: ", $arity, " args: ", \@args;
	#use Devel::Peek;
	#Dump($_) for @args;
});

Runops::Trace::enable_tracing();

my $f = fact(3);

Runops::Trace::disable_tracing();

is( $f, 6 );
