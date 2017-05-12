use strict;
use warnings;
use Test::More;
use Test::LeakTrace;

use NgxQueue;

diag "Test for: " . NgxQueue::BACKEND;

my $q = NgxQueue->new;
ok $q->empty;

# insert tail
$q->insert_tail( NgxQueue->new('foo') );
ok !$q->empty;

is $q->head->data, 'foo';
is $q->last->data, 'foo';

$q->head->remove;
ok $q->empty;


# insert head
$q->insert_head( NgxQueue->new('bar') );
ok !$q->empty;

is $q->head->data, 'bar';
is $q->last->data, 'bar';

$q->head->remove;
ok $q->empty;


# insert after
$q->insert_after( NgxQueue->new('bar') );
ok !$q->empty;

is $q->head->data, 'bar';
is $q->last->data, 'bar';

$q->head->remove;
ok $q->empty;


# insert multi
$q->insert_tail( NgxQueue->new('foo') );
$q->insert_tail( NgxQueue->new('bar') );
$q->insert_tail( NgxQueue->new('buzz') );
ok !$q->empty;

my $head = $q->head;
is $head->data, 'foo';
is $head->next->data, 'bar';
is $head->next->next->data, 'buzz';

$q->foreach(sub {
    $_->remove;
});
ok $q->empty;

# add
$q->insert_tail( NgxQueue->new('foo') );
$q->insert_tail( NgxQueue->new('bar') );

my $qq = NgxQueue->new;
$qq->insert_head( NgxQueue->new('fuga'));
$qq->insert_head( NgxQueue->new('hoge'));

$q->add($qq);

my @r; $q->foreach(sub { push @r, $_->data});
is_deeply \@r, [qw/foo bar hoge fuga/];

# split
my $qqq = NgxQueue->new;
my $sep = $q->head->next->next;
$q->split($sep, $qqq);

@r = (); $q->foreach(sub { push @r, $_->data});
is_deeply \@r, [qw/foo bar/];

@r = (); $qqq->foreach(sub { push @r, $_->data});
is_deeply \@r, [qw/hoge fuga/];

done_testing;


