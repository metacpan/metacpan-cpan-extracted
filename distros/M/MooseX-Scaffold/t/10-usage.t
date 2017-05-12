#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

BEGIN {
    $INC{$_} = 1 for qw/MyScaffolder.pm MyAppleClass.pm MyBananaClass.pm/;
}

BEGIN {
package MyScaffolder;

use MooseX::Scaffold;

MooseX::Scaffold->setup_scaffolding_import;

sub SCAFFOLD {
    my $class = shift;
    my %given = @_;

    $class->has($given{kind} => is => 'ro', isa => 'Int', required => 1);

    # Using MooseX::ClassAttribute
    $class->class_has(kind => is => 'ro', isa => 'Str', default => $given{kind});
}
}

package MyAppleClass;

use Moose;
use MooseX::ClassAttribute;
use MyScaffolder kind => 'apple';

package MyBananaClass;

use Moose;
use MooseX::ClassAttribute;
use MyScaffolder kind => 'banana';

package main;

use MyAppleClass;
use MyBananaClass;

my $apple = MyAppleClass->new(apple => 1);
my $banana = MyBananaClass->new(banana => 2);

is($apple->apple, 1);
is($apple->kind, 'apple');

is($banana->banana, 2);
is($banana->kind, 'banana');
