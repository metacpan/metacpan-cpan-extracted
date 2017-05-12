#!/usr/bin/perl -w

use strict;

use Test::More tests => 629;

BEGIN
{
  # Don't use Class::XSAccessor unless invoked from t/makemethods-xs.t
  # as indicated by magic (false) value 0, set in t/makemethods-xs.t
  unless(defined $ENV{'ROSE_OBJECT_NO_CLASS_XSACCESOR'})
  {
    $ENV{'ROSE_OBJECT_NO_CLASS_XSACCESOR'} = 1;
  }

  use_ok('Rose::Object');
  use_ok('Rose::Object::MakeMethods::Generic');
  use_ok('Rose::Class');
  use_ok('Rose::Class::MakeMethods::Generic');
  use_ok('Rose::Class::MakeMethods::Set');
}

my $p = Person->new() || ok(0);
ok(ref $p eq 'Person', 'Construct object (no init)');

##
## Object methods
##

#
# scalar
#

is($p->bar, undef, 'Get named attribute (scalar)');
is($p->bar('bar'), 'bar', 'Set named attribute 1 (scalar)');
is($p->bar, 'bar', 'Set named attribute 2 (scalar)');

#
# scalar --get_set_init
#

is($p->type, 'default', 'Get named attribute (scalar --get_set_init)');

$p->type('foo');
is($p->type, 'foo', 'Set named attribute (scalar --get_set_init)');

#
# boolean
#

$p->is_foo('foo');
is($p->is_foo, 1, 'Set named attribute (boolean) 1');

$p->is_foo('');
is($p->is_foo, 0, 'Set named attribute (boolean) 2');

$p->is_foo(0);
is($p->is_foo, 0, 'Set named attribute (boolean) 3');

is($p->is_valid, 1, 'Default value (boolean)');

is($p->def0, 0, 'Default value (0) (boolean)');

#
# boolean --get_set_init
#

is($p->is_def_foo, 1, 'Get named attribute (boolean --get_set_init)');

$p->is_def_foo(undef);
is($p->is_def_foo, 0, 'Set named attribute (boolean --get_set_init)');

#
# hash
#

ok(!defined $p->params, 'Get undefinied hash (hash)');

$p->params(a => 1, b => 2);

is($p->param('b'), 2, 'Get hash key (hash)');

my $h = $p->params;

ok(ref $h eq 'HASH' && $h->{'a'} == 1 && $h->{'b'} == 2, 'Get hash ref (hash --get-set_all)');

my %h = $p->params;

ok($h{'a'} == 1 && $h{'b'} == 2, 'Get hash (hash --get-set_all)');

$p->params({ c => 3, d => 4 });

ok(!$p->param_exists('a'), 'Check for key existence (hash --exists)');

is(join(',', sort $p->param_names), 'c,d', 'Get key names (hash --keys)');

is(join(',', sort $p->param_values), '3,4', 'Get key values (hash --values)');

$p->delete_param('c');

is(join(',', sort $p->param_names), 'd', 'Delete param (hash --delete)');

$p->param(f => 7, g => 8);

is(join(',', sort $p->param_values), '4,7,8', 'Add name/value pairs (hash)');

#
# hash --get_set_init_all
#

$h = $p->fhash;
ok(ref $h eq 'HASH' && $h->{'a'} == 1 && $h->{'b'} == 2, 'Get hash ref (hash --get-get_set_init_all)');
%h = $p->fhash;
ok($h{'a'} == 1 && $h{'b'} == 2, 'Get hash (hash --get-set_all)');

$p->fhash(c => 3, d => 4);

$h = $p->fhash;
ok(ref $h eq 'HASH' && $h->{'c'} == 3 && $h->{'d'} == 4, 'Get hash ref 2 (hash --get-get_set_init_all)');
%h = $p->fhash;
ok($h{'c'} == 3 && $h{'d'} == 4, 'Get hash 2 (hash --get-set_all)');

$p->fhash({ e => 5, f => 6 });

$h = $p->fhash;
ok(ref $h eq 'HASH' && $h->{'e'} == 5 && $h->{'f'} == 6, 'Get hash ref 3 (hash --get-get_set_init_all)');
%h = $p->fhash;
ok($h{'e'} == 5 && $h{'f'} == 6, 'Get hash 3 (hash --get-set_all)');

#
# hash --get_set_init
#

my $ip = $p->iparams;

ok(ref $ip eq 'HASH' && $ip->{'a'} == 1 && $ip->{'b'} == 2,
   'Get default hash - hash ref (hash --get_set_init)');

$p->iparams({ c => 3, d => 4 });

my %ip = $p->iparams;

ok(keys %ip == 2 && $ip{'c'} == 3 && $ip{'d'} == 4,
   'Set hash - hash ref (hash --get_set_init)');

$p->clear_iparams();

%ip = $p->iparams;

ok(!keys %ip, 'Clear hash (hash --get_set_init)');

$p->reset_iparams();

%ip = $p->iparams;

ok(keys %ip == 2 && $ip{'a'} == 1 && $ip{'b'} == 2,
   'Get default hash - hash (hash --get_set_init)');

$p->iparams(c => 3, d => 4);

$ip = $p->iparams;

ok(ref $ip eq 'HASH' && $ip->{'c'} == 3 && $ip->{'d'} == 4,
   'Set  hash - hash (hash --get_set_inited)');

my $p2 = Person->new();

is($p2->iparams('b'), 2, 'Init on key request (hash --get_set_inited)');

#
# hash --get_set_inited
#

$ip = $p->idparams;

ok(ref $ip eq 'HASH' && !keys %$ip,
   'Get empty hash - scalar (hash --get_set_inited)');

$p->idparams({ c => 3, d => 4 });

%ip = $p->idparams;

ok(keys %ip == 2 && $ip{'c'} == 3 && $ip{'d'} == 4,
   'Set hash - hash ref (hash --get_set_inited)');

$p->clear_idparams();

%ip = $p->idparams;

ok(!keys %ip, 'Get empty hash - list (hash --get_set_inited)');

$p->idparams(c => 3, d => 4);

$ip = $p->idparams;

ok(ref $ip eq 'HASH' && $ip->{'c'} == 3 && $ip->{'d'} == 4,
   'Set  hash - hash (hash --get_set_inited)');

#
# array
#

ok(!defined $p->jobs, 'Get undefined array (array)');

$p->clear_jobs();

ok(@{$p->jobs} == 0, 'Clear array (array)');

$p->jobs('butcher', 'baker');

is(join(',', $p->jobs), 'butcher,baker', 'Set list - array (array)');

$p->jobs([ 'butcher', 'baker' ]);

is(join(',', $p->jobs), 'butcher,baker', 'Set list - array ref (array)');

is(join(',', @{$p->jobs}), 'butcher,baker', 'Get list - array ref (array)');

$p->push_jobs('x');
is(join(',', $p->jobs), 'butcher,baker,x', 'push 1(array)');

$p->push_jobs('y', 'z');
is(join(',', $p->jobs), 'butcher,baker,x,y,z', 'push 2 (array)');

is($p->pop_jobs, 'z', 'pop 1 (array)');
is(join(',', $p->jobs), 'butcher,baker,x,y', 'pop 2 (array)');

is(join(',', $p->pop_jobs(2)), 'x,y', 'pop 3 (array)');
is(join(',', $p->jobs), 'butcher,baker', 'pop 4 (array)');

$p->push_jobs([ 1, 2 ]);
is(join(',', $p->jobs), 'butcher,baker,1,2', 'pop 5 (array)');

is(join(',', $p->pop_jobs(2)), '1,2', 'pop 6 (array)');

$p->unshift_jobs('a');
is(join(',', $p->jobs), 'a,butcher,baker', 'unshift 1 (array)');

$p->unshift_jobs('b', 'c');
is(join(',', $p->jobs), 'b,c,a,butcher,baker', 'unshift 2 (array)');

$p->unshift_jobs([ 'd', 'e' ]);
is(join(',', $p->jobs), 'd,e,b,c,a,butcher,baker', 'unshift 3 (array)');

is($p->shift_jobs, 'd', 'shift 1 (array)');
is(join(',', $p->shift_jobs(4)), 'e,b,c,a', 'shift 2 (array)');

#
# array --get_set_item
#

$p->jobs([ 'xbutcher', 'xbaker' ]);

is($p->job(0), 'xbutcher', 'Get item by index (array --get_set_item)');

$p->job(0 => 'mailman');

is($p->job(0), 'mailman', 'Set item by index (array --get_set_item)');

#
# array --get_set_init
#

is(join(',', $p->nicknames), 'wiley,joe', 'Get default list - array (array --get_set_init)');

$p->nicknames('sam', 'moe');

is(join(',', $p->nicknames), 'sam,moe', 'Set list - array (array --get_set_init)');

$p->nicknames([ 'xsam', 'xmoe' ]);

is(join(',', $p->nicknames), 'xsam,xmoe', 'Set list - array ref (array --get_set_init)');

is(join(',', @{$p->nicknames}), 'xsam,xmoe', 'Get list - array ref (array --get_set_init)');

#
# array --get_set_inited
#

my $nicks = $p->idnicknames;

ok(ref $nicks eq 'ARRAY' && !@$nicks, 'Get empty array - scalar (array --get_set_inited)');

my @nicks = $p->idnicknames;

ok(@nicks == 0, 'Get empty array - list (array --get_set_inited)');

$p->idnicknames('sam', 'moe');

is(join(',', $p->idnicknames), 'sam,moe', 'Set list - array (array --get_set_inited)');

$p->idnicknames([ 'xsam', 'xmoe' ]);

is(join(',', $p->idnicknames), 'xsam,xmoe', 'Set list - array ref (array --get_set_inited)');

is(join(',', @{$p->idnicknames}), 'xsam,xmoe', 'Get list - array ref (array --get_set_inited)');

#
# datetime
#

eval { require Rose::DateTime::Util };

SKIP:
{
  if($@)
  {
     skip("datetime tests: could not load Rose::DateTime::Util", 13);
  }

  $p = Person->new(birthday => '01/24/1984 1:00');
  ok(ref $p eq 'Person', 'Construct object (date: with init)');

  is($p->birthday(format => '%m/%d/%Y %H:%M:%S'), '01/24/1984 01:00:00', 'Get named attribute (datetime) 1');

  $p->birthday('01/24/1984 1:00:01');
  is($p->birthday(format => '%m/%d/%Y %H:%M:%S'), '01/24/1984 01:00:01', 'Set named attribute (datetime) 2');

  $p->birthday('01/24/1984 1:00:01.1');
  is($p->birthday(format => '%m/%d/%Y %H:%M:%S.%1N'), '01/24/1984 01:00:01.1', 'Set named attribute (datetime) 3');

  is($p->birthday(format => '%m/%d/%Y %H:%M:%S'), '01/24/1984 01:00:01', 'Set named attribute (datetime) 4');

  $p->birthday_floating('01/24/1984 1:00');
  is(ref $p->birthday_floating->time_zone, 'DateTime::TimeZone::Floating', 'Check time zone 2');

  eval { $p->birthday(foo => 1) };
  ok($@, 'Invalid args (datetime)');

  eval { $p->birthday(1, 2, 3) };
  ok($@, 'Too many args (datetime)');

  is($p->arrival(format => '%m/%d/%Y %t'), '01/24/1984  1:10:00 PM', 'Get named attribute (datetime --get_set_init) 1');
  is($p->departure(format => '%m/%d/%Y'), '01/30/2000', 'Get named attribute (datetime --get_set_init) 2');
  is(ref $p->departure->time_zone, 'DateTime::TimeZone::Floating', 'Check time zone (datetime --get_set_init) 2');

  eval { $p->arrival(foo => 1) };
  ok($@, 'Invalid args (datetime --get_set_init)');

  eval { $p->arrival(1, 2, 3) };
  ok($@, 'Too many args (datetime --get_set_init)');
}

##
## Class methods
##

#
# scalar
#

is(MyObject->flub('bar'), 'bar', 'Set named class attribute (scalar) 1');
is(MyObject->flub(), 'bar', 'Get named class attribute (scalar) 1');
is(MySubObject->flub(), undef, 'Get named class attribute (scalar) 2');
is(MySubObject->flub('baz'), 'baz', 'Set named class attribute (scalar) 2');
is(MySubObject->flub(), 'baz', 'Get named class attribute (scalar) 3');

#
# scalar --get_set_init
#

is(MyObject->class_type(), 'wacky', 'Get named class attribute (scalar --get_set_init) 1');
is(MyObject->class_type('foob'), 'foob', 'Set named class attribute (scalar --get_set_init) 1');
is(MyObject->class_type(), 'foob', 'Get named class attribute (scalar --get_set_init) 1');
is(MySubObject->class_type(), 'subwacky', 'Get named class attribute (scalar --get_set_init) 2');
is(MySubObject->class_type('baz'), 'baz', 'Set named class attribute (scalar --get_set_init) 2');
is(MySubObject->class_type(), 'baz', 'Get named class attribute (scalar --get_set_init) 3');

#
# inheritable_scalar
#

is(MyObject->name('John'), 'John',  'Set named inheritable class attribute 1');
is(MyObject->name(), 'John',  'Get named inheritable class attribute 1');
is(MySubObject4->name, 'John', 'Get named inheritable class attribute (inherited) 1');

is(MySubObject->name(), 'John',  'Get named inheritable class attribute (inherited) 2');
is(MySubObject2->name(), 'John',  'Get named inheritable class attribute (inherited) 3');
is(MySubObject3->name(), 'John',  'Get named inheritable class attribute (inherited) 4');

is(MySubObject->name('Craig'), 'Craig',  'Set named inheritable class attribute 2');
is(MyObject->name(), 'John',  'Get named inheritable class attribute 2');
is(MySubObject->name(), 'Craig',  'Get named inheritable class attribute (inherited) 5');
is(MySubObject2->name(), 'John',  'Get named inheritable class attribute (inherited) 6');
is(MySubObject3->name(), 'John',  'Get named inheritable class attribute (inherited) 7');

is(MySubObject2->name('Anne'), 'Anne',  'Set named inheritable class attribute 3');
is(MyObject->name(), 'John',  'Get named inheritable class attribute 3');
is(MySubObject->name(), 'Craig',  'Get named inheritable class attribute (inherited) 8');
is(MySubObject2->name(), 'Anne',  'Get named inheritable class attribute (not inherited) 1');
is(MySubObject3->name(), 'Anne',  'Get named inheritable class attribute (inherited) 9');
is(MySubObject4->name, 'Anne', 'Get named inheritable class attribute (inherited) 10');

#
# inheritable_boolean
#

is(MyObject->bool('xxx'), 1,  'Set named inheritable class attribute 1');
is(MyObject->bool(), 1,  'Get named inheritable class attribute 1');
is(MySubObject4->bool, 1, 'Get named inheritable class attribute (inherited) 1');

is(MySubObject->bool(), 1,  'Get named inheritable class attribute (inherited) 2');
is(MySubObject2->bool(), 1,  'Get named inheritable class attribute (inherited) 3');
is(MySubObject3->bool(), 1,  'Get named inheritable class attribute (inherited) 4');

is(MySubObject->bool(''), 0,  'Set named inheritable class attribute 2');
is(MyObject->bool(), 1,  'Get named inheritable class attribute 2');
is(MySubObject->bool(), 0,  'Get named inheritable class attribute (inherited) 5');
is(MySubObject2->bool(), 1,  'Get named inheritable class attribute (inherited) 6');
is(MySubObject3->bool(), 1,  'Get named inheritable class attribute (inherited) 7');

is(MySubObject2->bool(1), 1,  'Set named inheritable class attribute 3');
is(MyObject->bool(), 1,  'Get named inheritable class attribute 3');
is(MySubObject->bool(), 0,  'Get named inheritable class attribute (inherited) 8');
is(MySubObject2->bool(), 1,  'Get named inheritable class attribute (not inherited) 1');
is(MySubObject3->bool(), 1,  'Get named inheritable class attribute (inherited) 9');
is(MySubObject4->bool, 1, 'Get named inheritable class attribute (inherited) 10');

#
# POD tests for inheritable_boolean
#

package MyClass;

use Rose::Class::MakeMethods::Generic
(
  inheritable_boolean => 'enabled',
);

package MySubClass;
our @ISA = qw(MyClass);

package MySubSubClass;
our @ISA = qw(MySubClass);

package main;

is(MyClass->enabled,   undef, 'x');
is(MySubClass->enabled, undef, 'x');
is(MySubSubClass->enabled, undef, 'x');

is(MyClass->enabled(1), 1, 'x');
is(MyClass->enabled, 1, 'x');
is(MySubClass->enabled, 1, 'x');
is(MySubSubClass->enabled, 1, 'x');

is(MyClass->enabled(undef), 0, 'x');
is(MyClass->enabled, 0, 'x');
is(MySubClass->enabled, 0, 'x');
is(MySubSubClass->enabled, 0, 'x');

is(MySubClass->enabled(1), 1, 'x');
is(MyClass->enabled, 0, 'x');
is(MySubClass->enabled, 1, 'x');
is(MySubSubClass->enabled, 1, 'x');

is(MyClass->enabled('foo'), 1, 'x');
is(MySubClass->enabled(undef), 0, 'x');
is(MyClass->enabled, 1, 'x');
is(MySubClass->enabled, 0, 'x');
is(MySubSubClass->enabled, 0, 'x');

is(MySubSubClass->enabled(1), 1 , 'x');
is(MyClass->enabled, 1, 'x');
is(MySubClass->enabled, 0, 'x');
is(MySubSubClass->enabled, 1, 'x');

#
# hash
#

ok(!defined MyObject->cparams, 'Get undefined class hash (hash)');

MyObject->cparams(a => 1, b => 2);

is(MyObject->cparam('b'), 2, 'Get class hash key (hash)');

my $ch = MyObject->cparams;

ok(ref $ch eq 'HASH' && $ch->{'a'} == 1 && $ch->{'b'} == 2, 'Get class hash ref (hash --get-set_all)');

my %ch = MyObject->cparams;

ok($ch{'a'} == 1 && $ch{'b'} == 2, 'Get class hash (hash --get-set_all)');

MyObject->cparams({ c => 3, d => 4 });

ok(!MyObject->cparam_exists('a'), 'Check for class hash key existence (hash --exists)');

is(join(',', sort MyObject->cparam_names), 'c,d', 'Get class hash key names (hash --keys)');

is(join(',', sort MyObject->cparam_values), '3,4', 'Get class hash key values (hash --values)');

MyObject->delete_cparam('c');

is(join(',', sort MyObject->cparam_names), 'd', 'Delete cparam (hash --delete)');

MyObject->cparam(f => 7, g => 8);

is(join(',', sort MyObject->cparam_values), '4,7,8', 'Add class hash name/value pairs (hash)');

#
# inheritable_hash
#

ok(!defined MyObject->icparams, 'Get undefined inheritable class hash (hash)');

MyObject->icparams(a => 1, b => 2);

is(MyObject->icparam('b'), 2, 'Get inheritable class hash key (hash)');

my $ich = MyObject->icparams;

ok(ref $ich eq 'HASH' && $ich->{'a'} == 1 && $ich->{'b'} == 2, 'Get inheritable class hash ref (hash --get-set_all)');

my %ich = MyObject->icparams;

ok($ich{'a'} == 1 && $ich{'b'} == 2, 'Get inheritable class hash (hash --get-set_all)');

MyObject->icparams({ c => 3, d => 4 });

ok(!MyObject->icparam_exists('a'), 'Check for inheritable class hash key existence (hash --exists)');

is(join(',', sort MyObject->icparam_names), 'c,d', 'Get inheritable class hash key names (hash --keys)');

is(join(',', sort MyObject->icparam_values), '3,4', 'Get inheritable class hash key values (hash --values)');

is(join(',', sort MySubObject->icparam_names), 'c,d', 'Inherited keys 1');
is(join(',', sort MySubObject->icparam_values), '3,4', 'Inherited values 1');

MyObject->delete_icparam('c');

is(join(',', sort MyObject->icparam_names), 'd', 'Delete icparam (hash --delete)');

MyObject->icparam(f => 7, g => 8);

is(join(',', sort MyObject->icparam_values), '4,7,8', 'Add inheritable class hash name/value pairs (hash)');

is(join(',', sort MySubObject2->icparam_names), 'd,f,g', 'Inherited keys 2');
is(join(',', sort MySubObject2->icparam_values), '4,7,8', 'Inherited values 2');

is(join(',', sort MySubObject3->icparam_names), 'd,f,g', 'Inherited keys 3');
is(join(',', sort MySubObject3->icparam_values), '4,7,8', 'Inherited values 3');

is(join(',', sort MySubObject->icparam_names), 'c,d', 'Inherited keys 4');
is(join(',', sort MySubObject->icparam_values), '3,4', 'Inherited values 4');

ok(!MySubObject->icparam_exists('f'), 'Inherited exists 1');
ok(MySubObject2->icparam_exists('f'), 'Inherited exists 2');
ok(MySubObject3->icparam_exists('f'), 'Inherited exists 3');

MySubObject3->delete_icparam('f');
MySubObject3->icparam('d' => 9);

is(join(',', sort MySubObject->icparam_names), 'c,d', 'Inherited keys 5');
is(join(',', sort MySubObject->icparam_values), '3,4', 'Inherited values 5');

is(join(',', sort MySubObject2->icparam_names), 'd,f,g', 'Inherited keys 6');
is(join(',', sort MySubObject2->icparam_values), '4,7,8', 'Inherited values 6');

is(join(',', sort MySubObject3->icparam_names), 'd,g', 'Inherited keys 7');
is(join(',', sort MySubObject3->icparam_values), '8,9', 'Inherited values 7');

is(join(',', sort MySubObject4->icparam_names), 'd,g', 'Inherited keys 8');
is(join(',', sort MySubObject4->icparam_values), '8,9', 'Inherited values 8');

MySubObject->reset_icparams;

is(join(',', sort MySubObject->icparam_names), 'd,f,g', 'reset_icparams() 1');
is(join(',', sort MySubObject->icparam_values), '4,7,8', 'reset_icparams() 2');

MySubObject->clear_icparams;

is(join(',', sort MySubObject->icparam_names), '', 'clear_icparams() 1');
is(join(',', sort MySubObject->icparam_values), '', 'clear_icparams() 2');

#
# inheritable_set
#

is(MyObject->add_required_names(qw(foo bar baz)), 3, 'add_required_names() 1');

foreach my $attr (MyObject->required_names)
{
  is(MyObject->name_is_required($attr), 1, "name_is_required() $attr");
  is(MySubObject->name_is_valid($attr), 1, "name_is_valid() $attr");
}

foreach my $attr (MyObject->required_names)
{
  is(MySubObject2->name_is_required($attr), 1, "name_is_required() inherited $attr");
  is(MySubObject2->name_is_valid($attr), 1, "name_is_valid() inherited $attr");
}

is(MySubObject3->add_required_names(undef), 0, 'add_required_names() 2');

foreach my $attr (MyObject->required_names)
{
  is(MySubObject3->name_is_required($attr), 1, "name_is_required() not inherited $attr");
  is(MySubObject3->name_is_valid($attr), 1, "name_is_valid() not inherited $attr");
}

is(MyObject->delete_required_name('foo'), 1, 'delete_required_name() 1');
is(MyObject->name_is_required('foo'), 0, 'delete_required_name() 2');
is(MyObject->name_is_valid('foo'), 1, 'delete_required_name() 3');
is(MySubObject2->name_is_valid('foo'), 1, 'delete_required_name() 4');
is(MySubObject3->name_is_valid('foo'), 1, 'delete_required_name() 5');

is(MyObject->required_name_value(foo => 5), undef, 'required_name_value() 1');
is(MyObject->name_is_required('foo'), 0, "name_is_required() not set foo");
is(MyObject->required_name_value(bar => 5), 5, 'required_name_value() 2');
is(MyObject->required_name_value('bar'), 5, 'required_name_value() 3');

MyObject->clear_required_names;
my @names = MyObject->required_names;
ok(@names == 0, 'clear_required_names()');

@names = MySubObject4->inheritable_items;
is_deeply([ sort @names ], [ 'abase', 'bbase' ], 'inheritable_items() 1');

#
# inherited_set
#

is(MyObject->add_valid_names(qw(foo bar baz)), 3, 'add_valid_names() 1');

foreach my $attr (MyObject->valid_names)
{
  is(MySubObject->name_is_valid($attr), 1, "name_is_valid() inherited $attr");
}

MyObject->add_valid_name('blargh');
is(MySubObject->name_is_valid('blargh'), 1, 'name_is_valid() inherited blargh 1');
is(MySubObject2->name_is_valid('blargh'), 1, 'name_is_valid() inherited blargh 2');

MyObject->delete_valid_name('blargh');
is(MySubObject->name_is_valid('blargh'), 0, 'name_is_valid() inherited blargh 3');
is(MySubObject2->name_is_valid('blargh'), 0, 'name_is_valid() inherited blargh 4');

MySubObject->add_valid_name('blargh');
is(MyObject->name_is_valid('blargh'), 0, 'name_is_valid() inherited blargh 5');
is(MySubObject2->name_is_valid('blargh'), 0, 'name_is_valid() inherited blargh 6');

MySubObject->delete_valid_name('blargh');
is(MySubObject->name_is_valid('blargh'), 0, 'name_is_valid() inherited blargh 7');
is(MySubObject2->name_is_valid('blargh'), 0, 'name_is_valid() inherited blargh 8');
is(MyObject->name_is_valid('blargh'), 0, 'name_is_valid() inherited blargh 9');

MyObject->add_valid_name('bloop');
is(MySubObject->name_is_valid('bloop'), 1, 'name_is_valid() inherited bloop 1');
is(MySubObject2->name_is_valid('bloop'), 1, 'name_is_valid() inherited bloop 2');
is(MySubObject3->name_is_valid('bloop'), 1, 'name_is_valid() inherited bloop 3');
is(MyObject->name_is_valid('bloop'), 1, 'name_is_valid() inherited bloop 4');

MySubObject->add_valid_name('bloop');
is(MySubObject->name_is_valid('bloop'), 1, 'name_is_valid() inherited bloop 5');
is(MySubObject2->name_is_valid('bloop'), 1, 'name_is_valid() inherited bloop 6');
is(MySubObject3->name_is_valid('bloop'), 1, 'name_is_valid() inherited bloop 7');
is(MyObject->name_is_valid('bloop'), 1, 'name_is_valid() inherited bloop 8');

MySubObject2->add_valid_name('bloop');
is(MySubObject->name_is_valid('bloop'), 1, 'name_is_valid() inherited bloop 9');
is(MySubObject2->name_is_valid('bloop'), 1, 'name_is_valid() inherited bloop 10');
is(MySubObject3->name_is_valid('bloop'), 1, 'name_is_valid() inherited bloop 11');
is(MyObject->name_is_valid('bloop'), 1, 'name_is_valid() inherited bloop 12');

MySubObject3->add_valid_name('bloop');
is(MySubObject->name_is_valid('bloop'), 1, 'name_is_valid() inherited bloop 13');
is(MySubObject2->name_is_valid('bloop'), 1, 'name_is_valid() inherited bloop 14');
is(MySubObject3->name_is_valid('bloop'), 1, 'name_is_valid() inherited bloop 15');
is(MyObject->name_is_valid('bloop'), 1, 'name_is_valid() inherited bloop 16');

MySubObject->delete_valid_name('bloop');
is(MySubObject->name_is_valid('bloop'), 0, 'name_is_valid() inherited bloop 17');
is(MySubObject2->name_is_valid('bloop'), 1, 'name_is_valid() inherited bloop 18');
is(MySubObject3->name_is_valid('bloop'), 1, 'name_is_valid() inherited bloop 19');
is(MyObject->name_is_valid('bloop'), 1, 'name_is_valid() inherited bloop 20');

MySubObject2->delete_valid_name('bloop');
is(MySubObject->name_is_valid('bloop'), 0, 'name_is_valid() inherited bloop 21');
is(MySubObject2->name_is_valid('bloop'), 0, 'name_is_valid() inherited bloop 22');
is(MySubObject3->name_is_valid('bloop'), 1, 'name_is_valid() inherited bloop 23');
is(MyObject->name_is_valid('bloop'), 1, 'name_is_valid() inherited bloop 24');

MyObject->delete_valid_name('bloop');
is(MySubObject->name_is_valid('bloop'), 0, 'name_is_valid() inherited bloop 25');
is(MySubObject2->name_is_valid('bloop'), 0, 'name_is_valid() inherited bloop 26');
is(MySubObject3->name_is_valid('bloop'), 1, 'name_is_valid() inherited bloop 27');
is(MyObject->name_is_valid('bloop'), 0, 'name_is_valid() inherited bloop 28');

MyObject->add_valid_name('argh');
is(MySubObject->name_is_valid('argh'), 1, 'name_is_valid() inherited argh 1');
is(MySubObject2->name_is_valid('argh'), 1, 'name_is_valid() inherited argh 2');
is(MySubObject3->name_is_valid('argh'), 1, 'name_is_valid() inherited argh 3');
is(MyObject->name_is_valid('argh'), 1, 'name_is_valid() inherited argh 4');

MySubObject2->delete_valid_name('argh');
is(MySubObject->name_is_valid('argh'), 1, 'name_is_valid() inherited argh 5');
is(MySubObject2->name_is_valid('argh'), 0, 'name_is_valid() inherited argh 6');
is(MySubObject3->name_is_valid('argh'), 1, 'name_is_valid() inherited argh 7');
is(MyObject->name_is_valid('argh'), 1, 'name_is_valid() inherited argh 8');

MySubObject->delete_valid_name('argh');
is(MySubObject->name_is_valid('argh'), 0, 'name_is_valid() inherited argh 9');
is(MySubObject2->name_is_valid('argh'), 0, 'name_is_valid() inherited argh 10');
is(MySubObject3->name_is_valid('argh'), 1, 'name_is_valid() inherited argh 11');
is(MyObject->name_is_valid('argh'), 1, 'name_is_valid() inherited argh 12');

MySubObject2->inherit_valid_name('argh');
is(MySubObject->name_is_valid('argh'), 0, 'name_is_valid() inherited argh 13');
is(MySubObject2->name_is_valid('argh'), 1, 'name_is_valid() inherited argh 14');
is(MySubObject3->name_is_valid('argh'), 1, 'name_is_valid() inherited argh 15');
is(MyObject->name_is_valid('argh'), 1, 'name_is_valid() inherited argh 16');

MyObject->clear_valid_names;
@names = MyObject->valid_names;
ok(@names == 0, 'clear_valid_names()');

#
# Inherited set with add_implies
#

MyObject->add_happy_names(qw(whee splurt foop));

foreach my $attr (MyObject->happy_names)
{
  is(MySubObject->name_is_happy($attr), 1, "name_is_happy() inherited $attr");
  is(MySubObject->name_is_valid($attr), 1, "name_is_valid() inherited implied $attr");
}

MyObject->add_happy_name('whee');
is(MySubObject->name_is_happy('whee'), 1, 'name_is_happy() inherited whee 1');
is(MySubObject2->name_is_happy('whee'), 1, 'name_is_happy() inherited whee 2');

MyObject->delete_happy_name('whee');
is(MySubObject->name_is_happy('whee'), 0, 'name_is_happy() inherited whee 3');
is(MySubObject2->name_is_happy('whee'), 0, 'name_is_happy() inherited whee 4');

MySubObject->add_happy_name('whee');
is(MyObject->name_is_happy('whee'), 0, 'name_is_happy() inherited whee 5');
is(MySubObject2->name_is_happy('whee'), 0, 'name_is_happy() inherited whee 6');

MySubObject->delete_happy_name('whee');
is(MySubObject->name_is_happy('whee'), 0, 'name_is_happy() inherited whee 7');
is(MySubObject2->name_is_happy('whee'), 0, 'name_is_happy() inherited whee 8');
is(MyObject->name_is_happy('whee'), 0, 'name_is_happy() inherited whee 9');

MyObject->add_happy_name('splurt');
is(MySubObject->name_is_happy('splurt'), 1, 'name_is_happy() inherited splurt 1');
is(MySubObject2->name_is_happy('splurt'), 1, 'name_is_happy() inherited splurt 2');
is(MySubObject3->name_is_happy('splurt'), 1, 'name_is_happy() inherited splurt 3');
is(MyObject->name_is_happy('splurt'), 1, 'name_is_happy() inherited splurt 4');

MySubObject->add_happy_name('splurt');
is(MySubObject->name_is_happy('splurt'), 1, 'name_is_happy() inherited splurt 5');
is(MySubObject2->name_is_happy('splurt'), 1, 'name_is_happy() inherited splurt 6');
is(MySubObject3->name_is_happy('splurt'), 1, 'name_is_happy() inherited splurt 7');
is(MyObject->name_is_happy('splurt'), 1, 'name_is_happy() inherited splurt 8');

MySubObject2->add_happy_name('splurt');
is(MySubObject->name_is_happy('splurt'), 1, 'name_is_happy() inherited splurt 9');
is(MySubObject2->name_is_happy('splurt'), 1, 'name_is_happy() inherited splurt 10');
is(MySubObject3->name_is_happy('splurt'), 1, 'name_is_happy() inherited splurt 11');
is(MyObject->name_is_happy('splurt'), 1, 'name_is_happy() inherited splurt 12');

MySubObject3->add_happy_name('splurt');
is(MySubObject->name_is_happy('splurt'), 1, 'name_is_happy() inherited splurt 13');
is(MySubObject2->name_is_happy('splurt'), 1, 'name_is_happy() inherited splurt 14');
is(MySubObject3->name_is_happy('splurt'), 1, 'name_is_happy() inherited splurt 15');
is(MyObject->name_is_happy('splurt'), 1, 'name_is_happy() inherited splurt 16');

MySubObject->delete_happy_name('splurt');
is(MySubObject->name_is_happy('splurt'), 0, 'name_is_happy() inherited splurt 17');
is(MySubObject2->name_is_happy('splurt'), 1, 'name_is_happy() inherited splurt 18');
is(MySubObject3->name_is_happy('splurt'), 1, 'name_is_happy() inherited splurt 19');
is(MyObject->name_is_happy('splurt'), 1, 'name_is_happy() inherited splurt 20');

MySubObject2->delete_happy_name('splurt');
is(MySubObject->name_is_happy('splurt'), 0, 'name_is_happy() inherited splurt 21');
is(MySubObject2->name_is_happy('splurt'), 0, 'name_is_happy() inherited splurt 22');
is(MySubObject3->name_is_happy('splurt'), 1, 'name_is_happy() inherited splurt 23');
is(MyObject->name_is_happy('splurt'), 1, 'name_is_happy() inherited splurt 24');

MyObject->delete_happy_name('splurt');
is(MySubObject->name_is_happy('splurt'), 0, 'name_is_happy() inherited splurt 25');
is(MySubObject2->name_is_happy('splurt'), 0, 'name_is_happy() inherited splurt 26');
is(MySubObject3->name_is_happy('splurt'), 1, 'name_is_happy() inherited splurt 27');
is(MyObject->name_is_happy('splurt'), 0, 'name_is_happy() inherited splurt 28');

MyObject->add_happy_name('foop');
is(MySubObject->name_is_happy('foop'), 1, 'name_is_happy() inherited foop 1');
is(MySubObject2->name_is_happy('foop'), 1, 'name_is_happy() inherited foop 2');
is(MySubObject3->name_is_happy('foop'), 1, 'name_is_happy() inherited foop 3');
is(MyObject->name_is_happy('foop'), 1, 'name_is_happy() inherited foop 4');

MySubObject2->delete_happy_name('foop');
is(MySubObject->name_is_happy('foop'), 1, 'name_is_happy() inherited foop 5');
is(MySubObject2->name_is_happy('foop'), 0, 'name_is_happy() inherited foop 6');
is(MySubObject3->name_is_happy('foop'), 1, 'name_is_happy() inherited foop 7');
is(MyObject->name_is_happy('foop'), 1, 'name_is_happy() inherited foop 8');

MySubObject->delete_happy_name('foop');
is(MySubObject->name_is_happy('foop'), 0, 'name_is_happy() inherited foop 9');
is(MySubObject2->name_is_happy('foop'), 0, 'name_is_happy() inherited foop 10');
is(MySubObject3->name_is_happy('foop'), 1, 'name_is_happy() inherited foop 11');
is(MyObject->name_is_happy('foop'), 1, 'name_is_happy() inherited foop 12');

MySubObject2->inherit_happy_name('foop');
is(MySubObject->name_is_happy('foop'), 0, 'name_is_happy() inherited foop 13');
is(MySubObject2->name_is_happy('foop'), 1, 'name_is_happy() inherited foop 14');
is(MySubObject3->name_is_happy('foop'), 1, 'name_is_happy() inherited foop 15');
is(MyObject->name_is_happy('foop'), 1, 'name_is_happy() inherited foop 16');

MyObject->delete_valid_name('foop');
is(MyObject->name_is_happy('foop'), 0, 'delete_implies 1');

#
# Inherited set with inherit_implies
#

MyObject->add_happy_name('iip');
is(MySubObject->name_is_valid('iip'), 1, 'name_is_valid() inherited iip 1');
is(MySubObject2->name_is_valid('iip'), 1, 'name_is_valid() inherited iip 2');
is(MySubObject3->name_is_valid('iip'), 1, 'name_is_valid() inherited iip 3');
is(MyObject->name_is_valid('iip'), 1, 'name_is_valid() inherited iip 4');

is(MySubObject->name_is_happy('iip'), 1, 'name_is_happy() inherited iip 1');
is(MySubObject2->name_is_happy('iip'), 1, 'name_is_happy() inherited iip 2');
is(MySubObject3->name_is_happy('iip'), 1, 'name_is_happy() inherited iip 3');
is(MyObject->name_is_happy('iip'), 1, 'name_is_happy() inherited iip 4');

MySubObject->delete_valid_name('iip');
is(MySubObject->name_is_valid('iip'), 0, 'name_is_valid() inherited iip 5');
is(MySubObject2->name_is_valid('iip'), 1, 'name_is_valid() inherited iip 6');
is(MySubObject3->name_is_valid('iip'), 1, 'name_is_valid() inherited iip 7');
is(MyObject->name_is_valid('iip'), 1, 'name_is_valid() inherited iip 8');

is(MySubObject->name_is_happy('iip'), 0, 'name_is_happy() inherited iip 5');
is(MySubObject2->name_is_happy('iip'), 1, 'name_is_happy() inherited iip 6');
is(MySubObject3->name_is_happy('iip'), 1, 'name_is_happy() inherited iip 7');
is(MyObject->name_is_happy('iip'), 1, 'name_is_happy() inherited iip 8');

MySubObject->inherit_valid_name('iip');
is(MySubObject->name_is_valid('iip'), 1, 'name_is_valid() inherited iip 9');
is(MySubObject2->name_is_valid('iip'), 1, 'name_is_valid() inherited iip 10');
is(MySubObject3->name_is_valid('iip'), 1, 'name_is_valid() inherited iip 11');
is(MyObject->name_is_valid('iip'), 1, 'name_is_valid() inherited iip 12');

is(MySubObject->name_is_happy('iip'), 1, 'name_is_happy() inherited iip 9');
is(MySubObject2->name_is_happy('iip'), 1, 'name_is_happy() inherited iip 10');
is(MySubObject3->name_is_happy('iip'), 1, 'name_is_happy() inherited iip 11');
is(MyObject->name_is_happy('iip'), 1, 'name_is_happy() inherited iip 12');

#
# inherited_hash
#

my %v = (foo => 1, bar => 2, baz => 3);

is(MyObject->add_val_names(%v), 3, 'add_val_names() 1');

foreach my $attr (MyObject->val_name_keys)
{
  is(MySubObject->val_name_exists($attr), 1, "val_name_exists() inherited $attr");
  is(MySubObject->val_name($attr), $v{$attr}, "val_name() inherited $attr");
}
is(MyObject->val_names(\%v), 3, 'add_val_names() 2');

foreach my $attr (MyObject->val_name_keys)
{
  is(MySubObject->val_name_exists($attr), 1, "val_name_exists() 2 inherited $attr");
  is(MySubObject->val_name($attr), $v{$attr}, "val_name() 2 inherited $attr");
}

MyObject->add_val_name(blargh => 11);
is(MySubObject->val_name_exists('blargh'), 1, 'val_name_exists() inherited blargh 1');
is(MySubObject2->val_name_exists('blargh'), 1, 'val_name_exists() inherited blargh 2');
is(MySubObject->val_name('blargh'), 11, 'val_name() inherited blargh 1');
is(MySubObject2->val_name('blargh'), 11, 'val_name() inherited blargh 2');

MyObject->delete_val_name('blargh');
is(MySubObject->val_name_exists('blargh'), 0, 'val_name_exists() inherited blargh 3');
is(MySubObject2->val_name_exists('blargh'), 0, 'val_name_exists() inherited blargh 4');

MySubObject->val_name(blargh => 22);
is(MyObject->val_name_exists('blargh'), 0, 'val_name_exists() inherited blargh 5');
is(MySubObject2->val_name_exists('blargh'), 0, 'val_name_exists() inherited blargh 6');
is(MySubObject->val_name('blargh'), 22, 'val_name() inherited blargh 3');
is(MySubObject2->val_name_exists('blargh'), 0, 'val_name_exists() inherited blargh 4');

MySubObject->delete_val_name('blargh');
is(MySubObject->val_name_exists('blargh'), 0, 'val_name_exists() inherited blargh 7');
is(MySubObject2->val_name_exists('blargh'), 0, 'val_name_exists() inherited blargh 8');
is(MyObject->val_name_exists('blargh'), 0, 'val_name_exists() inherited blargh 9');

MyObject->add_val_name(bloop => 33);
is(MySubObject->val_name_exists('bloop'), 1, 'val_name_exists() inherited bloop 1');
is(MySubObject->val_name('bloop'), 33, 'val_name() inherited bloop 1');
is(MySubObject2->val_name_exists('bloop'), 1, 'val_name_exists() inherited bloop 2');
is(MySubObject2->val_name('bloop'), 33, 'val_name() inherited bloop 2');
is(MySubObject3->val_name_exists('bloop'), 1, 'val_name_exists() inherited bloop 3');
is(MySubObject3->val_name('bloop'), 33, 'val_name() inherited bloop 3');
is(MyObject->val_name_exists('bloop'), 1, 'val_name_exists() inherited bloop 4');
is(MyObject->val_name('bloop'), 33, 'val_name() inherited bloop 4');

MySubObject->add_val_name(bloop => 44);
is(MySubObject->val_name_exists('bloop'), 1, 'val_name_exists() inherited bloop 5');
is(MySubObject->val_name('bloop'), 44, 'val_name() inherited bloop 5');
is(MySubObject2->val_name_exists('bloop'), 1, 'val_name_exists() inherited bloop 6');
is(MySubObject2->val_name('bloop'), 33, 'val_name() inherited bloop 6');
is(MySubObject3->val_name_exists('bloop'), 1, 'val_name_exists() inherited bloop 7');
is(MySubObject3->val_name('bloop'), 33, 'val_name() inherited bloop 7');
is(MyObject->val_name_exists('bloop'), 1, 'val_name_exists() inherited bloop 8');
is(MyObject->val_name('bloop'), 33, 'val_name() inherited bloop 8');

MySubObject2->val_name(bloop => 55);
is(MySubObject->val_name_exists('bloop'), 1, 'val_name_exists() inherited bloop 9');
is(MySubObject->val_name('bloop'), 44, 'val_name() inherited bloop 9');
is(MySubObject2->val_name_exists('bloop'), 1, 'val_name_exists() inherited bloop 10');
is(MySubObject2->val_name('bloop'), 55, 'val_name() inherited bloop 10');
is(MySubObject3->val_name_exists('bloop'), 1, 'val_name_exists() inherited bloop 11');
is(MySubObject3->val_name('bloop'), 55, 'val_name() inherited bloop 11');
is(MyObject->val_name_exists('bloop'), 1, 'val_name_exists() inherited bloop 12');
is(MyObject->val_name('bloop'), 33, 'val_name() inherited bloop 12');

MySubObject3->add_val_name(bloop => 66);
is(MySubObject->val_name_exists('bloop'), 1, 'val_name_exists() inherited bloop 13');
is(MySubObject->val_name('bloop'), 44, 'val_name() inherited bloop 13');
is(MySubObject2->val_name_exists('bloop'), 1, 'val_name_exists() inherited bloop 14');
is(MySubObject2->val_name('bloop'), 55, 'val_name() inherited bloop 14');
is(MySubObject3->val_name_exists('bloop'), 1, 'val_name_exists() inherited bloop 15');
is(MySubObject3->val_name('bloop'), 66, 'val_name() inherited bloop 15');
is(MyObject->val_name_exists('bloop'), 1, 'val_name_exists() inherited bloop 16');
is(MyObject->val_name('bloop'), 33, 'val_name() inherited bloop 16');

MySubObject->delete_val_name('bloop');
is(MySubObject->val_name_exists('bloop'), 0, 'val_name_exists() inherited bloop 17');
is(MySubObject2->val_name_exists('bloop'), 1, 'val_name_exists() inherited bloop 18');
is(MySubObject3->val_name_exists('bloop'), 1, 'val_name_exists() inherited bloop 19');
is(MyObject->val_name_exists('bloop'), 1, 'val_name_exists() inherited bloop 20');

MySubObject2->delete_val_name('bloop');
is(MySubObject->val_name_exists('bloop'), 0, 'val_name_exists() inherited bloop 21');
is(MySubObject2->val_name_exists('bloop'), 0, 'val_name_exists() inherited bloop 22');
is(MySubObject3->val_name_exists('bloop'), 1, 'val_name_exists() inherited bloop 23');
is(MyObject->val_name_exists('bloop'), 1, 'val_name_exists() inherited bloop 24');

MyObject->delete_val_name('bloop');
is(MySubObject->val_name_exists('bloop'), 0, 'val_name_exists() inherited bloop 25');
is(MySubObject2->val_name_exists('bloop'), 0, 'val_name_exists() inherited bloop 26');
is(MySubObject3->val_name_exists('bloop'), 1, 'val_name_exists() inherited bloop 27');
is(MyObject->val_name_exists('bloop'), 0, 'val_name_exists() inherited bloop 28');

MyObject->val_name(argh => 100);
is(MySubObject->val_name_exists('argh'), 1, 'val_name_exists() inherited argh 1');
is(MySubObject->val_name('argh'), 100, 'val_name() inherited argh 1');
is(MySubObject2->val_name_exists('argh'), 1, 'val_name_exists() inherited argh 2');
is(MySubObject2->val_name('argh'), 100, 'val_name() inherited argh 2');
is(MySubObject3->val_name_exists('argh'), 1, 'val_name_exists() inherited argh 3');
is(MySubObject3->val_name('argh'), 100, 'val_name() inherited argh 3');
is(MyObject->val_name_exists('argh'), 1, 'val_name_exists() inherited argh 4');
is(MyObject->val_name('argh'), 100, 'val_name() inherited argh 4');

MySubObject2->delete_val_name('argh');
is(MySubObject->val_name_exists('argh'), 1, 'val_name_exists() inherited argh 5');
is(MySubObject->val_name('argh'), 100, 'val_name() inherited argh 5');
is(MySubObject2->val_name_exists('argh'), 0, 'val_name_exists() inherited argh 6');
is(MySubObject3->val_name_exists('argh'), 1, 'val_name_exists() inherited argh 7');
is(MySubObject3->val_name('argh'), 100, 'val_name() inherited argh 7');
is(MyObject->val_name_exists('argh'), 1, 'val_name_exists() inherited argh 8');
is(MyObject->val_name('argh'), 100, 'val_name() inherited argh 8');

MySubObject->delete_val_name('argh');
is(MySubObject->val_name_exists('argh'), 0, 'val_name_exists() inherited argh 9');
is(MySubObject2->val_name_exists('argh'), 0, 'val_name_exists() inherited argh 10');
is(MySubObject3->val_name_exists('argh'), 1, 'val_name_exists() inherited argh 11');
is(MySubObject3->val_name('argh'), 100, 'val_name() inherited argh 11');
is(MyObject->val_name_exists('argh'), 1, 'val_name_exists() inherited argh 12');
is(MyObject->val_name('argh'), 100, 'val_name() inherited argh 12');

MySubObject2->inherit_val_name('argh');
is(MySubObject->val_name_exists('argh'), 0, 'val_name_exists() inherited argh 13');
is(MySubObject2->val_name_exists('argh'), 1, 'val_name_exists() inherited argh 14');
is(MySubObject2->val_name('argh'), 100, 'val_name() inherited argh 14');
is(MySubObject3->val_name_exists('argh'), 1, 'val_name_exists() inherited argh 15');
is(MySubObject3->val_name('argh'), 100, 'val_name() inherited argh 15');
is(MyObject->val_name_exists('argh'), 1, 'val_name_exists() inherited argh 16');
is(MyObject->val_name('argh'), 100, 'val_name() inherited argh 16');

MyObject->clear_val_names;
@names = MyObject->val_name_keys;
ok(@names == 0, 'clear_val_names()');

#
# Inherited set with add_implies
#

%v = (whee => 1, splurt => 2, foop => 3);

MyObject->hval_names(%v);

foreach my $attr (MyObject->hval_name_keys)
{
  is(MySubObject->hval_name_exists($attr), 1, "hval_name_exists() inherited $attr");
  is(MySubObject->val_name_exists($attr), 1, "val_name_exists() inherited implied $attr");
}

MyObject->add_hval_name(whee => 1);
is(MySubObject->hval_name_exists('whee'), 1, 'hval_name_exists() inherited whee 1');
is(MySubObject2->hval_name_exists('whee'), 1, 'hval_name_exists() inherited whee 2');

MyObject->delete_hval_name('whee');
is(MySubObject->hval_name_exists('whee'), 0, 'hval_name_exists() inherited whee 3');
is(MySubObject->hval_name('whee'), undef, 'hval_name() inherited whee 3');
is(MySubObject2->hval_name_exists('whee'), 0, 'hval_name_exists() inherited whee 4');
is(MySubObject2->hval_name('whee'), undef, 'hval_name() inherited whee 4');

MySubObject->hval_name(whee => 11);
is(MyObject->hval_name_exists('whee'), 0, 'hval_name_exists() inherited whee 5');
is(MyObject->hval_name('whee'), undef, 'hval_name() inherited whee 5');
is(MySubObject2->hval_name_exists('whee'), 0, 'hval_name_exists() inherited whee 6');
is(MySubObject2->hval_name('whee'), undef, 'hval_name() inherited whee 6');

MySubObject->delete_hval_name('whee');
is(MySubObject->hval_name_exists('whee'), 0, 'hval_name_exists() inherited whee 7');
is(MySubObject2->hval_name_exists('whee'), 0, 'hval_name_exists() inherited whee 8');
is(MyObject->hval_name_exists('whee'), 0, 'hval_name_exists() inherited whee 9');

MyObject->hval_name(splurt => 2);
is(MySubObject->hval_name_exists('splurt'), 1, 'hval_name_exists() inherited splurt 1');
is(MySubObject->hval_name('splurt'), 2, 'hval_name() inherited splurt 1');
is(MySubObject2->hval_name_exists('splurt'), 1, 'hval_name_exists() inherited splurt 2');
is(MySubObject2->hval_name('splurt'), 2, 'hval_name() inherited splurt 2');
is(MySubObject3->hval_name_exists('splurt'), 1, 'hval_name_exists() inherited splurt 3');
is(MySubObject3->hval_name('splurt'), 2, 'hval_name() inherited splurt 3');
is(MyObject->hval_name_exists('splurt'), 1, 'hval_name_exists() inherited splurt 4');
is(MyObject->hval_name('splurt'), 2, 'hval_name() inherited splurt 4');

MySubObject->add_hval_name(splurt => 2);
is(MySubObject->hval_name_exists('splurt'), 1, 'hval_name_exists() inherited splurt 5');
is(MySubObject->hval_name('splurt'), 2, 'hval_name() inherited splurt 5');
is(MySubObject2->hval_name_exists('splurt'), 1, 'hval_name_exists() inherited splurt 6');
is(MySubObject2->hval_name('splurt'), 2, 'hval_name() inherited splurt 6');
is(MySubObject3->hval_name_exists('splurt'), 1, 'hval_name_exists() inherited splurt 7');
is(MySubObject3->hval_name('splurt'), 2, 'hval_name() inherited splurt 7');
is(MyObject->hval_name_exists('splurt'), 1, 'hval_name_exists() inherited splurt 8');
is(MyObject->hval_name('splurt'), 2, 'hval_name() inherited splurt 8');

MySubObject2->add_hval_name(splurt => 2);
is(MySubObject->hval_name_exists('splurt'), 1, 'hval_name_exists() inherited splurt 9');
is(MySubObject2->hval_name_exists('splurt'), 1, 'hval_name_exists() inherited splurt 10');
is(MySubObject3->hval_name_exists('splurt'), 1, 'hval_name_exists() inherited splurt 11');
is(MyObject->hval_name_exists('splurt'), 1, 'hval_name_exists() inherited splurt 12');

MySubObject3->add_hval_name(splurt => 2);
is(MySubObject->hval_name_exists('splurt'), 1, 'hval_name_exists() inherited splurt 13');
is(MySubObject2->hval_name_exists('splurt'), 1, 'hval_name_exists() inherited splurt 14');
is(MySubObject3->hval_name_exists('splurt'), 1, 'hval_name_exists() inherited splurt 15');
is(MyObject->hval_name_exists('splurt'), 1, 'hval_name_exists() inherited splurt 16');

MySubObject->delete_hval_name('splurt');
is(MySubObject->hval_name_exists('splurt'), 0, 'hval_name_exists() inherited splurt 17');
is(MySubObject->hval_name('splurt'), undef, 'hval_name() inherited splurt 17');
is(MySubObject2->hval_name_exists('splurt'), 1, 'hval_name_exists() inherited splurt 18');
is(MySubObject2->hval_name('splurt'), 2, 'hval_name() inherited splurt 18');
is(MySubObject3->hval_name_exists('splurt'), 1, 'hval_name_exists() inherited splurt 19');
is(MySubObject3->hval_name('splurt'), 2, 'hval_name() inherited splurt 19');
is(MyObject->hval_name_exists('splurt'), 1, 'hval_name_exists() inherited splurt 20');
is(MyObject->hval_name('splurt'), 2, 'hval_name() inherited splurt 20');

MySubObject2->delete_hval_name('splurt');
is(MySubObject->hval_name_exists('splurt'), 0, 'hval_name_exists() inherited splurt 21');
is(MySubObject2->hval_name_exists('splurt'), 0, 'hval_name_exists() inherited splurt 22');
is(MySubObject3->hval_name_exists('splurt'), 1, 'hval_name_exists() inherited splurt 23');
is(MyObject->hval_name_exists('splurt'), 1, 'hval_name_exists() inherited splurt 24');

MyObject->delete_hval_name('splurt');
is(MySubObject->hval_name_exists('splurt'), 0, 'hval_name_exists() inherited splurt 25');
is(MySubObject2->hval_name_exists('splurt'), 0, 'hval_name_exists() inherited splurt 26');
is(MySubObject3->hval_name_exists('splurt'), 1, 'hval_name_exists() inherited splurt 27');
is(MyObject->hval_name_exists('splurt'), 0, 'hval_name_exists() inherited splurt 28');

MyObject->add_hval_name(foop => 3);
is(MySubObject->hval_name_exists('foop'), 1, 'hval_name_exists() inherited foop 1');
is(MySubObject->hval_name('foop'), 3, 'hval_name() inherited foop 1');
is(MySubObject2->hval_name_exists('foop'), 1, 'hval_name_exists() inherited foop 2');
is(MySubObject2->hval_name('foop'), 3, 'hval_name() inherited foop 2');
is(MySubObject3->hval_name_exists('foop'), 1, 'hval_name_exists() inherited foop 3');
is(MySubObject3->hval_name('foop'), 3, 'hval_name() inherited foop 3');
is(MyObject->hval_name_exists('foop'), 1, 'hval_name_exists() inherited foop 4');
is(MyObject->hval_name('foop'), 3, 'hval_name() inherited foop 4');

MySubObject2->delete_hval_name('foop');
is(MySubObject->hval_name_exists('foop'), 1, 'hval_name_exists() inherited foop 5');
is(MySubObject->hval_name('foop'), 3, 'hval_name() inherited foop 5');
is(MySubObject2->hval_name_exists('foop'), 0, 'hval_name_exists() inherited foop 6');
is(MySubObject2->hval_name('foop'), undef, 'hval_name() inherited foop 6');
is(MySubObject3->hval_name_exists('foop'), 1, 'hval_name_exists() inherited foop 7');
is(MySubObject3->hval_name('foop'), 3, 'hval_name() inherited foop 7');
is(MyObject->hval_name_exists('foop'), 1, 'hval_name_exists() inherited foop 8');
is(MyObject->hval_name('foop'), 3, 'hval_name() inherited foop 8');

MySubObject->delete_hval_name('foop');
is(MySubObject->hval_name_exists('foop'), 0, 'hval_name_exists() inherited foop 9');
is(MySubObject->hval_name('foop'), undef, 'hval_name() inherited foop 9');
is(MySubObject2->hval_name_exists('foop'), 0, 'hval_name_exists() inherited foop 10');
is(MySubObject2->hval_name('foop'), undef, 'hval_name() inherited foop 10');
is(MySubObject3->hval_name_exists('foop'), 1, 'hval_name_exists() inherited foop 11');
is(MySubObject3->hval_name('foop'), 3, 'hval_name() inherited foop 11');
is(MyObject->hval_name_exists('foop'), 1, 'hval_name_exists() inherited foop 12');
is(MyObject->hval_name('foop'), 3, 'hval_name() inherited foop 12');

MySubObject2->inherit_hval_name('foop');
is(MySubObject->hval_name_exists('foop'), 0, 'hval_name_exists() inherited foop 13');
is(MySubObject->hval_name('foop'), undef, 'hval_name() inherited foop 13');
is(MySubObject2->hval_name_exists('foop'), 1, 'hval_name_exists() inherited foop 14');
is(MySubObject2->hval_name('foop'), 3, 'hval_name() inherited foop 14');
is(MySubObject3->hval_name_exists('foop'), 1, 'hval_name_exists() inherited foop 15');
is(MySubObject3->hval_name('foop'), 3, 'hval_name() inherited foop 15');
is(MyObject->hval_name_exists('foop'), 1, 'hval_name_exists() inherited foop 16');
is(MyObject->hval_name('foop'), 3, 'hval_name() inherited foop 16');

MyObject->delete_hval_name('foop');
is(MyObject->hval_name_exists('foop'), 0, 'delete_implies 1');

#
# Inherited set with inherit_implies
#

MyObject->add_hval_name(iip => 227);
is(MySubObject->val_name_exists('iip'), 1, 'val_name_exists() inherited iip 3');
is(MySubObject->val_name('iip'), 227, 'val_name() inherited iip 1');
is(MySubObject2->val_name_exists('iip'), 1, 'val_name_exists() inherited iip 3');
is(MySubObject2->val_name('iip'), 227, 'val_name() inherited iip 2');
is(MySubObject3->val_name_exists('iip'), 1, 'val_name_exists() inherited iip 3');
is(MySubObject3->val_name('iip'), 227, 'val_name() inherited iip 3');
is(MyObject->val_name_exists('iip'), 1, 'val_name_exists() inherited iip 3');
is(MyObject->val_name('iip'), 227, 'val_name() inherited iip 4');

is(MySubObject->hval_name_exists('iip'), 1, 'hval_name_exists() inherited iip 1');
is(MySubObject->hval_name('iip'), 227, 'hval_name() inherited iip 1');
is(MySubObject2->hval_name_exists('iip'), 1, 'hval_name_exists() inherited iip 2');
is(MySubObject2->hval_name('iip'), 227, 'hval_name() inherited iip 2');
is(MySubObject3->hval_name_exists('iip'), 1, 'hval_name_exists() inherited iip 3');
is(MySubObject3->hval_name('iip'), 227, 'hval_name() inherited iip 3');
is(MyObject->hval_name_exists('iip'), 1, 'hval_name_exists() inherited iip 4');
is(MyObject->hval_name('iip'), 227, 'hval_name() inherited iip 4');

MySubObject->delete_val_name('iip');
is(MySubObject->val_name_exists('iip'), 0, 'val_name_exists() inherited iip 3');
is(MySubObject->val_name('iip'), undef, 'val_name() inherited iip 5');
is(MySubObject2->val_name_exists('iip'), 1, 'val_name_exists() inherited iip 3');
is(MySubObject2->val_name('iip'), 227, 'val_name() inherited iip 6');
is(MySubObject3->val_name_exists('iip'), 1, 'val_name_exists() inherited iip 3');
is(MySubObject3->val_name('iip'), 227, 'val_name() inherited iip 7');
is(MyObject->val_name_exists('iip'), 1, 'val_name_exists() inherited iip 3');
is(MyObject->val_name('iip'), 227, 'val_name() inherited iip 8');

is(MySubObject->hval_name_exists('iip'), 0, 'hval_name_exists() inherited iip 3');
is(MySubObject->hval_name('iip'), undef, 'hval_name() inherited iip 5');
is(MySubObject2->hval_name_exists('iip'), 1, 'hval_name_exists() inherited iip 3');
is(MySubObject2->hval_name('iip'), 227, 'hval_name() inherited iip 6');
is(MySubObject3->hval_name_exists('iip'), 1, 'hval_name_exists() inherited iip 3');
is(MySubObject3->hval_name('iip'), 227, 'hval_name() inherited iip 7');
is(MyObject->hval_name_exists('iip'), 1, 'hval_name_exists() inherited iip 3');
is(MyObject->hval_name('iip'), 227, 'hval_name() inherited iip 8');

MySubObject->inherit_val_name('iip');
is(MySubObject->val_name_exists('iip'), 1, 'val_name_exists() inherited iip 3');
is(MySubObject->val_name('iip'), 227, 'val_name() inherited iip 9');
is(MySubObject2->val_name_exists('iip'), 1, 'val_name_exists() inherited iip 3');
is(MySubObject2->val_name('iip'), 227, 'val_name() inherited iip 10');
is(MySubObject3->val_name_exists('iip'), 1, 'val_name_exists() inherited iip 3');
is(MySubObject3->val_name('iip'), 227, 'val_name() inherited iip 11');
is(MyObject->val_name_exists('iip'), 1, 'val_name_exists() inherited iip 3');
is(MyObject->val_name('iip'), 227, 'val_name() inherited iip 12');

is(MySubObject->hval_name_exists('iip'), 1, 'hval_name_exists() inherited iip 3');
is(MySubObject->hval_name('iip'), 227, 'hval_name() inherited iip 9');
is(MySubObject2->hval_name_exists('iip'), 1, 'hval_name_exists() inherited iip 3');
is(MySubObject2->hval_name('iip'), 227, 'hval_name() inherited iip 10');
is(MySubObject3->hval_name_exists('iip'), 1, 'hval_name_exists() inherited iip 3');
is(MySubObject3->hval_name('iip'), 227, 'hval_name() inherited iip 11');
is(MyObject->hval_name_exists('iip'), 1, 'hval_name_exists() inherited iip 3');
is(MyObject->hval_name('iip'), 227, 'hval_name() inherited iip 12');

INHERITED_HASH_POD_CHECK:
{
  package MyClass;

  use Rose::Class::MakeMethods::Generic
  (
    inherited_hash =>
    [
      pet_color =>
      {
        keys_method     => 'pets',
        delete_implies  => 'delete_special_pet_color',
        inherit_implies => 'inherit_special_pet_color',
      },

      special_pet_color =>
      {
        keys_method     => 'special_pets',
        add_implies => 'add_pet_color',
      },
    ],
  );

  package main;

  my $i = 1;

  MyClass->pet_colors(Fido => 'white',
                      Max  => 'black',
                      Spot => 'yellow');

  MyClass->special_pet_color(Toby => 'tan');

  is(join(', ', sort MyClass->pets), 'Fido, Max, Spot, Toby', 'inherited_hash pod ' . $i++);
  is(join(', ', sort MyClass->special_pets), 'Toby', 'inherited_hash pod ' . $i++);

  is(join(', ', sort MySubClass->pets), 'Fido, Max, Spot, Toby', 'inherited_hash pod ' . $i++);
  is(join(', ', sort MyClass->pet_color('Toby')), 'tan', 'inherited_hash pod ' . $i++);

  MySubClass->special_pet_color(Toby => 'gold');

  is(join(', ', sort MyClass->pet_color('Toby')), 'tan', 'inherited_hash pod ' . $i++);
  is(join(', ', sort MyClass->special_pet_color('Toby')), 'tan', 'inherited_hash pod ' . $i++);

  is(join(', ', sort MySubClass->pet_color('Toby')), 'gold', 'inherited_hash pod ' . $i++);
  is(join(', ', sort MySubClass->special_pet_color('Toby')), 'gold', 'inherited_hash pod ' . $i++);

  MySubClass->inherit_pet_color('Toby');

  is(join(', ', sort MySubClass->pet_color('Toby')), 'tan', 'inherited_hash pod ' . $i++);
  is(join(', ', sort MySubClass->special_pet_color('Toby')), 'tan', 'inherited_hash pod ' . $i++);

  MyClass->delete_pet_color('Max');

  is(join(', ', sort MyClass->pets), 'Fido, Spot, Toby', 'inherited_hash pod ' . $i++);
  is(join(', ', sort MySubClass->pets), 'Fido, Spot, Toby', 'inherited_hash pod ' . $i++);

  MyClass->special_pet_color(Max => 'mauve');

  is(join(', ', sort MyClass->pets), 'Fido, Max, Spot, Toby', 'inherited_hash pod ' . $i++);
  is(join(', ', sort MySubClass->pets), 'Fido, Max, Spot, Toby', 'inherited_hash pod ' . $i++);

  is(join(', ', sort MyClass->special_pets), 'Max, Toby', 'inherited_hash pod ' . $i++);
  is(join(', ', sort MySubClass->special_pets), 'Max, Toby', 'inherited_hash pod ' . $i++);

  MySubClass->delete_special_pet_color('Max');

  is(join(', ', sort MyClass->pets), 'Fido, Max, Spot, Toby', 'inherited_hash pod ' . $i++);
  is(join(', ', sort MySubClass->pets), 'Fido, Max, Spot, Toby', 'inherited_hash pod ' . $i++);

  is(join(', ', sort MyClass->special_pets), 'Max, Toby', 'inherited_hash pod ' . $i++);
  is(join(', ', sort MySubClass->special_pets), 'Toby', 'inherited_hash pod ' . $i++);
}

BEGIN
{
  use Test::More();

  package Person;

  use strict;

  @Person::ISA = qw(Rose::Object);

  use Rose::Object::MakeMethods::Generic
  (
    'boolean' => 'is_foo',

    'boolean --get_set_init' =>
    [
      'is_def_foo',
    ],

    'boolean' =>
    [
      is_valid => { default => 1 },
    ],

    'boolean --default=0' => 'def0',

    'scalar' => 'bar',

    'scalar --get_set_init' => 
    [
      qw(type) 
    ],

    hash =>
    [
      param          => { hash_key => 'params' },
      params         => { interface => 'get_set_all' },
      param_names    => { interface => 'keys', hash_key => 'params' },
      param_values   => { interface => 'values', hash_key => 'params' },
      param_exists   => { interface => 'exists', hash_key => 'params' },
      delete_param   => { interface => 'delete', hash_key => 'params' },

      clear_params   => { interface => 'clear', hash_key => 'params' },
      reset_params   => { interface => 'reset', hash_key => 'params' },

      iparams        => { interface => 'get_set_init' },
      reset_iparams  => { interface => 'reset', hash_key => 'iparams' },
      clear_iparams  => { interface => 'clear', hash_key => 'iparams' },

      idparams       => { interface => 'get_set_inited' },
      clear_idparams => { interface => 'clear', hash_key => 'idparams' },
      reset_idparams => { interface => 'reset', hash_key => 'idparams' },

      fhash => { interface => 'get_set_init_all' },
    ],

    array => 'jobs',

    array =>
    [
      job          => { interface => 'get_set_item', hash_key => 'jobs' },
      clear_jobs   => { interface => 'clear', hash_key => 'jobs' },
      push_jobs    => { interface => 'push', hash_key => 'jobs' },
      pop_jobs     => { interface => 'pop', hash_key => 'jobs' },
      unshift_jobs => { interface => 'unshift', hash_key => 'jobs' },
      shift_jobs   => { interface => 'shift', hash_key => 'jobs' },
    ],

    array =>
    [
      nicknames  => { interface => 'get_set_init' },
      idnicknames  => { interface => 'get_set_inited' },
    ],
  );

  SKIP:
  {
    eval { require Rose::DateTime::Util };

    if($@)
    {
      Test::More::skip('loading Rose::Object::MakeMethods::DateTime', 1);
    }
    else
    {
      Test::More::use_ok('Rose::Object::MakeMethods::DateTime');

      eval
      "    
        use Rose::Object::MakeMethods::DateTime
        (
          datetime => [ 'birthday' ],
          datetime => [ birthday_floating => { tz => 'floating' } ],
          'datetime --get_set_init' => 'arrival',
          'datetime --get_set_init' => [ 'departure' => { tz => 'floating' } ],
        );
      ";
    }
  }

  sub init_fhash { { a => 1, b => 2 } }

  sub init_arrival   { '1/24/1984 1:10pm' }
  sub init_departure { DateTime->new(month => 1, day => 30, year => 2000, 
                                     time_zone => 'UTC') }

  sub init_is_def_foo { 123 }

  sub init_type { 'default' }

  sub init_nicknames  { [ qw(wiley joe) ] }

  sub init_iparams { { a => 1, b => 2 } }

  package MyObject;

  use Rose::Class::MakeMethods::Generic
  (
    'inheritable_scalar' => 'name',

    'inheritable_boolean' => 'bool',

    scalar => 
    [
      'flub',
      'class_type' => { interface => 'get_set_init' },
    ],

    hash =>
    [
      cparam          => { hash_key => 'cparams' },
      cparams         => { interface => 'get_set_all' },
      cparam_names    => { interface => 'keys', hash_key => 'cparams' },
      cparam_values   => { interface => 'values', hash_key => 'cparams' },
      cparam_exists   => { interface => 'exists', hash_key => 'cparams' },
      delete_cparam   => { interface => 'delete', hash_key => 'cparams' },

      clear_cparams   => { interface => 'clear', hash_key => 'cparams' },
    ],

    inheritable_hash =>
    [
      icparam          => { hash_key => 'icparams' },
      icparams         => { interface => 'get_set_all' },
      icparam_names    => { interface => 'keys', hash_key => 'icparams' },
      icparam_values   => { interface => 'values', hash_key => 'icparams' },
      icparam_exists   => { interface => 'exists', hash_key => 'icparams' },
      delete_icparam   => { interface => 'delete', hash_key => 'icparams' },

      clear_icparams   => { interface => 'clear', hash_key => 'icparams' },
      reset_icparams   => { interface => 'reset', hash_key => 'icparams' },
    ],

    inherited_hash =>
    [
      val_name =>
      {
        exists_method   => 'val_name_exists', 
        delete_implies  => 'delete_hval_name',
        inherit_implies => 'inherit_hval_name',
      },

      hval_name =>
      {
        add_implies   => 'add_val_name',
        exists_method => 'hval_name_exists', 
      },
    ],
  );

  sub init_class_type { 'wacky' }

  use Rose::Class::MakeMethods::Set
  (
    'inheritable_set  --add_implies=nonesuch' =>
    [
      required_name =>
      {
        add_implies => 'add_valid_name',
        test_method => 'name_is_required', 
      },
    ],

    inheritable_set => 'inheritable_item',

    inherited_set =>
    [
      valid_name =>
      {
        test_method     => 'name_is_valid', 
        delete_implies  => 'delete_happy_name',
        inherit_implies => 'inherit_happy_name',
      },

      happy_name =>
      {
        add_implies => 'add_valid_name',
        test_method => 'name_is_happy', 
      },
    ],
  );

  MyObject->add_inheritable_items(qw(abase bbase));

  package MySubObject;
  our @ISA = qw(MyObject);

  sub init_class_type { 'subwacky' }

  package MySubObject2;
  our @ISA = qw(MyObject);

  package MySubObject3;
  our @ISA = qw(MySubObject2);

  package MySubObject4;
  our @ISA = qw(MySubObject3);
}
