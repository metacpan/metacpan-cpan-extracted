#!/usr/bin/perl

##
## Test for wrapping abilities of Object::Destroyer
##

use strict;
use warnings;

use Test::More;
use Object::Destroyer;

my $foo = Foo->new;
my $sentry = Object::Destroyer->new($foo, 'release');

##
## isa tests
##
isa_ok( $foo, 'Foo' );
isa_ok( $foo, 'Bar' );
isa_ok( $sentry, 'Foo' );
isa_ok( $sentry, 'Bar' );
isa_ok( $sentry, 'Object::Destroyer' );
ok(!$sentry->isa('BAZ'));

##
## can tests
##
can_ok($foo, 'hello');
can_ok($foo, 'bar');

can_ok($sentry, 'hello');
can_ok($sentry, 'release');
can_ok($sentry, 'self_test');
can_ok($sentry, 'params_count');
can_ok($sentry, 'bar');
ok(!$sentry->can('impossible'));

##
## Check that arguments are passed normally
##
ok( $foo->self_test );
ok( $sentry->self_test );
is( $foo->params_count(1,1,1), 3);
is( $sentry->params_count(1,1,1), 3);

##
## Check that results are returned correctly
##
is( $foo->hello, 'Hello World!', 'Foo->hello returns as expected' );
is( $sentry->hello, 'Hello World!' );
is( $foo->hello('Bob'), 'Hello Bob!', 'Foo->hello(args) returns as expected' );
is( $sentry->hello('Bob'), 'Hello Bob!');

is(scalar($foo->test_context), -1);
is(scalar($sentry->test_context), -1);
is_deeply([$foo->test_context], [1, 2]);
is_deeply([$sentry->test_context], [1, 2]);

$_ = 0;
$foo->test_context; ## void context
is($_, 1);

##
## Test that $sentry->new will pass to Foo->new
##
my $new = $sentry->new;
is(ref $new, 'Foo');

##
## Test that AUTOLOAD handles errors correctly
##
eval { $sentry->impossible };
like(
    $@,
    qr/Can't locate object method "impossible"/,
    'AUTOLOAD handles errors correctly'
);

eval {
    $sentry->DESTROY;
    $sentry->impossible;
};
like(
    $@,
    qr/Can't locate object to call method 'impossible'/,
    'AUTOLOAD cannot find method after DESTROY'
);

$sentry = Object::Destroyer->new(sub { 123; });
eval { $sentry->impossible };
like(
    $@,
    qr/Can't locate object to call method 'impossible'/,
    'AUTOLOAD cannot find method when there is no object'
);

isnt(
    ref($sentry->can('foo')),
    'CODE',
    'can does not pass through without object'
);

##
## Test for AUTOLOAD'ed methods
##
my $buzz = Buzz->new();
$sentry = Object::Destroyer->new($buzz);
is( scalar($sentry->test(1)), "test");
is( scalar($sentry->foo), "foofoo");
is( scalar($sentry->bar(3)), "barbarbar");
is_deeply( [$sentry->bar], ["bar", "bar"]);
is_deeply( [$sentry->foo(1)], ["foo"]);
is_deeply( [$sentry->t(3)], [qw/t t t/]);
eval {
    $sentry->void;
    return;
};
ok !$@, 'AUTOLOAD in void context works';


done_testing;

#####################################################################
# Test Classes

package Foo;

use vars qw{$destroy_counter @ISA};
BEGIN { $destroy_counter = 0; @ISA = 'Bar' };

sub new {
    my $class = ref $_[0] ? ref shift : shift;
    my $self = bless {}, $class;
    $self->{self} = $self; ## This is a circular reference
    return $self;
}

sub self_test{
    my $self = shift;
    return $self==$self->{self};
}

sub params_count{
    my $self = shift;
    return scalar(@_);
}

sub hello {
    shift;
    return (@_) ? "Hello $_[0]!" : "Hello World!"
}

sub test_context{
    return  (wantarray) ? (1, 2) :
            (defined wantarray) ? -1 : ++$_;
}

sub DESTROY {
    $destroy_counter++;
}

sub release{
    my $self = shift;
    undef $self->{self};
}

package Bar;
sub bar {}

package Buzz;
sub new{
    my $class = shift;
    return bless {}, ref $class || $class;
}
use vars '$AUTOLOAD';

sub AUTOLOAD{
    my $self = shift;
    my $repeat_number = shift || 2;

    my ($method) = $AUTOLOAD =~ /.*::(.*)$/;
    return (wantarray) ?
        ($method) x $repeat_number :
        $method   x $repeat_number;
}

sub DESTROY{
}

1;