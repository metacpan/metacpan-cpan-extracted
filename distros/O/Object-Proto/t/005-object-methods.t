use strict;
use warnings;
use Test::More tests => 9;

use Object::Proto;

# Define class with properties
Object::Proto::define('Animal', qw(name species));

# Add custom methods to the package
package Animal;
sub speak { 
    my $self = shift; 
    return $self->name . " says hello!";
}

sub info {
    my $self = shift;
    return $self->name . " is a " . $self->species;
}

package main;

# Create object
my $dog = new Animal 'Rex', 'dog';

# Test basic accessors
is($dog->name, 'Rex', 'getter works');
is($dog->species, 'dog', 'getter works for second prop');

# Test custom package methods
is($dog->speak, 'Rex says hello!', 'custom method works');
is($dog->info, 'Rex is a dog', 'custom method using multiple accessors');

# Test isa
ok($dog->isa('Animal'), 'isa returns true for correct class');
ok(!$dog->isa('Cat'), 'isa returns false for wrong class');

# Test can
ok($dog->can('speak'), 'can returns true for defined method');
ok($dog->can('name'), 'can returns true for accessor');

# Test ref
is(ref($dog), 'Animal', 'ref returns class name');
