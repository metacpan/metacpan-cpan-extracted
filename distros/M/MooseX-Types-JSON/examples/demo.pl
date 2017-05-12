#!/usr/bin/perl

{
    package Foo;

    use Moose;
    use Moose::Util::TypeConstraints;
    use MooseX::Types::JSON qw( JSON relaxedJSON );
    
    has data_strict  => ( is => 'rw', isa => JSON        );
    has data_relaxed => ( is => 'rw', isa => relaxedJSON );
    has data_coerced => ( is => 'rw', isa => JSON, coerce => 1 );
}

my $foo = Foo->new(
    data_strict  => qq| { "foo": "bar", "answer": "42"  } |,
    data_relaxed => qq| { "foo": "bar", "answer": "42", } |,
    data_coerced => { foo => "bar", answer => 42 },
);

print $foo->dump;