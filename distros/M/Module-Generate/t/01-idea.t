use Test::More;

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
		->sub('new')
			->code(sub { return bless {}, $_[0] })
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

ok(1);

done_testing;
