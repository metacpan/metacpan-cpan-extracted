use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('Net::Google::DataAPI::Role::HasContent');
}

{
    package Foo;
    use Any::Moose;
    with 'Net::Google::DataAPI::Role::HasContent';

    sub update { }
}

my $hash = {
    a => 1,
    b => 2,
};

ok my $foo = Foo->new(
    content => $hash,
);
is_deeply $foo->param, $hash;
is $foo->param('a'), $hash->{a};
is_deeply $foo->param({a => 3}), {
    %$hash,
    a => 3
};
is $foo->param('a'), 3;

done_testing;
