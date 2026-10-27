use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;

# -------------------------------------------------------
# Test that hook resolution caching works correctly:
# - hooks fire on first and subsequent calls
# - subclass overrides resolve independently
# - role hooks are cached and dispatched correctly
# - builders (lazy getters) are cached
# - objects of the same class share the cache
# -------------------------------------------------------

{
    package CacheBase;
    use Simple::Accessor qw{alpha beta};

    my @log;
    sub get_log  { [@log] }
    sub clear_log { @log = () }

    sub _before_alpha {
        my ($self, $v) = @_;
        push @log, "before_alpha:$v";
        return 1;
    }

    sub _validate_alpha {
        my ($self, $v) = @_;
        push @log, "validate_alpha:$v";
        return $v ne 'bad';
    }

    sub _after_alpha {
        my ($self, $v) = @_;
        push @log, "after_alpha:$v";
        return 1;
    }

    sub _build_beta { 42 }
}

# --- Basic hook caching: hooks fire on every call ---
CacheBase->clear_log;
my $o1 = CacheBase->new;
$o1->alpha('first');
is_deeply( CacheBase->get_log,
    ['before_alpha:first', 'validate_alpha:first', 'after_alpha:first'],
    'all three hooks fire on first setter call' );

CacheBase->clear_log;
$o1->alpha('second');
is_deeply( CacheBase->get_log,
    ['before_alpha:second', 'validate_alpha:second', 'after_alpha:second'],
    'all three hooks fire on second setter call (cached path)' );

# --- Validation rejection still works after caching ---
CacheBase->clear_log;
my $o2 = CacheBase->new(alpha => 'ok');
CacheBase->clear_log;
$o2->alpha('bad');
is $o2->alpha, 'ok', 'validate rejection works with cached hooks';
is_deeply( CacheBase->get_log,
    ['before_alpha:bad', 'validate_alpha:bad'],
    'after hook not called when validate rejects (cached)' );

# --- Builder caching ---
my $o3 = CacheBase->new;
is $o3->beta, 42, 'builder fires on first object';
my $o4 = CacheBase->new;
is $o4->beta, 42, 'builder fires on second object (cached builder path)';

# --- No-hook attribute: fast path after cache miss ---
my $o5 = CacheBase->new;
$o5->beta(99);
is $o5->beta, 99, 'no-hook attribute works after cache records absence';
$o5->beta(100);
is $o5->beta, 100, 'no-hook attribute works on repeated calls';

# --- Subclass with hook override caches independently ---
{
    package CacheChild;
    our @ISA = ('CacheBase');
    use Simple::Accessor qw{gamma};

    my @child_log;
    sub get_child_log  { [@child_log] }
    sub clear_child_log { @child_log = () }

    sub _before_alpha {
        my ($self, $v) = @_;
        push @child_log, "child_before_alpha:$v";
        return 1;
    }
}

# warm up parent's cache
my $parent = CacheBase->new;
$parent->alpha('p');

# child should use its own override, not parent's cached version
CacheChild->clear_child_log;
CacheBase->clear_log;
my $child = CacheChild->new;
$child->alpha('c');
is_deeply( CacheChild->get_child_log, ['child_before_alpha:c'],
    'subclass override is cached independently from parent' );
my $parent_log = CacheBase->get_log;
ok( !grep(/before_alpha:c/, @$parent_log),
    'parent hook not called for child objects' );

# --- Role hook caching ---
{
    package RoleForCache;
    use Simple::Accessor qw{rattr};

    my @rlog;
    sub get_rlog  { [@rlog] }
    sub clear_rlog { @rlog = () }

    sub _validate_rattr {
        my ($self, $v) = @_;
        push @rlog, "role_validate:$v";
        return $v > 0;
    }

    sub _build_rattr { 10 }
}

{
    package CacheWithRole;
    use Simple::Accessor qw{own};

    with 'RoleForCache';
}

RoleForCache->clear_rlog;
my $r1 = CacheWithRole->new;
is $r1->rattr, 10, 'role builder fires (first call)';

$r1->rattr(5);
is_deeply( RoleForCache->get_rlog, ['role_validate:5'],
    'role hook fires via cache on first setter' );

RoleForCache->clear_rlog;
$r1->rattr(3);
is_deeply( RoleForCache->get_rlog, ['role_validate:3'],
    'role hook fires via cache on second setter' );

RoleForCache->clear_rlog;
$r1->rattr(-1);
is $r1->rattr, 3, 'role validate rejection works with cache';

# --- Multiple objects share cache ---
CacheBase->clear_log;
my @objects = map { CacheBase->new } 1..5;
for my $i (0..4) {
    $objects[$i]->alpha("v$i");
}
my $all_log = CacheBase->get_log;
is scalar(@$all_log), 15, '5 objects x 3 hooks = 15 log entries (cache shared)';

done_testing;
