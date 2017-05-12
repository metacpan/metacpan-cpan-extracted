use Modern::Perl;
use Test::More;
package main;

{
  package A::Hello;
  use Moo::Role;
  sub hello { "Hello" }
  1;
}

{
  package A1;
  use Moo;
  use MooX::Object::Pluggable -pluggable_options => { search_path => ["A"] }, -load_plugins => ["Hello"];
  1
}

{
  package B2;
  use Moo;
  use MooX::Object::Pluggable pluggable_options => { search_path => ["A"] }, load_plugins => ["Hello"];
  1;
}

{
  package C3;
  use Moo;

  use MooX 'Object::Pluggable' => { -pluggable_options => { search_path => ["A"] }, -load_plugins => ['Hello'] };

  1;
}

can_ok('A1', "load_plugin", "load_plugins", "loaded_plugins", "plugins");

can_ok('A1'->new, "hello");
can_ok('B2'->new, 'hello');
can_ok('C3'->new, 'hello');

done_testing;
