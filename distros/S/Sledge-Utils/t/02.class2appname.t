use strict;
use warnings;
use Test::Base;
use Sledge::Utils;

sub class2appclass {
    Sledge::Utils::class2appclass(@_);
}

run_is 'input' => 'expected';

__END__

=== Boofy::Pages::Foo
--- input class2appclass: Boofy::Pages::Foo
--- expected: Boofy

=== Boofy::Pages
--- input class2appclass: Boofy::Pages
--- expected: Boofy

=== Boo::Fy::Pages::Foo::Bar
--- input class2appclass: Boo::Fy::Pages::Foo::Bar
--- expected: Boo::Fy
