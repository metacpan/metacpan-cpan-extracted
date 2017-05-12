#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use Test::More tests => 22;

use lib 't/data';

BEGIN {
    use_ok('Two');
    use_ok('Mock::Sub');
};

{# side_effect
    
    my $cref = sub {die "throwing error";};
    my $mock = Mock::Sub->new;
    my $foo = $mock->mock('One::foo', side_effect => $cref);
    eval{Two::test;};
    like ($@, qr/throwing error/, "side_effect with a cref works");
}
{# side_effect

    my $href = {};
    my $mock = Mock::Sub->new;
    eval {my $test = $mock->mock('One::foo', side_effect => $href);};
    like ($@, qr/side_effect param/, "mock() dies if side_effect isn't a cref");
}
{
    eval {my $mock = Mock::Sub->mock('One::foo', side_effect => sub {}, return_value => 1);};
#    like ($@, qr/use only one of/, "mock() dies if both side_effect and return_value are supplied");
}
{
    my $cref = sub {50};
    my $mock = Mock::Sub->new;
    my $foo = $mock->mock('One::foo', side_effect => $cref);
    my $ret = Two::test;
    is ($ret, 50, "side_effect properly returns a value if die() isn't called")
}
{
    my $cref = sub {'False'};
    my $mock = Mock::Sub->new;
    my $foo = $mock->mock(
        'One::foo',
        side_effect => $cref,
        return_value => 'True');
    my $ret = Two::test;
    is ($ret, 'False', "side_effect with value returns with return_value");
}
{
    my $cref = sub {undef};
    my $mock = Mock::Sub->new;
    my $foo = $mock->mock(
        'One::foo',
        side_effect => $cref,
        return_value => 'True');
    my $ret = Two::test;
    is ($ret, 'True', "side_effect with no value, return_value returns");
}
{
    my $mock = Mock::Sub->new;
    my $foo = $mock->mock('One::foo');
    my $ret = Two::test;

    is ($ret, undef, "no side effect set yet");

    $foo->side_effect(sub {50});

    $ret = Two::test;

    is ($ret, 50, "side_effect() can add an effect after instantiation");

}
{
    my $mock = Mock::Sub->new;
    my $foo = $mock->mock('One::foo');

    eval { $foo->side_effect(10); };

    like ($@, qr/side_effect parameter/,
          "side_effect() can add an effect after instantiation"
    );

}
{
    my $mock = Mock::Sub->new;
    my $foo = $mock->mock('One::foo');

    my $cref = sub {
        return \@_;
    };
    $foo->side_effect($cref);

    my $ret = One::foo(1, 2, {3 => 'a'});

    is (ref $ret, 'ARRAY', 'side_effect now has access to called_with() args');
    is ($ret->[0], 1, 'side_effect 1st arg is 1');
    is ($ret->[1], 2, 'side_effect 2nd arg is 2');
    is (ref $ret->[2], 'HASH', 'side_effect 3rd arg is a hash');
    is ($ret->[2]{3}, 'a', 'side_effect args work properly')
}
{
    my $mock = Mock::Sub->new;
    my $foo = $mock->mock('One::foo');

    $foo->side_effect(sub { return (1, 2, 3); } );

    my @ret = One::foo();

    is (ref \@ret, 'ARRAY', "in list context, side_effect returns array");
    is (@ret, 3, "in list context, side_effect args has right count");

    $foo->side_effect(sub { my %h=(a=>1, b=>2); return %h; } );

    my %ret = One::foo();

    is ($ret{a}, '1', "in list context, a hash is properly created if wanted");
    is ($ret{b}, '2', "in list context, a hash is properly created if wanted");
}
{ # test side_effect in new()

    my $mock = Mock::Sub->new(side_effect => sub {return 'new'});

    my $foo = $mock->mock('One::foo');
    use Data::Dumper;

    my $ret = One::foo();
    is ($ret, 'new', "setting side_effect in new applies to obj 1");

    my $bar = $mock->mock('One::foo');
    $ret = One::foo();
    is ($ret, 'new', "setting side_effect in new applies to obj 2");

    my $baz = $mock->mock('One::foo');
    $ret = One::foo();
    is ($ret, 'new', "setting side_effect in new applies to obj 3");
}

