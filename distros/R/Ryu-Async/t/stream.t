use strict;
use warnings;

no indirect;

use Test::More;
use Test::Deep;
use Test::Refcount;
use Test::Fatal;

use Time::HiRes;

use IO::Async::Loop;
use Ryu::Async;
use Variable::Disposition qw(dispose);

use IO::Async::Stream;

my $loop = IO::Async::Loop->new;
$loop->add(
    my $ryu = Ryu::Async->new
);

{
    # Trivial reader/writer pair
    pipe my ($rfh, $wfh);
    $wfh->autoflush(1);
    my $stream = IO::Async::Stream->new(
        read_handle  => $rfh,
    );

    is(exception {
        my @rslt;
        my $src = $ryu->from($stream)
            ->chunksize(4)
            ->each(sub {
                push @rslt, $_
            });
        $loop->later(sub {
            $wfh->write('12345678');
            $wfh->close;
        });
        Future->needs_any(
            $src->completed,
            $loop->timeout_future(after => 3)
        )->get;
#       $loop->loop_once(0.001);
#       $stream->close;
        cmp_deeply(\@rslt, [qw(1234 5678)], 'have expected data from stream');
    }, undef, 'can ->from a ::Stream');
}

is(
    0 + $ryu->children,
    0,
    'all child notifiers removed'
) or diag explain [ map ref, $ryu->children ];

done_testing;

