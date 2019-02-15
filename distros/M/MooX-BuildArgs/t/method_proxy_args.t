#!/usr/bin/env perl
use Test2::V0;

{
    package Foo;
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
