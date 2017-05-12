#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use lib 't';

use Container2;


Container2::run_shadow_attrs( attrs => [ 'a' ],
			      private => 0,
			      instance => 0,
			      fmt => sub { shift() . '0' },
			    );

Container2::run_shadow_attrs( attrs => [ 'a' ],
			      private => 0,
			      instance => 1,
			      fmt => sub { shift() . '1' },
			    );


my $obj = Container2->new( a0 => 3, a1 => 4 );

is ( $obj->a0, 3, 'container attribute 0' );
is ( $obj->a1, 4, 'container attribute 1' );

is ( $obj->foo->[0]->a, 3, 'contained attribute 0' );
is ( $obj->foo->[1]->a, 4, 'contained attribute 1' );

done_testing;
