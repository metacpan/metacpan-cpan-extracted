#!/usr/bin/env perl

use strict;
use Test::More tests => 7;
use Test::Mouse;

SKIP: {

      skip 'MouseX::POE::Role is currently borken', 7;

{
    package Rollo;
    use MouseX::POE::Role;

    sub foo { ::pass('foo!')}

    event yarr => sub { ::pass("yarr!"); shift->yield('matey'); };
    event matey => sub { ::pass("matey!") };

}

{
    package App;
    use MouseX::POE;

    with qw(Rollo);

    sub START {
        my ($self) = $_[OBJECT];
        ::pass('START');
        $self->foo();
        $self->yield('next');
    }

    event next => sub {
        my ($self) = $_[OBJECT];
        ::pass('next');
        $self->yield("yarr");
    };

    sub STOP { ::pass('STOP') }
}

my $obj = App->new;

does_ok($obj, 'Rollo');
POE::Kernel->run;

}
