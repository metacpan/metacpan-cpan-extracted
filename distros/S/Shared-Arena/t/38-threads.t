#!perl
use strict;
use warnings;
use Config;
use Test::More;
use Shared::Arena ();

# A THREAD GETS NO COPY OF ANY HANDLE.
#
# Every object here is a C pointer in a blessed scalar. Cloning the interpreter
# used to clone the scalar and share the pointer, so the thread's copy and the
# original each freed it when they went - and the thread's copy of the region
# unmapped the arena under the thread that created it. CLONE_SKIP makes the
# thread's copies inert, and a thread that wants the arena attaches by name.
#
# The assertion that matters is the one after the join: the creating thread
# still reads its own cache once the other thread has come and gone. Without the
# skip it would be reading a region that had been unmapped.
#
# Not a test of Shared::Arena::Lease across threads: a lease is held per
# process, and two threads share one pid.

plan skip_all => 'this perl has no ithreads' unless $Config{useithreads};
plan skip_all => 'no atomics in this build' unless Shared::Arena::have_atomics();
plan skip_all => 'named regions are POSIX or Windows only' if $^O eq 'cygwin';
require threads;

my $name  = "sa-threads-$$";
Shared::Arena->destroy($name);   # a previous run that died holding it
my $arena = Shared::Arena->create(size => 1 << 20, name => $name);
my $cache = $arena->cache('c', capacity => 64);
$cache->set('k', 'from the creator');

my @seen = threads->create({ context => 'list' }, sub {
    my @r = (ref($arena), ref($cache));
    my $again = Shared::Arena->attach($name);
    my $c2    = $again ? $again->cache('c', capacity => 64) : undef;
    push @r, $c2 ? scalar $c2->get('k') : 'no attach';
    $c2->set('t', 'from the thread') if $c2;
    return @r;
})->join;

isnt($seen[0], 'Shared::Arena', 'the thread got no live copy of the region');
isnt($seen[1], 'Shared::Arena::Cache', 'nor of the cache');
is($seen[2], 'from the creator', 'but it attached by name and read what was there');

is(scalar $cache->get('k'), 'from the creator',
   'and after the thread has gone the creator still reads its own cache');
is(scalar $cache->get('t'), 'from the thread', 'including what the thread wrote');

for my $class (map { "Shared::Arena$_" } '', qw(
    ::Ring ::Ring::Cursor ::Ring::Group ::Map ::Bloom ::Histogram ::Cache
    ::Rate ::CountMin ::Frozen ::Frozen::View ::Cuckoo ::Lease ::Scoreboard))
{
    ok($class->can('CLONE_SKIP') && $class->CLONE_SKIP,
       "$class is not cloned into a new thread");
}

Shared::Arena->destroy($name);
done_testing;
