#!perl

use strict;
use warnings;

use Test::More tests => 38;


BEGIN{ require_ok('Module::Pragma') };

BEGIN{
	package test;
	use base qw(Module::Pragma);

	__PACKAGE__->register_tags( reverse 'a' .. 'e' );
	__PACKAGE__->register_tags( 'f' );
	__PACKAGE__->register_tags( __hidden => 0 );

	__PACKAGE__->register_exclusive('a', 'e');

	__PACKAGE__->register_bundle( set =>'a' .. 'd' );
}

ok !eval{ test->register_tags('___'); 1 }, 'not a valid tag name';
ok !eval{ test->import(); 1 }, 'requires explicit arguments';

is_deeply([sort test->tags], [sort 'a' .. 'f'], "register() and tags()");
is( test->tag('a'), 16, 'registered tag (a)');
is( test->tag('b'),  8, 'registered tag (b)');
is( test->tag('c'),  4, 'registered tag (c)');
is( test->tag('d'),  2, 'registered tag (d)');
is( test->tag('e'),  1, 'registered tag (e)');
is( test->tag('f'), 32, 'registered tag (f)');
is( test->tag('__hidden'), 0, 'registered tag(__hidden)');

ok !eval{ test->tag('g'); 1 }, 'unregistered tag';
like $@, qr/unknown subpragma/;


BEGIN{
	package empty;
	use base qw(Module::Pragma);
	sub unknown_tag{ 0 }
}

is_deeply([ empty->tags ], []);
is(empty->tag('a'), 0);
is(empty->tag('b'), 0);
is_deeply([ empty->enabled ], []);
is_deeply([ empty->exclusive_tags('a') ], []);


is( test->pack_tags('a'),        0b010000 , "pack_tags(a)");
is( test->pack_tags('a', 'b'),   0b011000,  "pack_tags(a, b)");
is( test->pack_tags('e','c','a'),0b010101,  "pack_tags(e, c, a)");
is( test->pack_tags(test->tags), 0b111111,  "pack_tags(a, b, c, d, e)");
is( test->pack_tags(':set'),     0b011110 , "pack_tags(:set)");

ok !eval{ test->pack_tags('foo') }, "unregistered subpragma";
like $@, qr/unknown subpragma/;

is_deeply( [test->unpack_tags( 0 )], [],                                           "unpack_tags(0)");
is_deeply( [test->unpack_tags( test->tag('a') )], ['a'],                           "unpack_tags(..)");
is_deeply( [sort test->unpack_tags( test->pack_tags('a', 'b') )], [sort 'a', 'b'], "unpack_tags(..)");


is_deeply [test->exclusive_tags('a')],    ['e'], 'exclusive';
is_deeply [test->exclusive_tags('e')],    ['a'], 'exclusive';
is_deeply [test->exclusive_tags('b')],    [];
is_deeply [test->exclusive_tags(':set')], ['e'], 'exclusive :set';


{
	package extest;
	use base qw(Module::Pragma);

	__PACKAGE__->register_tags(-zero => 0, -foo, -bar, -baz);
	__PACKAGE__->register_exclusive( __PACKAGE__->tags );

}

is_deeply [sort extest->tags], [sort -zero, -foo, -bar, -baz], "non ascii tag names";
is(extest->tag(-foo), 1);

is_deeply([extest->unpack_tags(0)], [-zero], 'unpack_tags(0) -> -zero');
is_deeply([extest->exclusive_tags(-zero)], [-foo, -bar, -baz], 'exclusive_tags(-zero)');

{
	package overflow_test;
	use base qw(Module::Pragma);

	sub unknown_tag{
		my($class, $tag) = @_;

		return $class->register_tags($tag);
	}
}

ok !eval{
	foreach my $symbol('AA' .. 'ZZ'){
		my $bitmask = overflow_test->tag($symbol);

		#diag($symbol . "=>" . sprintf '%064b', overflow_test->tag($symbol));
	}
	1;
}, 'must be overflowed';
like $@, qr/overflowed/;

# DEBUG INFORMATION
if(Module::Pragma->can('_dump')){
	diag(Module::Pragma->_dump);
}

#EOF
