use strict;
use warnings;
use Test::More;
use Test::LeakTrace;

use NgxQueue;

no_leaks_ok {
    my $q = NgxQueue->new;
    $q->insert_tail( NgxQueue->new('foo') );
    $q->insert_tail( NgxQueue->new('bar') );
    $q->insert_tail( NgxQueue->new('buzz') );

    $q->foreach(sub { $_->remove });
};

no_leaks_ok {
    my $q = NgxQueue->new;

    {
        my $foo = NgxQueue->new('foo');
        $q->insert_tail($foo);
    }

    die unless $q->head->data eq 'foo';

    $q->foreach(sub { $_->remove });
};

no_leaks_ok {
    my $q = NgxQueue->new;
    $q->insert_tail( NgxQueue->new('foo') );
    $q->insert_tail( NgxQueue->new('bar') );

    my $qq = NgxQueue->new;
    $qq->insert_head( NgxQueue->new('fuga'));
    $qq->insert_head( NgxQueue->new('hoge'));

    $q->add($qq);

    $q->foreach(sub { $_->remove });
};

no_leaks_ok {
    my $q = NgxQueue->new;
    $q->insert_tail( NgxQueue->new('foo') );
    $q->insert_tail( NgxQueue->new('bar') );
    $q->insert_tail( NgxQueue->new('fuga'));
    $q->insert_tail( NgxQueue->new('hoge'));

    my $sep = $q->head->next;
    my $qq = NgxQueue->new;

    $q->split($sep, $qq);

    $q->foreach(sub { $_->remove });
    $qq->foreach(sub { $_->remove });
};

done_testing;
