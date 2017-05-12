use strict;
use warnings;
use Test::More;
use Test::Exception;
use Nephia::Chain;

subtest normal => sub {
    my $obj = Nephia::Chain->new;
    isa_ok $obj, 'Nephia::Chain';
    my $chain = $obj->{chain};
    
    $obj->append(foo => sub {'bar'}, hoge => sub{'fuga'});
    isa_ok $chain->[ $obj->index($_) ], "Nephia::Chain::Item::$_" for qw/foo hoge/;
    is $obj->size, 2;
    
    $obj->prepend(piyo => sub {'poo'});
    isa_ok $chain->[0], 'Nephia::Chain::Item::piyo';
    isa_ok $chain->[1], 'Nephia::Chain::Item::foo';
    isa_ok $chain->[2], 'Nephia::Chain::Item::hoge';
    is $obj->size, 3;
    
    $obj->after('foo', x => sub {123});
    isa_ok $chain->[0], 'Nephia::Chain::Item::piyo';
    isa_ok $chain->[1], 'Nephia::Chain::Item::foo';
    isa_ok $chain->[2], 'Nephia::Chain::Item::x';
    isa_ok $chain->[3], 'Nephia::Chain::Item::hoge';
    is $obj->size, 4;
    
    $obj->before('hoge', y => sub {321});
    isa_ok $chain->[0], 'Nephia::Chain::Item::piyo';
    isa_ok $chain->[1], 'Nephia::Chain::Item::foo';
    isa_ok $chain->[2], 'Nephia::Chain::Item::x';
    isa_ok $chain->[3], 'Nephia::Chain::Item::y';
    isa_ok $chain->[4], 'Nephia::Chain::Item::hoge';
    is $obj->size, 5;
    
    is join(',', map {$_->()} $obj->as_array), 'poo,bar,123,321,fuga', 'as_array';

    $obj->delete('foo');
    isa_ok $chain->[0], 'Nephia::Chain::Item::piyo';
    isa_ok $chain->[1], 'Nephia::Chain::Item::x';
    isa_ok $chain->[2], 'Nephia::Chain::Item::y';
    isa_ok $chain->[3], 'Nephia::Chain::Item::hoge';
    is $obj->size, 4;
    
};

subtest failure => sub {
    my $obj = Nephia::Chain->new;
    throws_ok { $obj->append(foo => sub {'bar'}, 'hoge') } qr/^code for hoge is undefined/;
    dies_ok { $obj->append(foo => sub {'bar'}, 'hoge') } 'say error and die';
    is $obj->size, 0;
};

{
    package Nephia::Chain::Test::Alpha;
    sub add_foo {
        my ($class, $chain) = @_;
        $chain->append(foo => sub { 'Foo' });
    }
}

{
    package Nephia::Chain::Test::Beta;
    sub add_bar {
        my ($class, $chain) = @_;
        $chain->append(bar => sub { 'Bar' });
    }
}

subtest from => sub {
    my $obj = Nephia::Chain->new;
    Nephia::Chain::Test::Alpha->add_foo($obj);
    Nephia::Chain::Test::Beta->add_bar($obj);
    is $obj->from('foo'), 'Nephia::Chain::Test::Alpha';
    is $obj->from('bar'), 'Nephia::Chain::Test::Beta';
};

done_testing;
