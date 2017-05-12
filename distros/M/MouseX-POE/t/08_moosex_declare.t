#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Mouse;

BEGIN {
  eval "use MouseX::Declare;";
  plan skip_all => "MouseX::Declare not installed; skipping" if $@;
}

plan tests => 6;


role Rollo {
    use MouseX::POE::Role qw(event);

    sub foo { ::pass('foo!')}

    event yarr => sub { ::pass("yarr!") }
}

does_ok(Rollo->meta, "MouseX::POE::Meta::Role");

class App with Rollo {
    use MouseX::POE::SweetArgs qw(event);

    sub START {
        my ($self) = @_;
        ::pass('START');
        $self->foo();
        $self->yield('next');
    }

    event next => sub {
        my ($self) = @_;
        ::pass('next');
        $self->yield("yarr");
    };

    sub STOP { ::pass('STOP') }
}

my $obj = App->new;

POE::Kernel->run;
