#!/usr/bin/env perl
use strict; use warnings;

use Test::More tests => 24;
use SQL::PatchDAG;

my ( @arg, @exec );
$ENV{'EDITOR'} = 'false';

BEGIN {
	package Test::SQL::PatchDAG;
	our @ISA = 'SQL::PatchDAG';
	sub create { @arg = ( create => @_ );   $_[1] }
	sub open   { @arg = ( open   => @_ ); ( $_[1], \*STDERR ) }
	sub run    { @arg = @exec = (); undef $@; eval { shift->SUPER::run( @_ ) } }
	sub _exec  { @exec = @_; 1 }
}

my $p = Test::SQL::PatchDAG->new;

for (
	[ [qw(    foo )] => ( 'create', $p, 'foo' ) ],
	[ [qw( -e foo )] => ( 'open',   $p, 'foo' ) ],
	[ [qw( -r foo )] => ( 'create', $p, 'foo', 'recreate' ) ],
) {
	my ( $argv, @expected ) = @$_;
	my $ok = defined $p->run( @$argv );
	is $@, '', "Successful invocation with qw( @$argv )";
	is "@arg", "@expected", "... and $expected[0] is called correctly";
	is "@exec", "$p $ENV{'EDITOR'} foo", "... resulting in the correct exec call";
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
	$p->run( @$argv );
	is $@, $um, "Usage message with qw( @$argv )";
}

{
	local $ENV{'EDITOR'};
	$p->run( 'foo' );
	is $@, "No editor to run, EDITOR environment variable unset\n",
		'Error message for missing EDITOR env var';
}
