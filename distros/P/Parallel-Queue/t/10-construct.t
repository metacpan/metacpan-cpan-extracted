########################################################################
# first sanity check: is the module usable.
########################################################################

use v5.24;
use strict;

my $madness = 'Parallel::Queue::Manager';
my $method  = 'new';

use Test::More;

SKIP:
{
    use_ok $madness
    or skip "Unusable: '$madness'";

    can_ok $madness, $method
    or skip "Your $madness lacks any '$method'.", 1;

    my $handler = sub { say 'Hello, world!' };

    eval
    {
        my $qmgr    = $madness->$method;

        if( $qmgr->handler )
        {
            fail 'Invalid handler installed.';
            diag "Object contents:\n", explain $qmgr;
            skip 'Botched construction without handler.', 1;
        }
        else
        {
            pass 'No handler installed';
        }
    };

    eval 
    {
        my $qmgr    = $madness->$method( $handler );

        pass "Constructed '$madness'";

        my $found   = $qmgr->handler;
        my $queue   = $qmgr->queue;

        ok $handler == $found, "Handler: '$found' ($handler)";
        ok ! @$queue, 'Queue is empty.';

        $qmgr
    }
    or BAIL_OUT "Could not construct '$madness' ($handler)";

    my $qmgr
    = eval 
    {
        my @queue   = map { rand } ( 1 .. 10 );
        my $qmgr    = $madness->$method( $handler, @queue );

        pass "Constructed '$madness'";

        for( my $found = $qmgr->handler )
        {
            ok $handler == $found, "Handler: '$found' ($handler)";
        }

        for( my $found = $qmgr->queue )
        {
            ok @$found, 'Queue is not empty.';
            is_deeply $found, \@queue, "Contents match"
            or diag
                "Queue:\n",   explain \@queue,
                "\nFound:\n", explain $found
            ;
        }

        do
        {
            my $buffer  = '';
            open my $fh, '>', \$buffer;

            local *STDERR = $fh;

            $qmgr->DESTROY;

            like $buffer, qr{^ Incomplete \s jobs: \n }x,
            'Found incomplete jobs.';
        };

        1
    }
    or
    BAIL_OUT "Could not construct '$madness' ($handler)";
}

done_testing;
__END__
