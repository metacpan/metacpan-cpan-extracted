#!/usr/bin/env perl

=head1 DESCRIPTION

Verify that forward dependencies are an error.

=cut

use strict;
use warnings;
use Test::More;
use Test::Exception;

throws_ok {
    use Resource::Silo;
    resource foo =>
        dependencies => ['bar'],
        init => sub { $_[0]->bar * 2 };
    resource bar =>
        init => sub { 2 };
} qr(^resource 'foo': .*loose_deps), "no forward declaration";

is_deeply [ silo->ctl->meta->list ], [], "no resources declared this far";

lives_and {
    use Resource::Silo;
    resource foo =>
        dependencies => ['bar'],
        loose_deps => 1,
        init => sub { $_[0]->bar * 2 };
    resource bar =>
        init => sub { 2 };

    is silo->foo, 4;
} "explicitly allowed forward declaration";

done_testing;
