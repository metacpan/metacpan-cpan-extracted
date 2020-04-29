use Test::More;

BEGIN {
	use Module::Generate;

	Module::Generate->lib('./t/lib')
		->author('LNATION')
		->email('email@lnation.org')
		->version('0.01')
		->class('Foo')
			->abstract('A Testing Module')
			->our('$one')
			->begin(sub {
				$one = 'abc';
			})
			->new
			->accessor('test')
			->accessor('testing')
			->sub('one')
				->code(sub { $one } )
			->sub('name')
				->code(sub {
					$_[1] + $_[2];
				})->pod('A Sub routine')
			->sub('another')
				->code(sub {
					$_[2] - $_[1];
				})->pod('Another Sub')
		->class('Foo::Bar')
			->abstract('A Testing Module')
			->base('Foo')
			->sub('different')
				->code(sub {
					$_[1] + $_[2];
				})
				->pod('A Sub routine')
				->example('$foo->different(10, 10)')
			->sub('another')
				->code(sub {
					$_[2] - $_[1];
				})->pod('Another Sub')
	->generate;
	ok(1, 'GENERATE');
}

use lib 't/lib';
use Foo;

my $foo = Foo->new;

is($foo->one, 'abc');
is($foo->name(10, 10), 20);
is($foo->test, undef);
ok($foo->test('abc'));
is($foo->test, 'abc');

use Foo::Bar;

my $bar = Foo::Bar->new;

is($bar->one, 'abc');
is($bar->name(10, 10), 20);
is($bar->different(10, 10), 20);
ok(1, 'RUN');

done_testing;
