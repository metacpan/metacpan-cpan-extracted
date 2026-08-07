#!perl
use 5.010;
use strict;
use warnings;
use Config;
use Test::More;
use Template::Stencil;

# Fork is the production model (Hyperman workers): the child inherits
# the engine memory wholesale and renders independently. Windows has no
# fork - perl emulates it with an ithread, which exercises the clone path
# below rather than the COW-inherit path this block is here to check.
SKIP: {
    skip 'no real fork on this platform', 3 if $^O eq 'MSWin32';
    my $s = Template::Stencil->new;
    is($s->render('{% v %}', { v => 'pre' }), 'pre', 'parent warm');
    my $pid = open my $rd, '-|';
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        print $s->render('{% v %}', { v => 'child' });
        exit 0;
    }
    my $got = do { local $/; <$rd> };
    close $rd;
    is($got, 'child', 'render in forked child');
    is($s->render('{% v %}', { v => 'post' }), 'post',
       'parent still renders after child exit');
}

# ithreads: a cloned object lazily rebuilds its own engine (fresh
# cache) from its cloned options; the parent's engine is untouched.
SKIP: {
    skip 'no ithreads in this perl', 4
        unless $Config{useithreads} && eval { require threads; 1 };
    my $s = Template::Stencil->new(filters => { up => sub { uc $_[0] } });
    is($s->render('{% v | up %}', { v => 'a' }), 'A', 'parent renders');
    my $thr = threads->create(sub {
        my $out = eval { $s->render('{% v | up %}', { v => 'b' }) };
        return $@ ? "ERR:$@" : $out;
    });
    my $res = $thr->join;
    is($res, 'B', 'cloned object renders in thread');
    is($s->render('{% v | up %}', { v => 'c' }), 'C',
       'parent renders after join');
    my $thr2 = threads->create(sub { 1 });
    $thr2->join;
    pass('clone + join with no use does not crash');
}

done_testing;
