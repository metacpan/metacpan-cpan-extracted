use strict;
use warnings;

use Test::More tests => 16;
use Test::Warnings;
use Test::Fatal;

use Object::ForkAware;

use lib 't/lib';
use PidTracker;

my $Test = Test::Builder->new;

{
    # on_fork handler that dies

    my $obj = Object::ForkAware->new(
        create => sub { PidTracker->new },
        on_fork => sub { die 'we forked with instance #' . shift->instance },
    );

    is($obj->pid, $$, 'object was created in the current process');
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

        like(
            exception { $obj->foo },
            qr/we forked with instance #0/,
            'on_fork sub called when used after a fork',
        );

        is($obj->{_obj}->instance, 0, 'on_fork sub died, so we did not regenerate object');
        isnt($obj->{_pid}, $$, 'on_fork sub died, so we did not update pid');
        exit;
    }

    # make sure we do not continue until after the child process exits
    waitpid($child_pid, 0);
    $Test->current_test($Test->current_test + 5);
}

$PidTracker::instance = -1;
{
    # on_fork handler that returns a new object

    my $obj = Object::ForkAware->new(
        create => sub { PidTracker->new },
        on_fork => sub { PidTracker->new(recreated_from => shift) },
    );

    is($obj->pid, $$, 'object was created in the current process');
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

        ok($obj->isa('PidTracker'), 'object type is still correct');

        is($obj->pid, $$, 'object was created in the current process');
        is($obj->instance, 1, 'this is now instance #1');
        is($obj->recreated_from->instance, 0, 'on_fork handler was passed the old object');
        exit;
    }

    # make sure we do not continue until after the child process exits
    waitpid($child_pid, 0);
    $Test->current_test($Test->current_test + 6);
}

