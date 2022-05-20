use Test::More;

BEGIN {
	*CORE::GLOBAL::open = sub (*;$@) {
		return 0;
	};
	*CORE::GLOBAL::mkdir = sub {
		return 0;
	};

}

use Module::Generate;

subtest '_make_path' => sub {
	rmdir('./t/lib/path');
	eval { Module::Generate::_make_path('./t/lib/unable/path') };
	like($@, qr/Cannot open file/);
};

subtest 'generate' => sub {
	%Module::Generate::CLASS = ();
	eval { 
		Module::Generate->lib('./t/lib/unable')
			->author('LNATION')
			->email('email@lnation.org')
			->version('0.01')
			->macro('self', sub {
				my ($self, $value) = @_;
			})
			->class('Foo')
				->abstract('A Testing Module')
				->our('$one')
				->begin(sub {
					$one = 'abc';
				})
				->new
		->generate;
	};
	like($@, qr/Cannot open file/);
};

subtest 'generate_tlib' => sub {
	eval { 
		Module::Generate::_generate_tlib('Foo', './t/');
	};
	like($@, qr/Cannot open file/);
};



done_testing;
