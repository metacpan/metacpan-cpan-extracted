use Test::More;

use Module::Generate::Hash qw/all/;
BEGIN {
generate(
	lib => './t/lib',
	author => 'LNATION',
	email => 'email@lnation.org',
	version => '0.01',
	classes => {
		Foo => {
			abstract => 'A Testing Module',
			our => '$one',
			begin => sub {
				$one = 'abc';
			},
			accessors => [
				'test',
				'testing'
			],
			subs => [
				one => {
					code => sub { $one }
				},
				name => {
					code => sub {
						$_[1] + $_[2];
					},
					pod => 'A Sub routine'
				},
				another => {
					code => sub {
						$_[2] - $_[1];
					},
					pod => 'Another Sub'
				}
			],
			subclass => {
				Bar => {
					abstract => 'A Testing Module',
					subs => [
						different => {
							code => sub {
								$_[1] + $_[2]
							},
							pod => 'A Sub routine',
							example => '$foo->different(10, 10)'
						},
						another => {
							code => sub {
								$_[2] - $_[1];
							},
							pod => 'Another Sub'
						}
					]		
				}
			}
		}
	}
);
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
is($bar->test, undef);
ok($bar->test('abc'));
is($bar->test, 'abc');

ok(1, 'RUN');

done_testing;
