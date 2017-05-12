use strict;
use warnings;

use Config;
BEGIN {
    if ($] < 5.008009) {
        print("1..0 # Skip Needs Perl 5.8.9 or later\n");
        exit(0);
    }
    if (! $Config{useithreads}) {
        print("1..0 # Skip Threads not supported\n");
        exit(0);
    }
}

use threads;
use threads::shared;

BEGIN {
    if ($threads::shared::VERSION lt '1.15') {
        print("1..0 # Skip Needs threads::shared 1.15 or later\n");
        exit(0);
    }
}

use Thread::Queue;
BEGIN {
    if ($Thread::Queue::VERSION lt '2.08') {
        print("1..0 # Skip Needs Thread::Queue 2.08 or later\n");
        exit(0);
    }
}

use Test::More 'tests' => 25;

package MyClass; {
    use Object::InsideOut qw/:SHARED/;

    sub _init :Init {
        my ($self, $arg) = @_;
        Test::More::is($$self, 1, '_init');
    }

    sub _destroy :Destroy {
        my ($self) = @_;
        Test::More::is($$self, 1, '_destroy');
    }
}

package main;

sub consumer
{
    my $fm_main = $_[0];
    my $to_main = $_[1];

    while (1) {
        my $obj = $fm_main->dequeue();
        last if (! ref($obj));
        my $id = $$obj;
        undef($obj);
        Test::More::is($id, 1, 'thread');
        $to_main->enqueue($id);
    }
    $to_main->enqueue('bye');
}

MAIN:
{
    my $to_thr = Thread::Queue->new();
    my $fm_thr = Thread::Queue->new();

    # Consumer
    my $thr = threads->create(\&consumer, $to_thr, $fm_thr);

    # Producer
    foreach (1..5) {
        my $obj = MyClass->new();
        my $id = $$obj;
        $to_thr->enqueue($obj);
        undef($obj);
        Test::More::is($id, 1, 'main');
        Test::More::is($fm_thr->dequeue(), 1, 'returned');
    }

    $to_thr->enqueue('done');
    $fm_thr->dequeue();

    $thr->join();
}

exit(0);

# EOF
