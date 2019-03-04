#!/usr/bin/env perl
use 5.008001;
use strictures 2;
use Test2::V0;

{
    package Foo;
    use strictures 2;

    use Moo;
    with 'MooX::MethodProxyArgs';
    has bar => ( is=>'ro' );
}

$INC{'main.pm'} = 1;

sub divide {
    my ($class, $number, $divisor) = @_;
    return $number / $divisor;
}

my $foo = Foo->new( bar => ['&proxy', 'main', 'divide', 10, 2 ] );

is( $foo->bar(), 5 );

done_testing;
