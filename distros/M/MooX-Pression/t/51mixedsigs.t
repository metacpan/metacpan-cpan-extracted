use strict;
use warnings;
use Test::More;
use Test::Requires { 'Type::Params' => '1.009002' };
use Test::Requires { 'MooX::Press' => '0.042' };

package MyApp {
	use MooX::Pression;
	
	class Foo {
		my $Int = Int->plus_coercions(Num, q[int $_]);
		
		method bar1 ({$Int} $x, ArrayRef $y, HashRef *n1, ScalarRef *n2?, CodeRef $z) {
			return [ $x, $y, $arg->n1, $arg->n2, $z ];
		}
		method bar2 :optimize ({$Int} $x, ArrayRef $y, HashRef *n1, ScalarRef *n2?, CodeRef $z) {
			return [ $x, $y, $arg->n1, $arg->n2, $z ];
		}
	}
}

my $obj = MyApp->new_foo;
my $coderef = $obj->can('new');

for my $method (qw/ bar1 bar2 /) {
	is_deeply(
		$obj->$method(1.1, ['c'], n1=>{foo=>42}, n2=>\42, $coderef),
		[1, ['c'], {foo=>42}, \42, $coderef],
	);
}

#use B::Deparse;
#note( B::Deparse->new->coderef2text(\&MyApp::Foo::bar2) );

done_testing;
