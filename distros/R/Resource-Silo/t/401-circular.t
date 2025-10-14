#!/usr/bin/env perl

=head1 DESCRIPTION

Ensure circular dependencies don't go wild

=cut

use strict;
use warnings;
use Test::More;
use Test::Exception;

subtest 'simple class, no forward deps' => sub {
    {
        package My::Project;
        use Resource::Silo -class;

        resource foo   =>
            init       => sub {$_[0]->bar};
        resource bar   =>
            init       => sub {$_[0]->foo};
    }

    subtest 'throws like it should' => sub {
        my $file = quotemeta __FILE__;
        my $line;

        throws_ok {
            # force fatal warnings
            local $SIG{__WARN__} = sub {die $_[0]};
            my $inst = My::Project->new;
            $line = __LINE__ + 1;
            $inst->foo;
        } qr/[Cc]ircular dependency/, 'circularity detected';

        like $@, qr($file line $line), 'error attributed correctly';

        note $@;
    };

    subtest 'ok if resource is substituted' => sub {
        lives_and {
            # force fatal warnings
            local $SIG{__WARN__} = sub {die $_[0]};
            my $inst = My::Project->new(bar => 42);
            is $inst->foo, 42, 'foo deduced from bar';
        };
    };
};

subtest 'forward dependencies end up in a loop' => sub {
    throws_ok {
        package My::Loop;
        use Resource::Silo -class;

        resource l1      =>
            dependencies => [ 'l2' ],
            init         => sub { ... };
        resource l2      =>
            dependencies => [ 'l3' ],
            init         => sub { ... };
        resource l3      =>
            dependencies => [ 'l4' ],
            init         => sub { ... };
        resource l4 =>
            dependencies => [ 'l1' ],
            init         => sub { ... };

        1;
    } qr/[Cc]ircular dependency/, 'circularity detected in forward deps';

    throws_ok {
        My::Loop->new;
    } qr/[Uu]nsatisf|dependencies.*declared/, "Unsitisfied dependencies = no go";

    note $@;
    my $meta = Resource::Silo->get_meta('My::Loop');
    is_deeply [ sort $meta->list ], [ sort qw[l1 l2 l3] ], 'three resources defined before failure';
};

done_testing;
