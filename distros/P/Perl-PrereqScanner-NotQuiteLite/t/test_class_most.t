use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Test::More;
use t::Util;

# taken from Test::Class::Most pod
test('parent with a package', <<'END', {'Test::Class::Most' => 0, 'Tests::For::Foo' => 0});
package Tests::For::Foo::Child;
use Test::Class::Most parent => 'Tests::For::Foo';
END

test('parent with packages', <<'END', {'Test::Class::Most' => 0, 'Tests::For::Foo' => 0, 'Tests::For::Bar' => 0, 'Some::Other::Class::For::Increased::Stupidity' => 0});
package Tests::For::ISuckAtOO;
use Test::Class::Most parent => [qw/
   Tests::For::Foo
   Tests::For::Bar
   Some::Other::Class::For::Increased::Stupidity
/];
END

test('with other options', <<'END', {'Test::Class::Most' => 0, 'My::Test::Class' => 0});
use Test::Class::Most 
   parent      => 'My::Test::Class',
   attributes  => [qw/customer items/],
   is_abstract => 1;
END

done_testing;
