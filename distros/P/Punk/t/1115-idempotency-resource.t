#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use Punk ();

# Which request a key belongs to, and what winning the lock means.
#
# A stored response is replayed for the request it answered and for no other.
# The route as declared is the same for /orders/7/cancel and /orders/8/cancel,
# so the path and the query string as they were asked for are part of what a
# key is checked against.

{
    package Scripted::Store;
    sub new       { bless { h => {}, hide => 0, log => [] }, shift }
    sub is_shared { 1 }
    sub get {
        my ($s, $k) = @_;
        push @{ $s->{log} }, 'get';
        if ($s->{hide}) { $s->{hide}--; return undef }
        return $s->{h}{$k};
    }
    sub set     { $_[0]{h}{ $_[1] } = $_[2]; push @{ $_[0]{log} }, 'set'; 1 }
    sub delete  { delete $_[0]{h}{ $_[1] }; 1 }
    sub clear   { %{ $_[0]{h} } = (); 1 }
    sub stats   { () }
    sub _lock   { push @{ $_[0]{log} }, 'lock:' . ($_[2] // 'none'); 1 }
    sub _unlock { push @{ $_[0]{log} }, 'unlock'; 1 }
    package main;
}

my %ran;
our $STORE = Scripted::Store->new;

{
    package ResApp;
    use Punk;
    cache($main::STORE);
    plugin 'Idempotency' => { scope => sub { 'alice' }, lock_wait => 45 };

    post '/orders/:id/cancel' => sub {
        my ($c) = @_;
        my $id = $c->param('id');
        $ran{$id}++;
        $c->json({ cancelled => $id, force => $c->req->query->{force} // 0 });
    }, { idempotent => 1 };
    post '/orders' => sub { $ran{new}++; $_[0]->json({ made => $ran{new} }, 201) },
        { idempotent => 1 };
}
my $app = ResApp->to_app;

sub req {
    my (%o) = @_;
    my $body = $o{body} // '';
    open my $in, '<', \$body or die $!;
    my $r = $app->({
        REQUEST_METHOD => 'POST',
        PATH_INFO      => $o{path},
        QUERY_STRING   => $o{query} // '',
        CONTENT_TYPE   => 'application/json',
        CONTENT_LENGTH => length $body,
        'psgi.input'   => $in,
        HTTP_IDEMPOTENCY_KEY => $o{key},
    });
    my %h = @{ $r->[1] };
    return ($r->[0], \%h, join('', @{ $r->[2] }));
}

# ---- one key, two resources ----------------------------------------------------
{
    my ($s, $h, $b) = req(path => '/orders/7/cancel', key => 'cancel-1');
    is($s, 200, 'order 7 is cancelled');
    like($b, qr/"cancelled":"7"/, '...and says so');

    ($s, $h, $b) = req(path => '/orders/7/cancel', key => 'cancel-1');
    is($h->{'Idempotency-Replayed'}, 'true', 'the same request again is a replay');
    is($ran{7}, 1, '...and ran once');

    ($s, $h, $b) = req(path => '/orders/8/cancel', key => 'cancel-1');
    is($s, 422, 'the same key for order 8 is refused');
    like($b, qr/already used for a different request/, '...by name');
    ok(!defined $h->{'Idempotency-Replayed'}, '...not replayed');
    unlike($b, qr/"cancelled"/, '...and order 7\'s answer is not in it');
    ok(!$ran{8}, '...and the handler did not run for 8 under that key');

    ($s, $h, $b) = req(path => '/orders/8/cancel', key => 'cancel-2');
    is($s, 200, 'order 8 under its own key is cancelled');
    like($b, qr/"cancelled":"8"/, '...as itself');
    is($ran{8}, 1, '...once');
}

# ---- one key, two query strings ------------------------------------------------
{
    my ($s, $h, $b) = req(path => '/orders/9/cancel', key => 'q-1');
    like($b, qr/"force":0/, 'a request with no query string');
    ($s, $h, $b) = req(path => '/orders/9/cancel', query => 'force=1', key => 'q-1');
    is($s, 422, 'the same key with ?force=1 is a different request');
    is($ran{9}, 1, '...and is not run');
    ($s, $h, $b) = req(path => '/orders/9/cancel', query => 'force=1', key => 'q-2');
    like($b, qr/"force":"?1/, 'under its own key it runs, with its query');
    ($s, $h, $b) = req(path => '/orders/9/cancel', query => 'force=1', key => 'q-2');
    is($h->{'Idempotency-Replayed'}, 'true', '...and replays for the same query');
}

# ---- winning the lock is not finding nothing ------------------------------------
# The holder records and then unlocks. A second request that looked before
# the record and locked after the unlock holds the lock with an answer already
# waiting; the store here plays that out by hiding the entry from one read.
{
    my ($s, $h, $b) = req(path => '/orders', body => '{}', key => 'race');
    is($s, 201, 'the first request ran');
    @{ $STORE->{log} } = ();
    $STORE->{hide} = 1;                       # the next read misses, once
    ($s, $h, $b) = req(path => '/orders', body => '{}', key => 'race');
    is($ran{new}, 1, 'a request that takes the lock after a miss looks again');
    is($h->{'Idempotency-Replayed'}, 'true', '...and replays what it finds');
    like($b, qr/"made":1/, '...the first answer');
    is_deeply($STORE->{log}, [ 'get', 'lock:45', 'get', 'unlock' ],
        '...read, lock for the plugin\'s own budget, read again, release');
}

# ---- lock_wait is the plugin's, and checked --------------------------------------
{
    for my $bad (0, -1, 'soon') {
        my $err = '';
        eval { Punk::App->new->plugin('Idempotency',
                   { scope => sub { 1 }, lock_wait => $bad }); 1 } or $err = $@;
        like($err, qr/lock_wait must be a positive number of seconds/,
            "lock_wait => '$bad' is refused at boot");
    }
    {
        package DefApp;
        use Punk;
        cache(Scripted::Store->new);
        plugin 'Idempotency' => { scope => sub { 'bob' } };
        post '/x' => sub { $_[0]->text('x') }, { idempotent => 1 };
    }
    my $d = DefApp->to_app;
    open my $in, '<', \'';
    $d->({ REQUEST_METHOD => 'POST', PATH_INFO => '/x', QUERY_STRING => '',
           'psgi.input' => $in, HTTP_IDEMPOTENCY_KEY => 'k' });
    my $log = DefApp->punk_app->{cache}{default}->backend->{log};
    is($log->[1], 'lock:30', 'with no option the lock is held for 30 seconds');
}

done_testing;
