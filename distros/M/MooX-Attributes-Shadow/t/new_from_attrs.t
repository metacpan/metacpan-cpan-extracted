#!perl

use strict;
use warnings;

use Test::More;
use Test::Deep;

use lib 't';
use MooX::Attributes::Shadow ':all';

{
    package Foo;

    use Moo;
    use ContainedWRole;

    ContainedWRole->shadow_attrs( fmt => sub { 'x' . shift }  );
    ContainedWRole->shadow_attrs( fmt => sub { 'x1' . shift }, instance => 1  );
    ContainedWRole->shadow_attrs( fmt => sub { 'x2' . shift }, instance => 2  );
    ContainedWRole->shadow_attrs( fmt => sub { 'x3' . shift }, instance => 3  );

    has foo => (
        is      => 'ro',
        default => sub { [ ContainedWRole->new( ContainedWRole->xtract_attrs( $_[0] ) ),
			   ContainedWRole->new_from_attrs( $_[0] ),
			   ContainedWRole->new_from_attrs( $_[0], b => 5 ),
			   ContainedWRole->new_from_attrs( $_[0], { instance => 1 } ),
			   ContainedWRole->new_from_attrs( $_[0], { instance => 2 }, { b => 3 } ),
			   ContainedWRole->new_from_attrs( $_[0], { instance => 3 }, b => 4 ),
			 ] },
    );

}

my $bar = Foo->new( xa  => 1,  xb => 2,
		    x1a => 3, x1b => 4,
		    x2a => 5, x2b => 6,
		    x3a => 7, x3b => 8,
		  );

my @testdata = (
		{ a => 1, b => 2 },
		{ a => 1, b => 2 },
		{ a => 1, b => 5 },
		{ a => 3, b => 4 },
		{ a => 5, b => 3 },
		{ a => 7, b => 4 },
);

for my $idx ( 0..$#testdata ) {

    my $foo = $bar->foo->[$idx];

    is_deeply ( { a => $foo->a, b => $foo->b }, $testdata[$idx], "idx $idx" );

}


done_testing;
