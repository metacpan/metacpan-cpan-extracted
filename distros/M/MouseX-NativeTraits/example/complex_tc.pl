#!perl -w
use strict;
{
    package Foo;
    use Any::Moose;
    use Any::Moose '::Util::TypeConstraints';

    subtype 'ArrayRef3',
        as 'ArrayRef',
        where { @{$_} <= 3 };

    has 'a3' => (
        is  => 'rw',
        isa => 'ArrayRef3',

        traits => ['Array'],

        handles => {
            push => 'push',
        },
        default => sub { [] },
    );

    no Any::Moose '::Util::TypeConstraints';
    no Any::Moose;
}

my $foo = Foo->new;
eval {
    $foo->push($_) for 10 .. 20;
    1;
} or warn $@;

print $foo->dump;

