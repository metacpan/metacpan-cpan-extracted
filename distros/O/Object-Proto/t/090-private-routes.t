use strict;
use warnings;
use Test::More;
use Object::Proto;

# A :private attribute may only be called from the package that declared it,
# through every method Object::Proto generates for it, and however the object
# was made. Each route is tried from main (dies) and from inside (works).

sub refused {
    my ($code, $attr, $class, $from, $name) = @_;
    ok(!eval { $code->(); 1 }, "$name dies");
    like($@, qr/^cannot call private attribute \Q$attr\E on \Q$class\E from \Q$from\E at /,
         "$name names the attribute, the class and the caller");
}

BEGIN {
    Object::Proto::define('Cat', 'name',
        'age:Int:private:reader(get_age):writer(set_age):clearer:predicate',
        'tag:private');
    Object::Proto::import_accessor('Cat', 'age', 'cat_age', 'main');
    Object::Proto::import_accessors('Cat', 'c_', 'main');
    Object::Proto::import_accessor('Cat', 'age', 'fn_age', 'Cat');
    Object::Proto::import_accessor('Cat', 'name', 'cat_name', 'main');
}

package Cat;
sub peek       { $_[0]->age }
sub poke       { $_[0]->age($_[1]) }
sub peek_tag   { $_[0]->tag }
sub via_reader { $_[0]->get_age }
sub via_writer { $_[0]->set_age($_[1]) }
sub via_clear  { $_[0]->clear_age }
sub via_has    { $_[0]->has_age }
sub fn_get     { fn_age($_[0]) }
sub fn_set     { fn_age($_[0], $_[1]) }
sub fn_set_sum { fn_age($_[0], $_[1] + 0) }

package main;

# --- the class's own attribute, every route ------------------------------
my $cat = new Cat name => 'Tom', age => 3, tag => 't';
refused(sub { $cat->age },                      'age', 'Cat', 'main', 'the getter from main');
refused(sub { $cat->age(4) },                   'age', 'Cat', 'main', 'the setter from main');
refused(sub { Cat->new(age => 1)->age },        'age', 'Cat', 'main', 'Cat->new(...)->age from main');
refused(sub { (new Cat age => 1)->age },        'age', 'Cat', 'main', 'new Cat(...)->age from main');
refused(sub { Cat->can('age')->($cat) },        'age', 'Cat', 'main', 'the accessor called as a code ref');
refused(sub { $cat->tag },                      'tag', 'Cat', 'main', 'an untyped private getter from main');
refused(sub { $cat->get_age },                  'age', 'Cat', 'main', 'the reader from main');
refused(sub { $cat->set_age(9) },               'age', 'Cat', 'main', 'the writer from main');
refused(sub { $cat->clear_age },                'age', 'Cat', 'main', 'the clearer from main');
refused(sub { $cat->has_age },                  'age', 'Cat', 'main', 'the predicate from main');
refused(sub { cat_age($cat) },                  'age', 'Cat', 'main', 'an imported function getter from main');
refused(sub { cat_age($cat, 5) },               'age', 'Cat', 'main', 'an imported function setter from main');
my $five = 5;
refused(sub { cat_age($cat, $five + 1) },       'age', 'Cat', 'main', 'an imported function setter with an expression');
refused(sub { my $f = \&cat_age; $f->($cat) },  'age', 'Cat', 'main', 'an imported function called through a reference');
refused(sub { c_age($cat) },                    'age', 'Cat', 'main', 'a function from import_accessors');
refused(sub { c_tag($cat) },                    'tag', 'Cat', 'main', 'an untyped one from import_accessors');


is($cat->peek, 3, 'the getter works from a Cat method');
is($cat->poke(4), 4, 'and the setter');
is($cat->peek_tag, 't', 'and an untyped private attribute');
is($cat->via_reader, 4, 'the reader works from Cat');
is($cat->via_writer(5), 5, 'the writer works from Cat');
ok($cat->via_has, 'the predicate works from Cat');
$cat->via_clear;
ok(!$cat->via_has, 'the clearer works from Cat');
is($cat->fn_set(6), 6, 'a function accessor imported into Cat sets from Cat');
is($cat->fn_get, 6, 'and gets');
is($cat->fn_set_sum(7), 7, 'and sets with an expression');
is(cat_name($cat), 'Tom', 'a public attribute imported as a function is unaffected');
is($cat->name, 'Tom', 'as is its method accessor');

# Initialising through the constructor is not a call to the accessor
my $made = Cat->new(age => 8);
is($made->peek, 8, 'the constructor still sets a private attribute from main');

# --- inherited: private to the parent that declared it -------------------
Object::Proto::define('Animal', 'legs:private', 'sound');
Object::Proto::define('Dog', extends => 'Animal', 'breed');
Object::Proto::define('Puppy', extends => 'Dog');

package Animal;
sub count_legs { $_[0]->legs }
package Dog;
sub dog_legs { $_[0]->legs }
package main;

my $dog = Dog->new(legs => 4, sound => 'woof');
refused(sub { $dog->legs },             'legs', 'Dog', 'main', 'an inherited private getter from main');
refused(sub { Dog->new->legs },         'legs', 'Dog', 'main', 'Dog->new->legs from main');
refused(sub { $dog->dog_legs },         'legs', 'Dog', 'Dog',  'an inherited private attribute from the child');
is($dog->count_legs, 4, 'a method of the declaring parent works on a child object');
is($dog->sound, 'woof', 'an inherited public attribute is unaffected');
my $pup = Puppy->new(legs => 3);
is($pup->count_legs, 3, 'and on a grandchild object');
refused(sub { $pup->legs },             'legs', 'Puppy', 'main', 'a grandchild from main');
refused(sub { $pup->dog_legs },         'legs', 'Puppy', 'Dog',  'a grandchild from the middle class');

# +attr keeps the parent as owner, unless it is the one adding :private
Object::Proto::define('Box', 'size:private', 'lid');
Object::Proto::define('BigBox', extends => 'Box', '+size:Int');
Object::Proto::define('Crate', extends => 'Box', '+lid:private');

package Box;
sub box_size { $_[0]->size }
sub box_lid  { $_[0]->lid }
package BigBox;
sub big_size { $_[0]->size }
package Crate;
sub crate_lid { $_[0]->lid }
package main;

my $big = BigBox->new(size => 9);
is($big->box_size, 9, '+attr on an inherited private attribute keeps the parent as owner');
refused(sub { $big->big_size }, 'size', 'BigBox', 'BigBox', 'so the child still cannot call it');
my $crate = Crate->new(lid => 'wood');
is($crate->crate_lid, 'wood', '+attr:private in the child makes the child the owner');
refused(sub { $crate->box_lid }, 'lid', 'Crate', 'Box', 'and the parent cannot call it on a child object');
refused(sub { $crate->lid },     'lid', 'Crate', 'main', 'nor can main');
is(Box->new(lid => 'l')->box_lid, 'l', 'the parent\'s own, public attribute is unchanged');

# --- a role's attribute: the role and the class that composed it ---------
package Secretive;
sub reveal { $_[0]->secret }
package Vault;
sub vault_secret { $_[0]->secret }
sub read_other   { $_[1]->secret }
package SubVault;
sub sub_secret { $_[0]->secret }
package main;

Object::Proto::role('Secretive', 'secret:private:reader(read_secret)');
Object::Proto::define('Vault', 'owner');
Object::Proto::with('Vault', 'Secretive');
Object::Proto::define('Safe', 'owner');
Object::Proto::with('Safe', 'Secretive');
Object::Proto::define('SubVault', extends => 'Vault');

my $vault = Vault->new(secret => 's1', owner => 'me');
refused(sub { $vault->secret },      'secret', 'Vault', 'main', 'a role private attribute from main');
refused(sub { $vault->read_secret }, 'secret', 'Vault', 'main', 'its reader from main');
is($vault->vault_secret, 's1', 'works from the consuming class');
is($vault->reveal, 's1', 'works from a role method');
is($vault->owner, 'me', 'the class\'s public attribute is unaffected');

my $safe = Safe->new(secret => 's2');
is($safe->reveal, 's2', 'a second class consuming the role: the role method works');
refused(sub { $vault->read_other($safe) }, 'secret', 'Safe', 'Vault',
        'the first consumer cannot call it on the second consumer\'s objects');

my $sub = SubVault->new(secret => 's3');
is($sub->vault_secret, 's3', 'a child of the consumer: the consumer\'s method works');
is($sub->reveal, 's3', 'and the role\'s');
refused(sub { $sub->sub_secret }, 'secret', 'SubVault', 'SubVault', 'but not the child\'s own method');
refused(sub { $sub->secret },     'secret', 'SubVault', 'main',     'nor main');

done_testing;
