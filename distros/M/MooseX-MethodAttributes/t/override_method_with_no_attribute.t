use strict;
use warnings;
use Test::More tests => 7;

use lib 't/lib';

use TestClass;

is_deeply( TestClass->meta->get_method('bar')->attributes,
    [q{SomeAttribute}], );

is_deeply( SubClass->meta->get_method('bar')->attributes, [], );

my @methods = SubClass->meta->get_all_methods_with_attributes;

my $bar_method = (grep { $_->name eq 'bar' } @methods)[0];
ok $bar_method;

# This is correct, we get the bar method from TestClass back,
# as that is the one with attributes.
isnt $bar_method, SubClass->meta->get_method('bar');
is $bar_method, TestClass->meta->get_method('bar');

my @methods_filtered = SubClass->meta->get_nearest_methods_with_attributes;
is( scalar(@methods_filtered), (scalar(@methods)-1) );

my $no_bar_method = (grep { $_->name eq 'bar' } @methods_filtered)[0];
is $no_bar_method, undef;

