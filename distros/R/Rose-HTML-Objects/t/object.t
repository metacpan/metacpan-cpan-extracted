#!/usr/bin/perl -w

use strict;

use Test::More tests => 241;

BEGIN { use_ok('Rose::HTML::Object') }

#
# Generic object stuff
#

my $o = Rose::HTML::Object->new('p');
ok(ref $o eq 'Rose::HTML::Object', 'new()');

$o->push_child('hello');

is($o->html, '<p>hello</p>', 'push_child 1');

$o->add_child("\n");

$o->add_children(Rose::HTML::Object->new(element => 'b', children => [ 'world' ]));

is($o->xhtml, "<p>hello\n<b>world</b></p>", 'add_children 1');

is($o->children->[0]->parent, $o, 'parent 1');
is($o->children->[2]->child(0)->parent, $o->children->[2], 'parent 2');

is(join(',', $o->descendants), join(',', $o->child(0), $o->child(1), $o->child(2),
                                         $o->child(2)->child(0)), 'descendants');

$o->delete_child(9999);
$o->delete_child(1);

is($o->html, "<p>hello<b>world</b></p>", 'delete_child 1');

my $o2 = Rose::HTML::Object->new('div');

$o->child(0)->parent($o2);

is($o->html, "<p><b>world</b></p>", 'parent 1');
is($o2->xhtml, '<div>hello</div>', 'parent 2');

$o->delete_children;

is(scalar @{ $o->children }, 0, 'children');

$o = Rose::HTML::Object->new;

is(scalar @{ $o->children }, 0, 'children scalar');
is(scalar(() = $o->children), 0, 'children list');

is($o->validate_html_attrs(0), 0, 'validate_html_attrs(0)');

$o->html_attr('name' => 'John');
is($o->html_attr('name'), 'John', 'html_attr() set/get');

ok($o->html_attr_exists('name'), 'html_attr_exists() basic');

$o->html_attr('age' => undef);
ok($o->html_attr_exists('age'), 'html_attr_exists() undef');

$o->delete_html_attr('age');
ok(!$o->html_attr_exists('age'), 'html_attr_exists() false');

$o->html_attrs({ name => 'John', age => 27 });
ok($o->html_attr_exists('name') && $o->html_attr('name') eq 'John' &&
   $o->html_attr_exists('age') && $o->html_attr('age') == 27,
   'html_attrs()');

is($o->html_attrs_string, ' age="27" name="John"', 'html_attrs_string() 1');

$o->set_error;
ok(defined $o->error && length $o->error == 0, 'set_error');

$o->unset_error;
ok(!defined $o->error, 'unset_error');

$o->error('Foo > bar');
is($o->error, 'Foo > bar', 'error()');

is($o->html_error, '<span class="error">Foo &gt; bar</span>', 'html_error()');
is($o->xhtml_error, '<span class="error">Foo &gt; bar</span>', 'xhtml_error()');

$o->escape_html(0);

is($o->html_error, '<span class="error">Foo > bar</span>', 'html_error()');
is($o->xhtml_error, '<span class="error">Foo > bar</span>', 'xhtml_error()');

$o->html_attr_hook('name' => sub 
{
  my($self) = shift;

  if(@_)
  {
    $self->html_attr('ucname' => uc $_);
  }

  return ucfirst $_;
});

$o->html_attr('name' => 'hello');

$o->add_class('foo');
is($o->html_attr('class'), 'foo', 'add_class() 1');

$o->add_class('foo');
is($o->html_attr('class'), 'foo', 'add_class() 2');

$o->add_class('bar');
is($o->html_attr('class'), 'foo bar', 'add_class() 3');

$o->add_classes('foo', 'bar', 'baz');
is($o->html_attr('class'), 'foo bar baz', 'add_class() 4');

$o->add_classes([ 'foo', 'blee', 'baz' ]);
is($o->html_attr('class'), 'foo bar baz blee', 'add_class() 5');

$o->delete_class('bar');
is($o->html_attr('class'), 'foo baz blee', 'delete_class() 1');

$o->delete_class('foo');
is($o->html_attr('class'), 'baz blee', 'delete_class() 2');

$o->delete_class('blee');
is($o->html_attr('class'), 'baz', 'delete_class() 3');

$o->class('  foo  bar baz blee   baz bar   ');

$o->delete_class('bar');
is($o->html_attr('class'), 'foo baz blee baz', 'delete_class() 4');

$o->delete_classes(qw(foo baz goo));
is($o->html_attr('class'), 'blee', 'delete_class() 5');

$o->class('foo bar  baz  baz bar');
$o->delete_classes([ qw(blee baz goo foo) ]);
is($o->html_attr('class'), 'bar bar', 'delete_class() 6');

$o->delete_classes([ qw(bar) ]);
is($o->html_attr('class'), '', 'delete_class() 7');

$o->delete_html_attr('class');

is($o->html_attr('name'), 'Hello', 'html_attr_hook() 1');
is($o->html_attr('ucname'), 'HELLO', 'html_attr_hook() 2');

is($o->html_attr_is_valid('foo'), 0, 'html_attr_is_valid() 1');
is($o->html_attr_is_valid('data-foo'), 1, 'html_attr_is_valid() 1.1');

is($o->validate_html_attrs(1), 1, 'validate_html_attrs(1)');
eval { $o->html_attr('foo') };
ok($@, 'validate_html_attrs 1');

$o->add_valid_html_attr('foo');

is($o->autoload_html_attr_methods, 1, 'autoload_html_attr_methods() 1');

is($o->autoload_html_attr_methods(0), 0, 'autoload_html_attr_methods() 2');

eval { $o->foo() };
ok($@, 'autoload_html_attr_methods() 3');

is($o->autoload_html_attr_methods(1), 1, 'autoload_html_attr_methods() 4');

is($o->foo(5), 5, 'AUTOLOAD HTML attribute');
ok(defined &Rose::HTML::Object::foo, 'autoload_html_attr_methods() 5');

ok($o->delete_html_attr('foo'), 'delete_html_attr() 1');

is($o->html_attr_is_valid('foo'), 1, 'html_attr_is_valid() 2');

eval { $o->html_attr('foo') };
ok(!$@, 'validate_html_attrs 2');

$o->delete_valid_html_attr('foo');
eval { $o->html_attr('foo') };
ok($@, 'validate_html_attrs 3');

$o->validate_html_attrs(0);

is($o->html_attr(bar => 'baz'), 'baz', 'validate_html_attrs 2');

is($o->delete_html_attr('name'), 1, 'delete_html_attr() 2');

is($o->html_attrs_string, ' age="27" bar="baz" ucname="HELLO"', 'delete_html_attr() 3');

$o->delete_html_attr_hook('name');

$o->html_attr(name => 'John');
$o->html_attr(color => 'red');

is($o->delete_html_attrs('name', 'age'), 2, 'delete_html_attrs() 1');

is($o->html_attrs_string, ' bar="baz" color="red" ucname="HELLO"', 'delete_html_attrs() 2');

$o->html_attr('data-bar' => 'goo');
is($o->html_attrs_string, ' bar="baz" color="red" data-bar="goo" ucname="HELLO"', 'data attributes 1');
$o->delete_html_attr('data-bar');

$o->clear_html_attr('bar');
my $names_str = join(' ', $o->html_attr_names);
is($names_str, 'bar color ucname', 'html_attr_names() 1');

$o->delete_html_attr('bar');
$names_str = join(' ', $o->html_attr_names);
is($names_str, 'color ucname', 'html_attr_names() 2');

my $names = $o->html_attr_names;
ok($names->[0] eq 'color' && $names->[1] eq 'ucname' && @$names == 2, 'html_attr_names() 3');

is($o->add_valid_html_attrs('bar', 'baz'), 2, 'add_valid_html_attrs() 1');

is($o->create_html_attr_methods(qw(bar baz)), 2, 'create_html_attr_methods() 1');

eval { $o->bar(5) };
ok(!$@, 'create_html_attr_methods() 2');

eval { $o->baz(6) };
ok(!$@, 'create_html_attr_methods() 3');

is($o->delete_valid_html_attrs(qw(baz bar blee)), 2, 'delete_valid_html_attrs() 2');

ok(!$o->html_attr_is_valid('bar'), 'delete_valid_html_attrs() 3');
ok(!$o->html_attr_is_valid('baz'), 'delete_valid_html_attrs() 4');
ok(!$o->html_attr_is_valid('blee'), 'delete_valid_html_attrs() 5');

is($o->validate_html_attrs(1), 1, 'validate_html_attrs(1) 2');

eval { $o->bar(5) };
ok($@, 'delete_valid_html_attrs() 6');

is($o->add_valid_html_attrs('name', 'age', 'color'), 3, 'add_valid_html_attrs() 2');

$o->html_attrs(name => 'John', age => 27, color => 'red');

$o->clear_all_html_attrs;

is($o->html_attrs_string, '', 'clear_all_html_attrs() 1');
is($o->add_required_html_attrs(qw(name age)), 2, 'add_required_html_attrs()');

is($o->default_html_attr_value(age => 25), 25, 'default_html_attr_value() 1');
is($o->html_attrs_string, ' age="25" name=""', 'default_html_attr_value() 2');
is($o->default_html_attr_value(age => undef), undef, 'default_html_attr_value() 3');

$o->color('blue');

is($o->html_attrs_string, ' age="" color="blue" name=""', 'clear_all_html_attrs()');

$o->delete_all_html_attrs;

is($o->html_attrs_string, ' age="" name=""', 'delete_all_html_attrs()');

my $b = $o->boolean_html_attrs;
ok(ref $b eq 'ARRAY' && @$b == 0, 'boolean_html_attrs() 1');

my @b = $o->boolean_html_attrs;
ok(@b == 0, 'boolean_html_attrs() 2');

is($o->add_boolean_html_attr('smart'), 1, 'add_boolean_html_attr1()');
is($o->add_boolean_html_attrs(qw(big tall)), 2, 'add_boolean_html_attrs()');

is(join(',', $o->boolean_html_attrs), 'big,smart,tall', 'boolean_html_attrs() 3');

is($o->html_attrs_string, ' age="" name=""', 'html_attrs_string() 2');

$o->big(0);
$o->smart('abc');

is($o->html_attrs_string, ' age="" name="" smart', 'html_attrs_string() 3');

$o->tall('');

is($o->html_attrs_string, ' age="" name="" smart', 'html_attrs_string() 4');

$o->tall(' ');

is($o->html_attrs_string, ' age="" name="" smart tall', 'html_attrs_string() 4');
is($o->xhtml_attrs_string, ' age="" name="" smart="smart" tall="tall"', 'xhtml_attrs_string() 1');

is($o->html_element('foo'), 'foo', 'html_element()');
is($o->xhtml_element('xfoo'), 'xfoo', 'xhtml_element()');

$o->is_self_closing(1);
is($o->html_tag, '<foo age="" name="" smart tall>', 'html_tag() 1');
$o->is_self_closing(0);
is($o->html_tag, '<foo age="" name="" smart tall></foo>', 'html_tag() 2');
$o->is_self_closing(1);
is($o->xhtml_tag, '<xfoo age="" name="" smart="smart" tall="tall" />', 'xhtml_tag()');
$o->is_self_closing(0);
is($o->xhtml_tag, '<xfoo age="" name="" smart="smart" tall="tall"></xfoo>', 'xhtml_tag()');

foreach my $attr (Rose::HTML::Object->valid_html_attrs)
{
  is(MySubObject->html_attr_is_valid($attr), 1, "html_attr_is_valid() inherited $attr");
}

Rose::HTML::Object->add_valid_html_attr('blargh');
is(MySubObject->html_attr_is_valid('blargh'), 1, 'html_attr_is_valid() inherited blargh 1');
is(MySubObject2->html_attr_is_valid('blargh'), 1, 'html_attr_is_valid() inherited blargh 2');

Rose::HTML::Object->delete_valid_html_attr('blargh');
is(MySubObject->html_attr_is_valid('blargh'), 0, 'html_attr_is_valid() inherited blargh 3');
is(MySubObject2->html_attr_is_valid('blargh'), 0, 'html_attr_is_valid() inherited blargh 4');

MySubObject->add_valid_html_attr('blargh');
is(Rose::HTML::Object->html_attr_is_valid('blargh'), 0, 'html_attr_is_valid() inherited blargh 5');
is(MySubObject2->html_attr_is_valid('blargh'), 0, 'html_attr_is_valid() inherited blargh 6');

MySubObject->delete_valid_html_attr('blargh');
is(MySubObject->html_attr_is_valid('blargh'), 0, 'html_attr_is_valid() inherited blargh 7');
is(MySubObject2->html_attr_is_valid('blargh'), 0, 'html_attr_is_valid() inherited blargh 8');
is(Rose::HTML::Object->html_attr_is_valid('blargh'), 0, 'html_attr_is_valid() inherited blargh 9');

Rose::HTML::Object->add_valid_html_attr('bloop');
is(MySubObject->html_attr_is_valid('bloop'), 1, 'html_attr_is_valid() inherited bloop 1');
is(MySubObject2->html_attr_is_valid('bloop'), 1, 'html_attr_is_valid() inherited bloop 2');
is(MySubObject3->html_attr_is_valid('bloop'), 1, 'html_attr_is_valid() inherited bloop 3');
is(Rose::HTML::Object->html_attr_is_valid('bloop'), 1, 'html_attr_is_valid() inherited bloop 4');

MySubObject->add_valid_html_attr('bloop');
is(MySubObject->html_attr_is_valid('bloop'), 1, 'html_attr_is_valid() inherited bloop 5');
is(MySubObject2->html_attr_is_valid('bloop'), 1, 'html_attr_is_valid() inherited bloop 6');
is(MySubObject3->html_attr_is_valid('bloop'), 1, 'html_attr_is_valid() inherited bloop 7');
is(Rose::HTML::Object->html_attr_is_valid('bloop'), 1, 'html_attr_is_valid() inherited bloop 8');

MySubObject2->add_valid_html_attr('bloop');
is(MySubObject->html_attr_is_valid('bloop'), 1, 'html_attr_is_valid() inherited bloop 9');
is(MySubObject2->html_attr_is_valid('bloop'), 1, 'html_attr_is_valid() inherited bloop 10');
is(MySubObject3->html_attr_is_valid('bloop'), 1, 'html_attr_is_valid() inherited bloop 11');
is(Rose::HTML::Object->html_attr_is_valid('bloop'), 1, 'html_attr_is_valid() inherited bloop 12');

MySubObject3->add_valid_html_attr('bloop');
is(MySubObject->html_attr_is_valid('bloop'), 1, 'html_attr_is_valid() inherited bloop 13');
is(MySubObject2->html_attr_is_valid('bloop'), 1, 'html_attr_is_valid() inherited bloop 14');
is(MySubObject3->html_attr_is_valid('bloop'), 1, 'html_attr_is_valid() inherited bloop 15');
is(Rose::HTML::Object->html_attr_is_valid('bloop'), 1, 'html_attr_is_valid() inherited bloop 16');

MySubObject->delete_valid_html_attr('bloop');
is(MySubObject->html_attr_is_valid('bloop'), 0, 'html_attr_is_valid() inherited bloop 17');
is(MySubObject2->html_attr_is_valid('bloop'), 1, 'html_attr_is_valid() inherited bloop 18');
is(MySubObject3->html_attr_is_valid('bloop'), 1, 'html_attr_is_valid() inherited bloop 19');
is(Rose::HTML::Object->html_attr_is_valid('bloop'), 1, 'html_attr_is_valid() inherited bloop 20');

MySubObject2->delete_valid_html_attr('bloop');
is(MySubObject->html_attr_is_valid('bloop'), 0, 'html_attr_is_valid() inherited bloop 21');
is(MySubObject2->html_attr_is_valid('bloop'), 0, 'html_attr_is_valid() inherited bloop 22');
is(MySubObject3->html_attr_is_valid('bloop'), 1, 'html_attr_is_valid() inherited bloop 23');
is(Rose::HTML::Object->html_attr_is_valid('bloop'), 1, 'html_attr_is_valid() inherited bloop 24');

Rose::HTML::Object->delete_valid_html_attr('bloop');
is(MySubObject->html_attr_is_valid('bloop'), 0, 'html_attr_is_valid() inherited bloop 25');
is(MySubObject2->html_attr_is_valid('bloop'), 0, 'html_attr_is_valid() inherited bloop 26');
is(MySubObject3->html_attr_is_valid('bloop'), 1, 'html_attr_is_valid() inherited bloop 27');
is(Rose::HTML::Object->html_attr_is_valid('bloop'), 0, 'html_attr_is_valid() inherited bloop 28');

Rose::HTML::Object->add_valid_html_attr('argh');
is(MySubObject->html_attr_is_valid('argh'), 1, 'html_attr_is_valid() inherited argh 1');
is(MySubObject2->html_attr_is_valid('argh'), 1, 'html_attr_is_valid() inherited argh 2');
is(MySubObject3->html_attr_is_valid('argh'), 1, 'html_attr_is_valid() inherited argh 3');
is(Rose::HTML::Object->html_attr_is_valid('argh'), 1, 'html_attr_is_valid() inherited argh 4');

MySubObject2->delete_valid_html_attr('argh');
is(MySubObject->html_attr_is_valid('argh'), 1, 'html_attr_is_valid() inherited argh 5');
is(MySubObject2->html_attr_is_valid('argh'), 0, 'html_attr_is_valid() inherited argh 6');
is(MySubObject3->html_attr_is_valid('argh'), 1, 'html_attr_is_valid() inherited argh 7');
is(Rose::HTML::Object->html_attr_is_valid('argh'), 1, 'html_attr_is_valid() inherited argh 8');

MySubObject->delete_valid_html_attr('argh');
is(MySubObject->html_attr_is_valid('argh'), 0, 'html_attr_is_valid() inherited argh 9');
is(MySubObject2->html_attr_is_valid('argh'), 0, 'html_attr_is_valid() inherited argh 10');
is(MySubObject3->html_attr_is_valid('argh'), 1, 'html_attr_is_valid() inherited argh 11');
is(Rose::HTML::Object->html_attr_is_valid('argh'), 1, 'html_attr_is_valid() inherited argh 12');

MySubObject2->inherit_valid_html_attr('argh');
is(MySubObject->html_attr_is_valid('argh'), 0, 'html_attr_is_valid() inherited argh 13');
is(MySubObject2->html_attr_is_valid('argh'), 1, 'html_attr_is_valid() inherited argh 14');
is(MySubObject3->html_attr_is_valid('argh'), 1, 'html_attr_is_valid() inherited argh 15');
is(Rose::HTML::Object->html_attr_is_valid('argh'), 1, 'html_attr_is_valid() inherited argh 16');

Rose::HTML::Object->add_boolean_html_attrs(qw(whee splurt foop));

foreach my $attr (Rose::HTML::Object->boolean_html_attrs)
{
  is(MySubObject->html_attr_is_boolean($attr), 1, "html_attr_is_boolean() inherited $attr");
  is(MySubObject->html_attr_is_valid($attr), 1, "html_attr_is_valid() inherited implied $attr");
}

Rose::HTML::Object->add_boolean_html_attr('whee');
is(MySubObject->html_attr_is_boolean('whee'), 1, 'html_attr_is_boolean() inherited whee 1');
is(MySubObject2->html_attr_is_boolean('whee'), 1, 'html_attr_is_boolean() inherited whee 2');

Rose::HTML::Object->delete_boolean_html_attr('whee');
is(MySubObject->html_attr_is_boolean('whee'), 0, 'html_attr_is_boolean() inherited whee 3');
is(MySubObject2->html_attr_is_boolean('whee'), 0, 'html_attr_is_boolean() inherited whee 4');

MySubObject->add_boolean_html_attr('whee');
is(Rose::HTML::Object->html_attr_is_boolean('whee'), 0, 'html_attr_is_boolean() inherited whee 5');
is(MySubObject2->html_attr_is_boolean('whee'), 0, 'html_attr_is_boolean() inherited whee 6');

MySubObject->delete_boolean_html_attr('whee');
is(MySubObject->html_attr_is_boolean('whee'), 0, 'html_attr_is_boolean() inherited whee 7');
is(MySubObject2->html_attr_is_boolean('whee'), 0, 'html_attr_is_boolean() inherited whee 8');
is(Rose::HTML::Object->html_attr_is_boolean('whee'), 0, 'html_attr_is_boolean() inherited whee 9');

Rose::HTML::Object->add_boolean_html_attr('splurt');
is(MySubObject->html_attr_is_boolean('splurt'), 1, 'html_attr_is_boolean() inherited splurt 1');
is(MySubObject2->html_attr_is_boolean('splurt'), 1, 'html_attr_is_boolean() inherited splurt 2');
is(MySubObject3->html_attr_is_boolean('splurt'), 1, 'html_attr_is_boolean() inherited splurt 3');
is(Rose::HTML::Object->html_attr_is_boolean('splurt'), 1, 'html_attr_is_boolean() inherited splurt 4');

MySubObject->add_boolean_html_attr('splurt');
is(MySubObject->html_attr_is_boolean('splurt'), 1, 'html_attr_is_boolean() inherited splurt 5');
is(MySubObject2->html_attr_is_boolean('splurt'), 1, 'html_attr_is_boolean() inherited splurt 6');
is(MySubObject3->html_attr_is_boolean('splurt'), 1, 'html_attr_is_boolean() inherited splurt 7');
is(Rose::HTML::Object->html_attr_is_boolean('splurt'), 1, 'html_attr_is_boolean() inherited splurt 8');

MySubObject2->add_boolean_html_attr('splurt');
is(MySubObject->html_attr_is_boolean('splurt'), 1, 'html_attr_is_boolean() inherited splurt 9');
is(MySubObject2->html_attr_is_boolean('splurt'), 1, 'html_attr_is_boolean() inherited splurt 10');
is(MySubObject3->html_attr_is_boolean('splurt'), 1, 'html_attr_is_boolean() inherited splurt 11');
is(Rose::HTML::Object->html_attr_is_boolean('splurt'), 1, 'html_attr_is_boolean() inherited splurt 12');

MySubObject3->add_boolean_html_attr('splurt');
is(MySubObject->html_attr_is_boolean('splurt'), 1, 'html_attr_is_boolean() inherited splurt 13');
is(MySubObject2->html_attr_is_boolean('splurt'), 1, 'html_attr_is_boolean() inherited splurt 14');
is(MySubObject3->html_attr_is_boolean('splurt'), 1, 'html_attr_is_boolean() inherited splurt 15');
is(Rose::HTML::Object->html_attr_is_boolean('splurt'), 1, 'html_attr_is_boolean() inherited splurt 16');

MySubObject->delete_boolean_html_attr('splurt');
is(MySubObject->html_attr_is_boolean('splurt'), 0, 'html_attr_is_boolean() inherited splurt 17');
is(MySubObject2->html_attr_is_boolean('splurt'), 1, 'html_attr_is_boolean() inherited splurt 18');
is(MySubObject3->html_attr_is_boolean('splurt'), 1, 'html_attr_is_boolean() inherited splurt 19');
is(Rose::HTML::Object->html_attr_is_boolean('splurt'), 1, 'html_attr_is_boolean() inherited splurt 20');

MySubObject2->delete_boolean_html_attr('splurt');
is(MySubObject->html_attr_is_boolean('splurt'), 0, 'html_attr_is_boolean() inherited splurt 21');
is(MySubObject2->html_attr_is_boolean('splurt'), 0, 'html_attr_is_boolean() inherited splurt 22');
is(MySubObject3->html_attr_is_boolean('splurt'), 1, 'html_attr_is_boolean() inherited splurt 23');
is(Rose::HTML::Object->html_attr_is_boolean('splurt'), 1, 'html_attr_is_boolean() inherited splurt 24');

Rose::HTML::Object->delete_boolean_html_attr('splurt');
is(MySubObject->html_attr_is_boolean('splurt'), 0, 'html_attr_is_boolean() inherited splurt 25');
is(MySubObject2->html_attr_is_boolean('splurt'), 0, 'html_attr_is_boolean() inherited splurt 26');
is(MySubObject3->html_attr_is_boolean('splurt'), 1, 'html_attr_is_boolean() inherited splurt 27');
is(Rose::HTML::Object->html_attr_is_boolean('splurt'), 0, 'html_attr_is_boolean() inherited splurt 28');

Rose::HTML::Object->add_boolean_html_attr('foop');
is(MySubObject->html_attr_is_boolean('foop'), 1, 'html_attr_is_boolean() inherited foop 1');
is(MySubObject2->html_attr_is_boolean('foop'), 1, 'html_attr_is_boolean() inherited foop 2');
is(MySubObject3->html_attr_is_boolean('foop'), 1, 'html_attr_is_boolean() inherited foop 3');
is(Rose::HTML::Object->html_attr_is_boolean('foop'), 1, 'html_attr_is_boolean() inherited foop 4');

MySubObject2->delete_boolean_html_attr('foop');
is(MySubObject->html_attr_is_boolean('foop'), 1, 'html_attr_is_boolean() inherited foop 5');
is(MySubObject2->html_attr_is_boolean('foop'), 0, 'html_attr_is_boolean() inherited foop 6');
is(MySubObject3->html_attr_is_boolean('foop'), 1, 'html_attr_is_boolean() inherited foop 7');
is(Rose::HTML::Object->html_attr_is_boolean('foop'), 1, 'html_attr_is_boolean() inherited foop 8');

MySubObject->delete_boolean_html_attr('foop');
is(MySubObject->html_attr_is_boolean('foop'), 0, 'html_attr_is_boolean() inherited foop 9');
is(MySubObject2->html_attr_is_boolean('foop'), 0, 'html_attr_is_boolean() inherited foop 10');
is(MySubObject3->html_attr_is_boolean('foop'), 1, 'html_attr_is_boolean() inherited foop 11');
is(Rose::HTML::Object->html_attr_is_boolean('foop'), 1, 'html_attr_is_boolean() inherited foop 12');

MySubObject2->inherit_boolean_html_attr('foop');
is(MySubObject->html_attr_is_boolean('foop'), 0, 'html_attr_is_boolean() inherited foop 13');
is(MySubObject2->html_attr_is_boolean('foop'), 1, 'html_attr_is_boolean() inherited foop 14');
is(MySubObject3->html_attr_is_boolean('foop'), 1, 'html_attr_is_boolean() inherited foop 15');
is(Rose::HTML::Object->html_attr_is_boolean('foop'), 1, 'html_attr_is_boolean() inherited foop 16');

MySubObject2->add_required_html_attr('foop');
MySubObject2->delete_valid_html_attr('foop');
is(MySubObject2->html_attr_is_boolean('foop'), 0, 'delete_valid_html_attr() 1');
is(MySubObject2->html_attr_is_required('foop'), 0, 'delete_valid_html_attr() 2');

BEGIN
{
  package MySubObject;
  our @ISA = qw(Rose::HTML::Object);

  package MySubObject2;
  our @ISA = qw(Rose::HTML::Object);

  package MySubObject3;
  our @ISA = qw(MySubObject2);
}
