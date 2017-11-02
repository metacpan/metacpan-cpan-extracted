#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

# this comes up in, for instance, Plack::Middleware::wrap

package Foo {
    use Moxie;

    extends 'Moxie::Object';

    has _bar => ();

    my sub _bar : private;

    sub BUILDARGS : init( bar? => _bar );

    sub bar : ro(_bar);

    sub baz ($self, $bar) {
        if (ref($self)) {
            _bar = $bar;
        }
        else {
            $self = __PACKAGE__->new( bar => $bar );
        }

        return $self->bar;
    }
}

is(Foo->baz('BAR-class'), 'BAR-class');
is(Foo->new->baz('BAR-instance'), 'BAR-instance');

done_testing;
