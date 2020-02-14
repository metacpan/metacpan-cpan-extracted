use strict;
use warnings;
use Test::More;
use Test::Fatal;

package MyApp
{
	use MooX::Pression;
	
	class Foo
	{
		method get_line (
			Str *foo?,
			Str *bar?,
			Str *baz?
		)
		{
			
			return __FILE__ . " line " . __LINE__;
			
		}
	}
}

note("Expected line 19!");
note(MyApp->new_foo->get_line);

note("Expected line 29!");
note(exception { MyApp->new_foo->get_line(bar=>undef) });

ok 1;

done_testing;