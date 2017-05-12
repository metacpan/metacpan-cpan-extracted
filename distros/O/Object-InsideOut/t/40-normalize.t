use strict;
use warnings;

use Test::More 'tests' => 6;

package Foo; {
    use Object::InsideOut;

use Data::Dumper;
    my @foo :Field :Acc(foo);
    my @bar :Field :Acc(bar);

    my %init_args :InitArgs = (
        foo => {
            field => \@foo,
            def   => 1,
        },
    );

    sub add_to_init_args
    {
        $init_args{bar} = {
            field => \@bar,
            def   => 'bar',
        };
    }

    sub renormalize
    {
        Object::InsideOut::normalize(\%init_args);
    }
}


package main;

my $obj = Foo->new();
is($obj->foo(), 1       => q/Default for 'foo'/);
ok(! $obj->bar()        => q/'bar' not set/);

Foo::add_to_init_args();

$obj = Foo->new();
is($obj->foo(), 1       => q/Default for 'foo'/);
ok(! $obj->bar()        => q/'bar' not set/);

Foo::renormalize();

$obj = Foo->new();
is($obj->foo(), 1       => q/Default for 'foo'/);
is($obj->bar(), 'bar'   => q/Default for 'bar'/);

exit(0);

# EOF
