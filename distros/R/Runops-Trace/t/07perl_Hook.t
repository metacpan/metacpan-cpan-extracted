#!perl

use strict;
use warnings;

use Runops::Trace;
use Test::More 'no_plan';

use Scalar::Util qw(refaddr);

my ( $called, @ops, @refgen_args, @aassign_args );

Runops::Trace::set_tracer(sub {
	my ( $op, $arity, @args ) = @_;

	$called++;

	if ( $op->name eq 'refgen' and @refgen_args < 2 ) {
		push @refgen_args, [ @args ];
	} elsif ( $op->name eq 'aassign' ) {
		push @aassign_args, [ @args ];
	}

	push @ops, $op;
});

my $i;
++$i;

sub foo { sub { $i } };
sub bar { sub { $i } };

Runops::Trace::enable_tracing();

++$i;
my $j = $i + 42;

my $y = 101;
my ( $x, @refs ) = \( $y, [qw/dancing hippies/], 33, \&foo );

$i ? foo() : bar();

if ( foo() || 1 ) {
	$j = "" . $i;
}

Runops::Trace::disable_tracing();

++$i;

is( $i, 3, "ops dispatched" );
ok( $called, "hook called" );
ok( scalar(@ops), "cought some ops" );

my %seen_names;
foreach my $op ( @ops ) {
	isa_ok( $op, "B::OP" );
	$seen_names{$op->name}++;
}

foreach my $opname (qw(
	nextstate
	preinc add
	entersub leavesub
	refgen sassign aassign
	padsv padav gv
	cond_expr and or
	const
	anonlist
	concat
)) {
	ok( $seen_names{$opname}, "$opname op seen by hook" );
}

is_deeply( \@refgen_args, [ [ \&foo ], [ $x, @refs ] ], "listop arg capture" );

is( refaddr($refgen_args[1][0]), refaddr($x), "aliasing semantics" );

is_deeply(
	\@aassign_args,
	[[
		[ \$x, \@refs ],   # two lvalues
		[ \$x, \(@refs) ], # four rvalues, passed to the hook by ref
	]],
	"aassign",
);

