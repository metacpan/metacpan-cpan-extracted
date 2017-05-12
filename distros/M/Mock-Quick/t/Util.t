#!/usr/bin/perl
use strict;
use warnings;

use Fennec::Lite;
use Test::Exception;
use Mock::Quick::Method;
use Mock::Quick::Object;

BEGIN {
    tests load => sub {
        require_ok qw/Mock::Quick::Util/;
        lives_ok { Mock::Quick::Util->import() } "Import";
        can_ok( __PACKAGE__, @Mock::Quick::Util::EXPORT );
    };
    run_tests;
}

tests inject => sub {
    inject( 'main', 'blah', sub { 'blah' });
    can_ok( 'main', 'blah' );
    is( blah(), 'blah', "injected sub" );
};

tests obj_meth => sub {
    obj_meth foo => sub { 'foo' };
    can_ok( __PACKAGE__, 'foo' );
    dies_ok { __PACKAGE__->foo } "Class form dies";
    lives_and {
        is( bless( {}, __PACKAGE__ )->foo, 'foo', "Object form works" );
    } "Object form should not die.";
};

tests alt_meth => sub {
    alt_meth alpha => (
        obj => sub { 'o' },
        class => sub { 'c' },
    );
    is( __PACKAGE__->alpha, 'c', "Class version" );
    is( bless( {}, __PACKAGE__ )->alpha, 'o', "Object version" );
};

tests call => sub {
    my $ref = bless({}, 'Mock::Quick::Object');
    is( call( $ref, 'a' ), undef, "Not set" );
    is( call( $ref, 'a', 'a' ), 'a', "Alter" );
    is( call( $ref, 'a' ), 'a', "Altered" );
    is( call( $ref, 'a', \$Mock::Quick::Util::CLEAR ), undef, "Cleared" );
    is( call( $ref, 'a' ), undef, "Not set" );

    call( $ref, 'a', Mock::Quick::Method->new( sub { 'xxx' }));

    is( call( $ref, 'a', 'foo' ), 'xxx', "Called method" );
    is( call( $ref, 'a', \$Mock::Quick::Util::CLEAR ), undef, "Cleared" );
    is( call( $ref, 'a' ), undef, "Not set" );
};

tests class_meth => sub {
    my $ref = bless( { baz => 'baz' }, 'Mock::Quick::Object' );
    class_meth baz => sub { 'class baz' };
    is( $ref->baz, 'baz', "Object form" );
    is( __PACKAGE__->baz, 'class baz', "Class Form" );
};

run_tests;

tests purge => sub {
    purge_util();
    ok( !__PACKAGE__->can( $_ ), "$_ purged" )
        for @Mock::Quick::Util::EXPORT;
};
run_tests;

done_testing;
