#!/usr/bin/perl
package Foo::Bar;
use strict;
use warnings;

use Test::More;
use Test::Exception;
use Fennec::Lite random => 0;
use Mock::Quick::Method;

our $CLASS;

BEGIN {
    $CLASS = 'Mock::Quick::Class';
    use_ok($CLASS);

    package Foo;
    1;

    package Bar;
    1;

    package Baz;
    sub foo { 'foo' }
    sub bar { 'bar' }
    sub baz { 'baz' }
    1;
}

tests create => sub {
    my $i = 1;
    my $obj = $CLASS->new( -with_new => 1, foo => 'bar', baz => sub { $i++ } );
    isa_ok( $obj, $CLASS );
    is( $obj->package, "$CLASS\::__ANON__\::AAAAAAAAAA", "First package" );
    can_ok( $obj->package, qw/new foo baz/ );
    isa_ok( $obj->new, $obj->package );
    is( $obj->new->baz, 1, "sub run 1" );
    is( $obj->new->baz, 2, "sub run 2" );

    $obj = $CLASS->new( -subclass => 'Foo' );
    isa_ok( $obj, $CLASS );
    is( $obj->package, "$CLASS\::__ANON__\::AAAAAAAAAB", "Second package" );
    ok( !$obj->package->can('new'), "no new" );
    isa_ok( $obj->package, 'Foo' );

    $obj = $CLASS->new( -subclass => [qw/Foo Bar/] );
    isa_ok( $obj, $CLASS );
    is( $obj->package, "$CLASS\::__ANON__\::AAAAAAAAAC", "Third package" );
    isa_ok( $obj->package, 'Foo' );
    isa_ok( $obj->package, 'Bar' );

    $obj = $CLASS->new( -with_new => 1, -attributes => [qw/a b c/] );
    can_ok( $obj->package, qw/a b c/ );
    my $one = $obj->package->new;
    $one->a('a');
    is( $one->a, 'a', "get/set" );
};

tests override => sub {
    my $obj = $CLASS->new( foo => 'bar' );
    is( $obj->package->foo, 'bar', "original value" );
    $obj->override( 'foo', sub { 'baz' } );
    is( $obj->package->foo, 'baz', "overriden" );
    $obj->restore('foo');
    is( $obj->package->foo, 'bar', "original value" );

    $obj->override( bub => Mock::Quick::Method->new( sub { print "VVV\n", return [@_] } ) );
    is_deeply(
        $obj->package->bub( 'a', 'b' ),
        [$obj->package, 'a', 'b'],
        "got args"
    );

    $obj->override( 'bar', sub { 'xxx' } );
    is( $obj->package->bar, 'xxx', "overriden" );
    $obj->restore('bar');
    ok( !$obj->package->can('bar'), "original value is nill" );

    # Multiple overrides
    $obj->override( foo => sub { 'foo' }, bar => sub { 'bar' } );
    is $obj->package->foo => 'foo', "overriden";
    is $obj->package->bar => 'bar', "overriden";
    $obj->restore(qw/ foo bar /);
    is $obj->package->foo => 'bar', "original value";
    ok !$obj->package->can('bar'), "original value is nil";
};

tests undefine => sub {
    my $obj = $CLASS->new( foo => 'bar' );
    can_ok( $obj->package, 'foo' );
    $obj->undefine;
    no strict 'refs';
    ok( !keys %{$obj->package . '::'}, "anon package undefined" );
    ok( !$obj->package->can('foo'),    "no more foo method" );
};

tests takeover => sub {
    my $obj = $CLASS->takeover('Baz');
    is( Baz->foo, 'foo', 'original' );
    $obj->override( 'foo', sub { 'new foo' } );
    is( Baz->foo, 'new foo', "override" );
    $obj->restore('foo');
    is( Baz->foo, 'foo', 'original' );

    $obj = $CLASS->new( -takeover => 'Baz' );
    is( Baz->foo, 'foo', 'original' );
    $obj->override( 'foo', sub { 'new foo' } );
    is( Baz->foo, 'new foo', "override" );
    $obj = undef;
    is( Baz->foo, 'foo', 'original' );

    $obj = $CLASS->new( -takeover => 'Baz' );
    $obj->override(
        'foo',
        sub {
            my $class = shift;
            return "PREFIX: " . $class->MQ_CONTROL->original('foo')->();
        }
    );

    is( Baz->foo, "PREFIX: foo", "Override and accessed original through MQ_CONTROL" );
    $obj = undef;

    is( Baz->foo, 'foo', 'original' );
    ok( !Baz->can('MQ_CONTROL'), "Removed control" );

    $obj = $CLASS->takeover('Baz');
    my @warnings;
    {
        local $SIG{__WARN__} = sub { push @warnings => @_ };
        $obj->override('not_implemented', sub { 'xxx' });
    }
    is(@warnings, 1, "got a warnings");
    like($warnings[0], qr/Overriding non-existent method 'not_implemented'/, "Warning is what we wanted");
};

tests implement => sub {
    my $obj = $CLASS->implement( 'Foox', a => sub { 'a' }, -with_new => 1 );
    lives_ok { require Foox; 1 } "Did not try to load Foox";
    can_ok( 'Foox', 'new' );
    $obj->undefine();
    throws_ok { require Foox; 1 } qr/Can't locate Foox\.pm/, "try to load Foox";
    $obj = undef;

    $obj = $CLASS->new( -implement => 'Foox', a => sub { 'a' }, -with_new => 1 );
    lives_ok { require Foox; 1 } "Did not try to load Foox";
    can_ok( 'Foox', 'new' );
    ok( $obj, "Keeping it in scope." );
    $obj = undef;
    throws_ok { require Foox; 1 } qr/Can't locate Foox\.pm/, "try to load Foox";
};

run_tests;
done_testing;
