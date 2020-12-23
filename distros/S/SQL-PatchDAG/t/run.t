#!/usr/bin/env perl
use strict; use warnings;

use Test::More tests => 21;
use SQL::PatchDAG;

my @arg;
$ENV{'EDITOR'} = 'false';

BEGIN {
	package Test::SQL::PatchDAG;
	our @ISA = 'SQL::PatchDAG';
	sub create { @arg = ( create => @_ ); $ENV{'EDITOR'}             ? die $_[0] : $_[1] }
	sub open   { @arg = ( open   => @_ ); __FILE__ eq +(caller 1)[1] ? die $_[0] : $_[1] }
	sub run    { @arg = (); defined eval { shift->SUPER::run( @_ ) } ? undef : $@ }
}

my $p = Test::SQL::PatchDAG->new;

for (
	[ ''   => ( 'create', $p, 'foo' ) ],
	[ '-e' => ( 'open',   $p, 'foo' ) ],
	[ '-r' => ( 'create', $p, 'foo', 'recreate' ) ],
) {
	my ( $switch, @expected ) = @$_;
	my @argv = ( $switch || (), 'foo' );
	is $p->run( @argv ), $p, "Successful invocation with qw( @argv )";
	is "@arg", "@expected", '... and create is called correctly';
}

my $um = "usage: $0 [ -r | -e ] <patchname>\n";

for my $argv (
	[qw( foo bar )],
	[qw( foo bar baz )],
	[qw( -e )],
	[qw( -r )],
	[qw( -x )],
	[qw( -yz )],
	[qw( -x foo )],
	[qw( -e -r foo )],
	[qw( -e -x foo )],
	[qw( -r -x foo )],
	[qw( -e foo bar )],
	[qw( -r foo bar )],
	[qw( -r -e foo bar )],
	[qw( -r -e -y -z foo bar )],
) {
	is $p->run( @$argv ), $um, "Usage message with qw( @$argv )";
}

{
	local $ENV{'EDITOR'};
	is $p->run( 'foo' ), "No editor to run, EDITOR environment variable unset\n",
		'Error message for missing EDITOR env var';
}
