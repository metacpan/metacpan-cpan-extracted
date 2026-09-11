#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Shared::Arena ();

# Creating, attaching, carving, and every refusal.
#
# The refusals matter as much as the successes: this dist's rule is that a
# region it cannot safely use is a region it declines, never one it uses
# anyway. A caller is expected to degrade.

plan skip_all => 'no atomics in this build' unless Shared::Arena::have_atomics();

# ---- anonymous, which is the inherited case -------------------------------
{
    my $a = Shared::Arena->create(size => 128 * 1024);
    ok($a, 'created an anonymous region');
    ok($a->created, 'and this process created it');
    cmp_ok($a->size, '>=', 128 * 1024,
           'it is at least the size asked for - the header is added to the '
         . 'request, not taken out of it');

    my ($off, $len) = $a->region('counters', size => 1024);
    ok($off, 'carved a region');
    is($len, 1024, 'of the size asked for');
    is($off % 16, 0, 'aligned');

    # Carving the same name again finds it rather than carving a second one.
    # That is what lets every process run the same setup code without one of
    # them having to be special.
    my ($off2, $len2) = $a->region('counters', size => 1024);
    is($off2, $off, 'carving the same name again returns the same region');
    is($len2, $len, 'with the same length');
    is_deeply([$a->regions], ['counters'], 'and it was carved once, not twice');

    my ($o3) = $a->region('other', size => 1024);
    isnt($o3, $off, 'a different name gets a different region');
    cmp_ok($o3, '>=', $off + $len, 'that does not overlap the first');

    is_deeply([$a->region('nope')], [], 'asking for a name never carved is an empty list');
}

# ---- what is refused -------------------------------------------------------
{
    my $a = Shared::Arena->create(size => 64 * 1024);

    is_deeply([$a->region('', size => 16)], [],
              'an empty name is refused');
    is_deeply([$a->region('x' x 32, size => 16)], [],
              'a name that does not fit the registry is refused');
    is_deeply([$a->region('huge', size => 1024 * 1024 * 1024)], [],
              'a carve larger than the region is refused');

    # And the refusal did not consume the space it could not use, which is the
    # reason the bump is a compare-and-swap rather than a fetch-add.
    my ($off) = $a->region('after', size => 1024);
    ok($off, 'a carve that fits still succeeds after one that did not');
}

# ---- across a fork, which is what anonymous mode is for --------------------
SKIP: {
    skip 'fork is POSIX-only here', 3 if $^O eq 'MSWin32';

    my $a = Shared::Arena->create(size => 128 * 1024);
    my ($off) = $a->region('handoff', size => 256);
    $a->poke('handoff', 0, 'parent was here');

    my $pid = fork();
    defined $pid or skip 'fork failed', 3;
    if (!$pid) {
        # The child inherits the mapping. Read what the parent wrote, answer,
        # and leave without running the parent's END blocks or its plan.
        my $seen = $a->peek('handoff', 0, 15);
        $a->poke('handoff', 64, $seen eq 'parent was here' ? 'child read it' : 'child saw junk');
        POSIX::_exit(0) if eval { require POSIX; 1 };
        exit 0;
    }
    waitpid $pid, 0;
    is($?, 0, 'the child exited cleanly');
    is($a->peek('handoff', 64, 13), 'child read it',
       'the child read what the parent wrote before the fork');
    is($a->peek('handoff', 0, 15), 'parent was here',
       'and the parent still sees its own bytes');
}

# ---- named, and destroy ----------------------------------------------------
SKIP: {
    my $name = "sa-map-$$";
    Shared::Arena->destroy($name);

    my $a = Shared::Arena->create(name => $name, size => 64 * 1024)
        or skip 'named regions unavailable in this build', 5;

    ok($a->created, 'created a named region');

    my $b = Shared::Arena->attach($name);
    ok($b, 'attached it by name');
    ok(!$b->created, 'and the attacher knows it did not create it');
    is($b->size, $a->size, 'and sees the same size, which came from the header '
                         . 'rather than from what the attacher guessed');

    ok(!Shared::Arena->attach("$name-does-not-exist"),
       'attaching a name that does not exist returns undef rather than croaking');

    undef $a;
    undef $b;
    Shared::Arena->destroy($name);
}

done_testing;
