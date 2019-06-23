#!/usr/bin/env perl

package Quiq::Object::Test;
use base qw/Quiq::Test::Class/;

use strict;
use warnings;
use v5.10.0;
use utf8;

# -----------------------------------------------------------------------------

sub test_loadClass : Init(1) {
    shift->useOk('Quiq::Object');
}

# -----------------------------------------------------------------------------

sub test_bless : Test(1) {
    my $self = shift;

    my $class = 'Quiq::Hash';

    my $ref = $class->bless({});
    $self->is(ref($ref),$class);
}

# -----------------------------------------------------------------------------

sub test_rebless : Test(1) {
    my $self = shift;

    my $obj = Quiq::Hash->new;

    my $class = 'Quiq::Object';
    $obj->rebless($class);
    $self->is(ref($obj),$class);
}

# -----------------------------------------------------------------------------

Quiq::Perl->createClass('MyClass','Quiq::Object');

sub test_parameters_0 : Test(4) {
    my $self = shift;

    MyClass->addMethod(myMethod => sub {
        my ($class,$arg1,$arg2) = splice @_,0,3;

        my $opt1 = 1;
        my $opt2 = 2;

        $class->parameters(\@_,
            opt1 => \$opt1,
            opt2 => \$opt2,
        );

        return "$arg1,$arg2,$opt1,$opt2";
    });

    my $val = MyClass->myMethod('a','b');
    $self->is($val,"a,b,1,2");

    $val = MyClass->myMethod('a','b',-opt1=>'x');
    $self->is($val,"a,b,x,2");

    $val = MyClass->myMethod('a','b',-opt2=>'x');
    $self->is($val,"a,b,1,x");

    eval{MyClass->myMethod('a','b',-opt3=>'x')};
    $self->ok($@);
}

sub test_parameters_1 : Test(4) {
    my $self = shift;

    MyClass->addMethod(myMethod => sub {
        my ($class,$arg1,$arg2) = splice @_,0,3;

        my $opt1 = 1;
        my $opt2 = 2;

        $class->parameters(1,\@_,
            opt1 => \$opt1,
            opt2 => \$opt2,
        );

        return "$arg1,$arg2,$opt1,$opt2,@_";
    });

    my $val = MyClass->myMethod('a','b');
    $self->is($val,"a,b,1,2,");

    $val = MyClass->myMethod('a','b',-opt1=>'x');
    $self->is($val,"a,b,x,2,");

    $val = MyClass->myMethod('a','b',-opt2=>'x');
    $self->is($val,"a,b,1,x,");

    $val = MyClass->myMethod('a','b',-opt3=>'x');
    $self->is($val,"a,b,1,2,-opt3 x");
}

sub test_parameters_2 : Test(6) {
    my $self = shift;

    MyClass->addMethod(myMethod => sub {
        my $class = shift;

        my $opt1 = 1;
        my $opt2 = 2;

        my $argA = $class->parameters(1,3,\@_,
            opt1 => \$opt1,
            opt2 => \$opt2,
        );

        return join ',',@$argA,$opt1,$opt2;
    });

    my $val = MyClass->myMethod('a','b');
    $self->is($val,"a,b,1,2");

    $val = MyClass->myMethod('a','b','c',-opt1=>'x');
    $self->is($val,"a,b,c,x,2");

    $val = MyClass->myMethod('a','b',-opt2=>'x');
    $self->is($val,"a,b,1,x");

    eval{MyClass->myMethod('a','b',-opt3=>'x')};
    $self->ok($@);

    eval{MyClass->myMethod(-opt2=>'x')};
    $self->ok($@);

    eval{MyClass->myMethod('a','b','c','d',-opt2=>'x')};
    $self->ok($@);
}

# -----------------------------------------------------------------------------

sub test_addMethod : Test(2) {
    my $self = shift;

    # Wir nutzen die Klasse selbst als Testklasse
    my $testClass = 'Quiq::Object';

    # instantiiere Objekt

    my $h = bless {},$testClass;
    $self->is(ref($h),$testClass);

    # füge Methode hinzu

    $h->addMethod('myMethod',sub {
        my $self = shift;
        return 4711;
    });

    # rufe Methode auf

    my $r = $h->myMethod;
    $self->is($r,4711);
}

# -----------------------------------------------------------------------------

sub test_classFile : Test(1) {
    my $self = shift;

    my $path = 'Quiq::Object';
    $path =~ s|::|/|g;

    my $file = Quiq::Object->classFile;
    $self->like($file,qr|$path|);
}

# -----------------------------------------------------------------------------

sub test_this_scalar : Test(2) {
    my $self = shift;

    my $this = 'Quiq::Hash';
    my $class = Quiq::Object->this($this);
    $self->is($class,'Quiq::Hash');

    $this = Quiq::Hash->new;
    $class = Quiq::Object->this($this);
    $self->is($class,'Quiq::Hash');
}

sub test_this_list : Test(6) {
    my $self = shift;

    my $this = 'Quiq::Hash';
    my ($class,$obj,$isClassMethod) = Quiq::Object->this($this);
    $self->is($class,'Quiq::Hash');
    $self->is($obj,undef);
    $self->ok($isClassMethod);

    $this = Quiq::Hash->new;
    ($class,$obj,$isClassMethod) = Quiq::Object->this($this);
    $self->is($class,'Quiq::Hash');
    $self->is(ref($obj),'Quiq::Hash');
    $self->ok(!$isClassMethod);
}

# -----------------------------------------------------------------------------

package main;
Quiq::Object::Test->runTests;

# eof
