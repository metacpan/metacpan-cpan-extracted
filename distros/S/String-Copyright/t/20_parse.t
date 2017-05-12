use strict;
use warnings;
use utf8;

use Test::More tests => 9;

use String::Copyright;
use String::Copyright { threshold_before => 0 },
	'copyright' => { -as => 'before0' };
use String::Copyright { threshold_before => 1 },
	'copyright' => { -as => 'before1' };
use String::Copyright { threshold_before => 2 },
	'copyright' => { -as => 'before2' };
use String::Copyright { threshold_after => 0 },
	'copyright' => { -as => 'after0' };
use String::Copyright { threshold_after => 1 },
	'copyright' => { -as => 'after1' };
use String::Copyright { threshold_after => 2 },
	'copyright' => { -as => 'after2' };

#is( ( 0 + copyright( "foo" ) ), 0, 'non-copyright string numeric is zero' );

my $string = "© Foo\n© Bar\n\n© Baz\n\n\n© Boom";

is_deeply copyright($string), "© Foo\n© Bar\n© Baz\n© Boom", 'no skip';

is_deeply before0("\n\n\n\n$string"),
	"© Foo\n© Bar\n© Baz\n© Boom", 'zero skip before match';
is_deeply before1($string), "© Foo\n© Bar\n© Baz\n© Boom",
	'skip before match and 1 miss';
is_deeply before1("\n$string"), "", 'skip before match and 1 miss, skipped';
is_deeply before2("\n$string"), "© Foo\n© Bar\n© Baz\n© Boom",
	'skip before match and 2 misses';
is_deeply before2("\n\n$string"), "",
	'skip before match and 2 misses, skipped';

is_deeply after0($string), "© Foo\n© Bar\n© Baz\n© Boom",
	'zero skip after match';
is_deeply after1($string), "© Foo\n© Bar", 'skip after match and 1 miss';
is_deeply after2($string),
	"© Foo\n© Bar\n© Baz", 'skip after match and 2 misses';
