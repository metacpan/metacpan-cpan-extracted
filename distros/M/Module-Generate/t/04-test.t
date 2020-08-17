use Test::More;

BEGIN {
	use Module::Generate;

	Module::Generate->lib('./t/lib')
		->tlib('./t/lib')
		->author('LNATION')
		->email('email@lnation.org')
		->version('0.01')
		->macro('self', sub {
			my ($self, $value) = @_;
		})
		->class('FooTest')
			->new
			->accessor('test')
				->example('')
			->accessor('testing')
			->sub('okay')->code(sub {
				my ($self, $value) = @_;
				if ($value eq 1) {
					return 'okay';
				}
				return $value;
			})->test(['is', '$obj->okay(1)', q|'okay'|], ['is', '$obj->okay(100)', 100])
	->generate;
	ok(1, 'GENERATE');
}

use lib 't/lib';
use FooTest;

my $foo = FooTest->new;

is($foo->test, undef);

my $lame = 't/lib/FooTest.t';
open my $fh, '<', $lame;
my $content  = do { local $/; <$fh> };
close $fh;
eval $content;

