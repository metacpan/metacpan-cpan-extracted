use strict;
use warnings;
use Test::Base;
use Sledge::Utils;

sub class2prefix {
    Sledge::Utils::class2prefix(@_);
}

run_is 'input' => 'expected';

__END__

=== Pages::Foo
--- input class2prefix: Proj::Pages::Foo
--- expected: /foo

=== Pages::Foo::Bar
--- input class2prefix: Proj::Pages::Foo::Bar
--- expected: /foo/bar

=== Pages::FooBar::Baz
--- input class2prefix: Proj::Pages::FooBar::Baz
--- expected: /foo_bar/baz

=== Pages::Root
--- input class2prefix: Proj::Pages::Root
--- expected: /

=== Pages::Index
--- input class2prefix: Proj::Pages::Index
--- expected: /

