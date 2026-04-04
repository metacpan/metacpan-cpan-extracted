#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Object::Proto;

# Test Object::Proto::is_locked predicate function
# is_locked initially false
{
    Object::Proto::define('LockTest1', qw(value));
    my $obj = new LockTest1 value => 42;
    
    ok(!Object::Proto::is_locked($obj), 'new object is not locked');
}
# is_locked after lock
{
    Object::Proto::define('LockTest2', qw(name));
    my $obj = new LockTest2 name => 'test';
    
    ok(!Object::Proto::is_locked($obj), 'initially not locked');
    Object::Proto::lock($obj);
    ok(Object::Proto::is_locked($obj), 'is_locked returns true after lock');
}
# is_locked after unlock
{
    Object::Proto::define('LockTest3', qw(data));
    my $obj = new LockTest3 data => 'test';
    
    Object::Proto::lock($obj);
    ok(Object::Proto::is_locked($obj), 'locked');
    Object::Proto::unlock($obj);
    ok(!Object::Proto::is_locked($obj), 'is_locked returns false after unlock');
}
# is_locked with prototype chain
{
    Object::Proto::define('LockParent', qw(parent_val));
    Object::Proto::define('LockChild', qw(child_val), 'LockParent');
    
    my $child = new LockChild child_val => 1, parent_val => 2;
    
    ok(!Object::Proto::is_locked($child), 'child initially not locked');
    Object::Proto::lock($child);
    ok(Object::Proto::is_locked($child), 'child is_locked after lock');
}
# is_locked is per-object
{
    Object::Proto::define('LockMulti', qw(val));
    my $obj1 = new LockMulti val => 1;
    my $obj2 = new LockMulti val => 2;
    
    Object::Proto::lock($obj1);
    
    ok(Object::Proto::is_locked($obj1), 'obj1 is locked');
    ok(!Object::Proto::is_locked($obj2), 'obj2 is not locked (independent)');
}
done_testing;
