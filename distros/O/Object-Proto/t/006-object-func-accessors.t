use strict;
use warnings;
use Test::More tests => 15;

# Must define and import in BEGIN before using function-style accessors
BEGIN {
    require Object::Proto;
    Object::Proto::define('Cat', qw(name age color));
    Object::Proto::import_accessors('Cat');  # Import all
    Object::Proto::import_accessor('Cat', 'name', 'get_name');     # alias name -> get_name
    Object::Proto::import_accessor('Cat', 'age', 'cat_age');       # alias age -> cat_age
    Object::Proto::import_accessor('Cat', 'color', 'set_color');   # alias for setter
}

use Object::Proto;

# Create test object
my $cat = new Cat 'Whiskers', 3, 'orange';

# Test basic function-style accessors (same name as property)
is(name($cat), 'Whiskers', 'function-style name() getter');
is(age($cat), 3, 'function-style age() getter');
is(color($cat), 'orange', 'function-style color() getter');

# Test aliased getters
is(get_name($cat), 'Whiskers', 'aliased get_name() works');
is(cat_age($cat), 3, 'aliased cat_age() works');

# Test function-style setters (same functions work for set)
age($cat, 5);
is(age($cat), 5, 'function-style age() setter');
is($cat->age, 5, 'method accessor sees update from function-style');

# Test aliased setter
set_color($cat, 'black');
is(color($cat), 'black', 'aliased set_color() setter');
is($cat->color, 'black', 'method accessor sees alias setter update');

# Test that function and method accessors are in sync
$cat->name('Felix');
is(name($cat), 'Felix', 'function-style sees method update');
is(get_name($cat), 'Felix', 'aliased function sees method update');

# Test multiple objects
my $cat2 = new Cat 'Garfield', 7, 'orange';
is(name($cat2), 'Garfield', 'function accessor works on different object');
is(name($cat), 'Felix', 'original object unchanged');

# Test that return value from setter is correct
my $ret = age($cat, 99);
is($ret, 99, 'setter returns new value');

# Test with undef
color($cat, undef);
ok(!defined(color($cat)), 'can set to undef');
