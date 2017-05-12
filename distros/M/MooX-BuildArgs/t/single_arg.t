#!/usr/bin/env perl
use Test2::Bundle::Extended;

{
    package Foo;
    use Moo;
    with 'MooX::SingleArg';
    __PACKAGE__->single_arg('bar');
    has bar => ( is=>'ro' );
}

my $list = Foo->new( bar=>11 );
is(
    $list->bar(),
    11,
    'list arguments',
);

my $hash_ref = Foo->new({ bar=>22 });
is(
    $hash_ref->bar(),
    22,
    'hash ref arguments',
);

my $single   = Foo->new( 33 );
is(
    $single->bar(),
    33,
    'single arguments',
);

{
    package FooForced;
    use Moo;
    with 'MooX::SingleArg';
    __PACKAGE__->single_arg('bar');
    __PACKAGE__->force_single_arg( 1 );
    has bar => ( is=>'ro' );
}

my $forced = FooForced->new({ bar=>44 });
is(
    $forced->bar(),
    { bar=>44 },
    'hash ref arguments with force_single_arg',
);

done_testing;
