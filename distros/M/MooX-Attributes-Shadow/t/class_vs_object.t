#!perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Exception;

use lib 't';
use MooX::Attributes::Shadow ':all';

{
    package Foo;

    use Moo;

    use ContainedWRole;
    use MooX::Attributes::Shadow ':all';

    ContainedWRole->shadow_attrs( fmt => sub { 'x' . shift }  );
    ContainedWRole->shadow_attrs( fmt => sub { 'x1' . shift }, instance => 1  );

    has foo => (
        is      => 'ro',
        default => sub { [ ContainedWRole->new( ContainedWRole->xtract_attrs( $_[0] ) ),
			   ContainedWRole->new( ContainedWRole->xtract_attrs( $_[0], instance => 1 ) )
			 ] },
    );

    has attrs => (
        is => 'ro',
        default => sub { [ ContainedWRole->shadowed_attrs,
			   ContainedWRole->shadowed_attrs( { instance => 1 } ) ] },
   );

}

my $bar = Foo->new( xa => 1, xb => 2, x1a => 3, x1b => 4 );
is_deeply( { xtract_attrs( ContainedWRole => $bar ) }, { a => 1, b => 2 }, 'extract: class' );
is_deeply( { xtract_attrs( $bar->foo->[0] => $bar ) }, { a => 1, b => 2 }, 'extract: object' );

is_deeply( { xtract_attrs( ContainedWRole => $bar, { instance => 1 } ) }, { a => 3, b => 4 }, 'extract: class instance 1' );
is_deeply( { xtract_attrs( $bar->foo->[1] => $bar, { instance => 1 } ) }, { a => 3, b => 4 }, 'extract: object instance 1' );


for my $setup ( { attrs => { 'xa' => 'a', 'xb' => 'b' },
		  idx => 0 },
		{ attrs => { 'x1a' => 'a', 'x1b' => 'b' },
		  idx => 1,
		  instance => 1
		},
	      ) {

    my $args = exists $setup->{instance} ? { instance => $setup->{instance} } : {} ;


    is_deeply( $bar->attrs->[$setup->{idx}], $setup->{attrs}, join( ' ', 'shadowed: implicit __PACKAGE__', %{$args} ) );

    is_deeply( shadowed_attrs( 'ContainedWRole', 'Foo', $args ) , $setup->{attrs}, join( ' ', 'shadowed: class, class', %{$args} ) );
    is_deeply( shadowed_attrs( 'ContainedWRole', $bar, $args )  , $setup->{attrs}, join( ' ', 'shadowed: class, object', %{$args} ) );
    is_deeply( shadowed_attrs( $bar->foo->[$setup->{idx}], $bar, $args )         , $setup->{attrs}, join( ' ', 'shadowed: object, object', %{$args} ) );

}

throws_ok{ xtract_attrs( 'ContainedWRole', 'a' ) } qr/not a container object/, "xtract_attrs: container_object";

done_testing;
