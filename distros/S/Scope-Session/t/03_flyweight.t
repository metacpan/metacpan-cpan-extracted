#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 15;
use Test::MockObject;
use Scalar::Util qw/refaddr/;
BEGIN{
    use_ok('Scope::Session::Flyweight');
}

{
    package Test::Object;
    sub new {
        my ( $class, %args ) = @_;
        return bless {%args} => $class;
    }
    sub identifier {
        my ( $class, %args ) = @_;
        return $args{id};
    }
}
{
    package Test::Object::Singleton::Flyweighted;
    use Scope::Session::Flyweight acquire => 1;
    sub identifier {
        my ( $class, %args ) = @_;
        return $args{id};
    }

    sub new {
        my ( $class, %args ) = @_;
        return bless {%args} => $class;
    }

}

Scope::Session::start {
    my $flyweight
        = Scope::Session::Flyweight->acquire( q|Test::Object| => ( id => 10 ) );
    my $flyweight2
        = Scope::Session::Flyweight->acquire( q|Test::Object| => ( id => 10 ) );
    ::ok $flyweight ;
    ::ok $flyweight2 ;

    ::is
        refaddr $flyweight,
        refaddr $flyweight2;

    my $flyweight12
        = Scope::Session::Flyweight->acquire( q|Test::Object| => ( id => 12 ) );
    my $flyweight13
        = Scope::Session::Flyweight->acquire( q|Test::Object| => ( id => 13 ) );

    ::isnt 
        refaddr $flyweight12 ,
        refaddr $flyweight13 ;
};

Scope::Session::start {
    my $flyweight  = Test::Object::Singleton::Flyweighted->acquire( id => 10 );
    my $flyweight2 = Test::Object::Singleton::Flyweighted->acquire( id => 10 );

    ::ok $flyweight;
    ::ok $flyweight2;

    ::is 
        refaddr $flyweight,
        refaddr $flyweight2;

    my $flyweight12 = Test::Object::Singleton::Flyweighted->acquire( id => 12 );
    my $flyweight13 = Test::Object::Singleton::Flyweighted->acquire( id => 13 );

    ::isnt refaddr $flyweight12 , refaddr $flyweight13 ;

};

Scope::Session::start {
    my $flyweight = Test::Object::Singleton::Flyweighted->acquire( id => 15 );
    my $flyweight2 = Scope::Session::Flyweight->acquire(
        q|Test::Object::Singleton::Flyweighted| => ( id => 15 ) );

    ::ok $flyweight ;
    ::ok $flyweight2 ;

    ::is refaddr $flyweight, refaddr $flyweight2 ;
};

Scope::Session::start {
    my $flyweight = Test::Object::Singleton::Flyweighted->acquire( id => 15 );
    my $flyweight2
        = Scope::Session::Flyweight->acquire( q|Test::Object| => ( id => 15 ) );

    ::ok $flyweight ;
    ::ok $flyweight2 ;
    ::isnt refaddr $flyweight, refaddr $flyweight2 ;

};

