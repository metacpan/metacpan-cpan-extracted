use strict;
use warnings;
use Test::More;

use Zydeco::Lite;

my $app = app sub {
	class 'Foobar' => sub {
		with role sub {
			method 'foo' => sub { 'FOO' };
		};
		with role sub {
			after_apply {
				method 'bar' => sub { 'BAR' };
			};
		};
		with role sub {
			before_apply {
				method 'baz' => sub { 'BAZ' };
			};
			with role sub {
				after_apply {
					method 'quux' => sub { 'QUUUX' }
						if $_[2] eq 'class';
				};
			};
		};
	};
};

my $o = $app->new_foobar;
is( $o->foo,  'FOO'   );
is( $o->bar,  'BAR'   );
is( $o->baz,  'BAZ'   );
is( $o->quux, 'QUUUX' );
done_testing;
