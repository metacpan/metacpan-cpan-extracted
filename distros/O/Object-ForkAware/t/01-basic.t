use strict;
use warnings;

use Test::More 'no_plan';    # the test count is different in each process
use Test::Warnings 0.009 qw(:all :no_end_test);
use Test::Fatal;

use Object::ForkAware;

use lib 't/lib';
use PidTracker;

my $Test = Test::Builder->new;

# give ourselves a predictable version
$Object::ForkAware::VERSION = '999';

{
    # the failure case...

    my $obj = PidTracker->new;
    is($obj->pid, $$, 'object was created in the current process');
    is($obj->instance, 0, 'this is instance #0');

    looks_like_a_pidtracker($obj);

    my $parent_pid = $$;
    my $child_pid = fork;

    if (not defined $child_pid)
    {
        die 'cannot fork: ', $!;
    }
    elsif ($child_pid == 0)
    {
        # child

        isnt($obj->pid, $$, 'object no longer has the right pid');
        is($obj->instance, 0, 'object is still instance #0');
        had_no_warnings;
        exit;
    }

    $Test->current_test($Test->current_test + 3);

    # make sure we do not continue until after the child process exits
    isnt(waitpid($child_pid, 0), '-1', 'waited for child to exit');
}

$PidTracker::instance = -1;
{
    # now wrap in a ForkAware object and watch the magic!

    my $obj = Object::ForkAware->new(create => sub { PidTracker->new });

    is($PidTracker::instance, 0, 'an object has been instantiated already');

    looks_like_a_pidtracker($obj);

    is($obj->pid, $$, 'object was created in the current process');
    is($obj->instance, 0, 'this is instance #0');

    # now fork and see what happens

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
        SKIP: {
            skip 'perl 5.9.4 required for ->DOES', 1 if "$]" < '5.009004';
            ok($obj->DOES('Object::ForkAware'), 'object does the ForkAware role')
        }

        looks_like_a_pidtracker($obj);
        is($obj->pid, $$, 'object was created in the current process');
        is($obj->instance, 1, 'this is now instance #1');

        had_no_warnings;
        exit;
    }

    $Test->current_test($Test->current_test + 13);

    # make sure we do not continue until after the child process exits
    isnt(waitpid($child_pid, 0), '-1', 'waited for child to exit');
}

{
    like(
        exception { Object::ForkAware->new },
        qr/missing required option: create/,
        'create is required',
    );

    is(Object::ForkAware->VERSION, '999', 'got the right version');
    ok(eval { Object::ForkAware->VERSION('998'); 1 }, 'VERSION with args also works');
}

sub looks_like_a_pidtracker
{
    my $obj = shift;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    # somehow, Test::More loses its marbles here during subtests and emits an
    # extra plan in the middle!
    #subtest 'object quacks like a PidTracker' => sub {
        ok($obj->isa('PidTracker'), '->isa works as if we called it on the target object');
        SKIP: {
            skip 'perl 5.9.4 required for UNIVERSAL::DOES', 1 if "$]" < '5.009004';
            ok($obj->DOES('PidTracker'), '->DOES works as if we called it on the target object')
        }
        ok($obj->can('foo'), '->can works as if we called it on the target object');
        is($obj->can('foo'), \&PidTracker::foo, '...and returns the correct reference');
        is($obj->foo, 'a sub that returns foo', 'method responds properly');
        is($obj->VERSION, '1.234', "got the object's version, not Object::ForkAware's");
        ok(!eval { $obj->VERSION('10'); 1 }, 'VERSION with args also propagates');
    #};
}

had_no_warnings;
