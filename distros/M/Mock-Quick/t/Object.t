#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Fennec::Lite;
use Mock::Quick::Method;

our $CLASS;

BEGIN {
    $CLASS = 'Mock::Quick::Object';
    use_ok( $CLASS );
}

tests get_set => sub {
    my $obj = $CLASS->new( foo => 'bar' );

    ok( $obj->can('zed'), "can do random sub" );

    is( $obj->foo(), 'bar', "have property" );

    ok( !$obj->baz(), "No property set" );
    is( $obj->baz( 1 ), 1, "setting property" );
    is( $obj->baz(), 1, "Stored value" );
};

tests methods => sub {
    my @args;
    my $obj = $CLASS->new(
        foo => Mock::Quick::Method->new( sub {
            @args = @_;
            return "foo was called";
        }),
    );

    is( $obj->foo( qw/bar baz/ ), "foo was called", "called virtualmethod" );
    is_deeply(
        \@args,
        [ $obj, qw/bar baz/ ],
        "Correct arguments",
    );

    is( $obj->foo( \$Mock::Quick::Util::CLEAR ), undef, "clearing method" );
    is( $obj->foo(), undef, "cleared method" );
};

run_tests;
done_testing;
