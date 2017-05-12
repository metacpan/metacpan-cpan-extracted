#!perl
use warnings;
use strict;
use Data::Dumper;
use Test::More tests => 28;

# test of the TALES parser - parsing strings of various forms into the
# right thing.

use Template::TAL::ValueParser;
use Template::TAL::Language::TALES;

my $test = {
  'simple' => ['simple'],
  'two; elements' => ['two','elements'],
  'there ; are ; many ; elements' => ['there','are','many','elements'],
  'escaped;; semi; colons' => ['escaped; semi', 'colons'],
};

is_deeply( [ Template::TAL::ValueParser->split($_) ], $test->{$_}, $_ ) for keys %$test;

# test object
package MyTest;
sub zombie { "brains" }
package main;

my $data = [{
  foo => 1,
  bar => [ 1,2,3 ],
  baz => { one => 1, two => 2, three => 3 },
  monster => bless({}, "MyTest"),
  false => 0,
  utf8 => "\x{e9}",
}];

my $plugins = [ Template::TAL::Language::TALES->new ];

# simple success cases
is( Template::TAL::Language::TALES->process_tales_path("foo", $data), 1, "single element" );
is( Template::TAL::Language::TALES->process_tales_path("bar/0", $data), 1, "array referencing" );
is( Template::TAL::Language::TALES->process_tales_path("bar/1", $data), 2, "array referencing" );
is( Template::TAL::Language::TALES->process_tales_path("bar/2", $data), 3, "array referencing" );
is( Template::TAL::Language::TALES->process_tales_path("baz/one", $data), 1, "hash referencing" );
is( Template::TAL::Language::TALES->process_tales_path("baz/three", $data), 3, "hash referencing" );

is( Template::TAL::Language::TALES->process_tales_path("utf8", $data), "\x{e9}", "utf8");

is_deeply( Template::TAL::Language::TALES->process_tales_path("bar", $data), [1,2,3], "can ask for array");

# failure cases
is( Template::TAL::Language::TALES->process_tales_path("banana", $data), undef, "missing element" );
is( Template::TAL::Language::TALES->process_tales_path("foo/banana", $data), undef, "can't walk a scalar" );
is( Template::TAL::Language::TALES->process_tales_path("bar/8", $data), undef, "missing key" );
is( Template::TAL::Language::TALES->process_tales_path("bar/foo", $data), undef, "non-int key" );

# interesting cases
is( Template::TAL::Language::TALES->process_tales_path("ape | foo", $data), 1, "fallback" );
is( Template::TAL::Language::TALES->process_tales_path("monster/zombie", $data), "brains", "method calls" );


is( Template::TAL::ValueParser->value("string:foo", $data, $plugins), 'foo' );
is( Template::TAL::ValueParser->value("string:foo bar baz", $data, $plugins), 'foo bar baz' );
is( Template::TAL::ValueParser->value("string:Hello, this is a 'nasty' string.", $data, $plugins), "Hello, this is a 'nasty' string." );

is( Template::TAL::ValueParser->value("foo", $data, $plugins), '1' );
is( Template::TAL::ValueParser->value("path:foo", $data, $plugins), '1' );

ok( ! Template::TAL::ValueParser->value("not:foo", $data, $plugins) );
ok(   Template::TAL::ValueParser->value("not:false", $data, $plugins) );


is( Template::TAL::ValueParser->value('string: hello $foo', $data, $plugins), 'hello 1' );
is( Template::TAL::ValueParser->value('string: hello ${foo}', $data, $plugins), 'hello 1' );
is( Template::TAL::ValueParser->value('string: hello ${bar/2}', $data, $plugins), 'hello 3' );

# TODO - do we not test context fallback?
# TODO - test plugins
