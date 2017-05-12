use strict;
use warnings;

use Test::More tests => 14;
use Test::Warnings;

use Object::ForkAware;

use lib 't/lib';
use PidTracker;

my $Test = Test::Builder->new;

{
    # lazy, access before fork

    my $obj = Object::ForkAware->new(
        create => sub { PidTracker->new },
        lazy => 1,
    );

    is($PidTracker::instance, -1, 'no instances have been created yet');
    is($obj->instance, 0, 'this is instance #0');

    my $parent_pid = $$;
    my $child_pid = fork;

    if (not defined $child_pid)
    {
        die 'cannot fork: ', $!;
    }
    elsif ($child_pid == 0)
    {
        # child

        isnt($$, $parent_pid, 'we are no longer the same process');

        ok($obj->isa('Object::ForkAware'), 'object is ForkAware');

        is($obj->pid, $$, 'object was created in the current process');
        is($obj->instance, 1, 'this is now instance #1');
        exit;
    }

    # make sure we do not continue until after the child process exits
    waitpid($child_pid, 0);
    $Test->current_test($Test->current_test + 5);
}

$PidTracker::instance = -1;

{
    # lazy, no access before fork

    my $obj = Object::ForkAware->new(
        create => sub { PidTracker->new },
        lazy => 1,
    );

    is($PidTracker::instance, -1, 'no instances have been created yet');

    my $parent_pid = $$;
    my $child_pid = fork;

    if (not defined $child_pid)
    {
        die 'cannot fork: ', $!;
    }
    elsif ($child_pid == 0)
    {
        # child

        isnt($$, $parent_pid, 'we are no longer the same process');

        ok($obj->isa('Object::ForkAware'), 'object is ForkAware');
        is($obj->pid, $$, 'object was created in the current process');
        is($obj->instance, 0, 'this is now instance #0');
        exit;
    }

    # make sure we do not continue until after the child process exits
    waitpid($child_pid, 0);
    $Test->current_test($Test->current_test + 5);
}

