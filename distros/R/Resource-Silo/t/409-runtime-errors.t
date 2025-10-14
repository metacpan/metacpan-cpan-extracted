#!/usr/bin/env perl

=head1 DESCRIPTION

Showcase bad DSL leading to a runtime expection.

=cut

use strict;
use warnings;
use Test::More;
use Test::Exception;

subtest 'unlisted dependency requested' => sub {
    {
        package My::App1;
        use Resource::Silo -class;

        resource foo =>
            dependencies    => [],
            init            => sub { $_[0]->bar };
        resource bar =>
            sub { 42 };
    };

    my $inst = My::App1->new;

    throws_ok {
        $inst->foo;
    } qr('bar'.*unexpected.*'foo'), "Can't depend on unlisted dependency";

    throws_ok {
        $inst->bar;
        $inst->foo;
    } qr('bar'.*unexpected.*'foo'), "Event if it was cached";
};

done_testing;
