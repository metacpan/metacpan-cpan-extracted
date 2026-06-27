use strict;
use warnings;
use Test2::V0;

use PAGI::Request;
use PAGI::WebSocket;
use PAGI::SSE;
use PAGI::Context;

# The high-level helpers expose buffered_amount / high_water_mark /
# low_water_mark by delegating to the server-provided pagi.transport handle,
# and degrade gracefully (0 / undef) when it is absent.

# Duck-typed pagi.transport handle (full: reads + callbacks).
{
    package MockTransport;
    sub new { bless { buf => $_[1], high => $_[2], low => $_[3], hw => [], dr => [] }, $_[0] }
    sub buffered_amount { $_[0]{buf} }
    sub high_water_mark { $_[0]{high} }
    sub low_water_mark  { $_[0]{low} }
    sub on_high_water { push @{$_[0]{hw}}, $_[1]; return $_[0] }
    sub on_drain      { push @{$_[0]{dr}}, $_[1]; return $_[0] }
}

# A reads-only handle (e.g. an older server): no callback methods. The helpers
# must treat on_high_water/on_drain as quiet no-ops here, not die.
{
    package ReadsOnlyTransport;
    sub new { bless { buf => $_[1], high => $_[2], low => $_[3] }, $_[0] }
    sub buffered_amount { $_[0]{buf} }
    sub high_water_mark { $_[0]{high} }
    sub low_water_mark  { $_[0]{low} }
}

my $recv = sub { };
my $send = sub { };

sub mk_request {
    my ($t) = @_;
    my $scope = { type => 'http', method => 'GET', headers => [] };
    $scope->{'pagi.transport'} = $t if $t;
    return PAGI::Request->new($scope);
}
sub mk_ws {
    my ($t) = @_;
    my $scope = { type => 'websocket', headers => [] };
    $scope->{'pagi.transport'} = $t if $t;
    return PAGI::WebSocket->new($scope, $recv, $send);
}
sub mk_sse {
    my ($t) = @_;
    my $scope = { type => 'sse', headers => [] };
    $scope->{'pagi.transport'} = $t if $t;
    return PAGI::SSE->new($scope, $recv, $send);
}
sub mk_ctx {
    my ($t) = @_;
    my $scope = { type => 'http', method => 'GET', headers => [] };
    $scope->{'pagi.transport'} = $t if $t;
    return PAGI::Context->new($scope, $recv, $send);
}

my @cases = (
    ['PAGI::Request',   \&mk_request],
    ['PAGI::WebSocket', \&mk_ws],
    ['PAGI::SSE',       \&mk_sse],
    ['PAGI::Context',   \&mk_ctx],
);

for my $case (@cases) {
    my ($name, $mk) = @$case;

    subtest "$name delegates to pagi.transport" => sub {
        my $obj = $mk->(MockTransport->new(4096, 65536, 16384));
        is($obj->buffered_amount, 4096,  'buffered_amount delegates');
        is($obj->high_water_mark, 65536, 'high_water_mark delegates');
        is($obj->low_water_mark,  16384, 'low_water_mark delegates');
    };

    subtest "$name graceful without pagi.transport" => sub {
        my $obj = $mk->(undef);
        is($obj->buffered_amount, 0,     'buffered_amount is 0 when handle absent');
        is($obj->high_water_mark, undef, 'high_water_mark undef when handle absent');
        is($obj->low_water_mark,  undef, 'low_water_mark undef when handle absent');
    };

    subtest "$name on_high_water/on_drain delegate and chain" => sub {
        my $t = MockTransport->new(0, 65536, 16384);
        my $obj = $mk->($t);
        my $cb1 = sub { };
        my $cb2 = sub { };
        # exact_ref (not is): WebSocket/SSE cache themselves in the scope, so a
        # deep compare of the object to itself would hit a reference cycle.
        is($obj->on_high_water($cb1), exact_ref($obj), 'on_high_water returns self for chaining');
        is($obj->on_drain($cb2),      exact_ref($obj), 'on_drain returns self for chaining');
        is(scalar @{$t->{hw}}, 1, 'on_high_water delegated to the handle');
        is($t->{hw}[0], exact_ref($cb1), 'with the registered callback');
        is(scalar @{$t->{dr}}, 1, 'on_drain delegated to the handle');
        is($t->{dr}[0], exact_ref($cb2), 'with the registered callback');
    };

    subtest "$name is_writable reflects the high-water mark" => sub {
        ok($mk->(MockTransport->new(1000, 65536, 16384))->is_writable,
            'writable below the high mark');
        ok(!$mk->(MockTransport->new(70000, 65536, 16384))->is_writable,
            'not writable at/above the high mark');
        ok($mk->(undef)->is_writable,
            'writable (assumed) when no handle is present');
    };

    subtest "$name callbacks are quiet no-ops on a reads-only handle" => sub {
        my $obj = $mk->(ReadsOnlyTransport->new(0, 65536, 16384));
        ok(lives { $obj->on_high_water(sub { }); $obj->on_drain(sub { }) },
            'on_high_water/on_drain do not die without callback support');
    };
}

done_testing;
