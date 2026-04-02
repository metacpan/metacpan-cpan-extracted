#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Object::Proto;

# Test DEMOLISH support (zero overhead)

our @destroyed;

# Test 1: Class with DEMOLISH gets it called on destruction
package WithDemolish;

sub DEMOLISH {
    my ($self) = @_;
    push @main::destroyed, "WithDemolish::DEMOLISH called";
}

package main;

Object::Proto::define('WithDemolish',
    'name:Str',
);

{
    my $obj = WithDemolish->new(name => "test");
    is(scalar @destroyed, 0, 'DEMOLISH not called while object alive');
}
is(scalar @destroyed, 1, 'DEMOLISH called when object destroyed');
like($destroyed[0], qr/WithDemolish::DEMOLISH called/, 'Correct DEMOLISH message');

# Test 2: Class without DEMOLISH has no overhead
package WithoutDemolish;
package main;

Object::Proto::define('WithoutDemolish', 'value');

{
    my $obj = WithoutDemolish->new(value => 42);
    ok(!$obj->can('DESTROY'), 'No DESTROY installed for class without DEMOLISH');
}
ok(1, 'No crash for class without DEMOLISH');

# Test 3: DEMOLISH receives $self correctly
package TrackSelf;

sub DEMOLISH {
    my ($self) = @_;
    push @main::destroyed, $self->name;
}

package main;

Object::Proto::define('TrackSelf', 'name:Str');

@destroyed = ();
{
    my $obj = TrackSelf->new(name => "Alice");
}
is_deeply(\@destroyed, ['Alice'], 'DEMOLISH receives self with correct data');

# Test 4: Multiple objects destroy independently
@destroyed = ();
{
    my $a = TrackSelf->new(name => "A");
    my $b = TrackSelf->new(name => "B");
    # B goes out of scope first
}
is(scalar @destroyed, 2, 'Both objects DEMOLISH called');

done_testing();
