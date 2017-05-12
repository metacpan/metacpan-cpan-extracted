#!/perl -T

use strict;
use warnings;

use Test::More tests => 6;

package Test::Object;

use Object::New;

package Test::Object::WithInit;

use Object::New;

sub init {
    my $self = shift;
    $self->{arguments} = [@_];
}

package main;

my $to = Test::Object->new();

isa_ok($to, 'Test::Object');

ok(! $to->can("init"));

my $towi = Test::Object::WithInit->new(qw/one two three/);

isa_ok($towi, 'Test::Object::WithInit');

ok(Test::Object::WithInit->can("init"));
ok($towi->can("init"));

is_deeply($towi->{arguments}, ["one", "two", "three"]);
