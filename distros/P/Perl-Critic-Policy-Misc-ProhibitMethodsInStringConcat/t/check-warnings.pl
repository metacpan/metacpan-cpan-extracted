#!/usr/bin/perl
use strict;
use warnings;

# Test class that can return undef from its methods
package TestObj;
sub new   { bless {}, shift }
sub name  { my $self = shift; return $self->{name} }
sub age   { my $self = shift; return $self->{age} }
sub greet { my $self = shift; return $self->{greet} }

package main;

my $obj = TestObj->new();
$obj->{name}  = 'Alice';
$obj->{age}   = undef;     # This one returns undef
$obj->{greet} = undef;     # This one also returns undef

print "=== Test 1: String concatenation with method calls ===\n";
{
    no warnings qw(once);
    my $result = "Name: " . $obj->name() . " Age: " . $obj->age() . " Greet: " . $obj->greet();
    print "Result: [$result]\n";
}

print "\n=== Test 2: sprintf with method calls ===\n";
{
    no warnings qw(once);
    my $result = sprintf 'Name: %s Age: %s Greet: %s', $obj->name(), $obj->age(), $obj->greet();
    print "Result: [$result]\n";
}

print "\n=== Test 3: Pre-assigned variables (the recommended approach) ===\n";
{
    no warnings qw(once);
    my $name   = $obj->name();
    my $age    = $obj->age();
    my $greet  = $obj->greet();
    my $result = "Name: " . $name . " Age: " . $age . " Greet: " . $greet;
    print "Result: [$result]\n";
}

print "\n=== Test 4: sprintf with pre-assigned variables ===\n";
{
    no warnings qw(once);
    my $name   = $obj->name();
    my $age    = $obj->age();
    my $greet  = $obj->greet();
    my $result = sprintf 'Name: %s Age: %s Greet: %s', $name, $age, $greet;
    print "Result: [$result]\n";
}

print "\n--- All tests complete ---\n";
