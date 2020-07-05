use strict;
use warnings;

use Test::More;
use Test::Deep;

use OpenTracing::Span;

subtest 'span ID' => sub {
    my $span = new_ok('OpenTracing::Span');
    my $id = $span->id;
    like($id, qr/^[[:xdigit:]]{16}$/, 'span ID is 64-bit hex string');
    is($span->id, $id, 'span ID is constant');
    {
        my $count = 100;
        my %seen;
        ++$seen{$_->id} for map { OpenTracing::Span->new } 1..$count;
        is(0 + keys %seen, $count, 'span IDs are unique');
    }
    done_testing;
};

subtest 'trace ID' => sub {
    my $span = new_ok('OpenTracing::Span');
    my $id = $span->trace_id;
    like($id, qr/^[[:xdigit:]]{32}$/, 'trace ID is 64-bit hex string');
    is($span->trace_id, $id, 'trace ID is constant');
    {
        my $count = 100;
        my %seen;
        ++$seen{$_->trace_id} for map { OpenTracing::Span->new } 1..$count;
        is(0 + keys %seen, $count, 'trace IDs are unique for unrelated spans');
    }
    done_testing;
};
done_testing;

