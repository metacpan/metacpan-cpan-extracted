#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Temp ();
use Punk ();

# The window, and the seam - phase 4 of plan_punk_idempotency.
#
# Cache-backed idempotency COLLAPSES the window between the work being done
# and the key being recorded. It does not remove it. A process killed in that
# gap leaves the work done and no key stored, so the retry executes again -
# and that is a documented behaviour, so it gets a test like any other.
#
# The only symptom an operator will ever see is a log line, so that is tested
# too: without it, a doubled order is indistinguishable from a client bug.

my $dir = File::Temp->newdir;
my @sink;
my $ran = 0;

{
    package Windowed;
    use Punk;
    logging level => 'warn', to => sub { push @sink, $_[0] };
    cache 'file', dir => "$dir";
    plugin 'Idempotency' => { scope => sub { 'alice' } };

    # An unrecordable response, standing in for the crash: the handler ran
    # and did its work, and nothing about it reaches the store. A filehandle
    # body cannot be recorded without consuming what is being sent.
    post '/download' => sub {
        my ($c) = @_;
        $ran++;
        $c->send_file(__FILE__, type => 'text/plain');
    }, { idempotent => 1 };

    post '/ok' => sub { $ran++; $_[0]->text('ok') }, { idempotent => 1 };

    # a scope that cannot answer
    post '/anon' => sub { $ran++; $_[0]->text('anon') }, { idempotent => 1 };
}

{
    package Anon;
    use Punk;
    logging level => 'warn', to => sub { push @sink, $_[0] };
    cache 'file', dir => "$dir";
    plugin 'Idempotency' => { scope => sub { undef } };
    post '/anon' => sub { $ran++; $_[0]->text('anon') }, { idempotent => 1 };
}

sub hit {
    my ($app, $path, $key) = @_;
    open my $in, '<', \'';
    my $r = $app->({
        REQUEST_METHOD => 'POST', PATH_INFO => $path, QUERY_STRING => '',
        CONTENT_LENGTH => 0, 'psgi.input' => $in,
        HTTP_IDEMPOTENCY_KEY => $key,
    });
    my %h = @{ $r->[1] };
    return ($r->[0], \%h);
}

my $app  = Windowed->to_app;
my $anon = Anon->to_app;

# ---- a response that could not be recorded --------------------------------------

{
    $ran = 0; @sink = ();
    my ($s1) = hit($app, '/download', 'w1');
    is $s1, 200, 'the request is served';
    is $ran, 1, '...by the handler';

    my ($s2, $h2) = hit($app, '/download', 'w1');
    is $ran, 2,
       'THE RETRY EXECUTES AGAIN, because nothing was recorded. This is the '
       . 'window, and it is a documented behaviour rather than a bug';
    ok !exists $h2->{'Idempotency-Replayed'}, '...it was not a replay';

    ok scalar(grep { /not recorded/ } @sink),
       'and it is in the log at warn - the only symptom an operator ever '
       . 'gets, and without it a doubled order looks like a client bug';
    like +(grep { /not recorded/ } @sink)[0], qr/retry.*execute again/,
       '...saying what the consequence is';
}

# ---- and not on an ordinary request ---------------------------------------------

{
    $ran = 0; @sink = ();
    hit($app, '/ok', 'w2');
    hit($app, '/ok', 'w2');
    is $ran, 1, 'a recordable response is recorded and replayed';
    is scalar(grep { /not recorded/ } @sink), 0,
       '...and says nothing, so the warning means something when it appears';
}

# ---- a scope that cannot answer --------------------------------------------------

{
    $ran = 0; @sink = ();
    hit($anon, '/anon', 'a1');
    hit($anon, '/anon', 'a1');
    is $ran, 2,
       'a scope returning undef means the plugin cannot say whose key this '
       . 'is, so it does not pretend to: the request proceeds unprotected';
    ok scalar(grep { /scope returned undef/ } @sink),
       '...loudly, because a silently inert plugin is worse than none';
}

# ---- the store is a seam, not a hardcoded Punk::Cache ---------------------------
#
# The plugin reaches the store through one narrow path - read, write, lock -
# so a store from outside this distribution works, which is what makes a
# database-backed one (the thing that would CLOSE the window) a drop-in
# rather than a rewrite.

{
    package Custom;
    use Punk;
    cache 'custom', max_bytes => '1M';
    plugin 'Idempotency' => { scope => sub { 'alice' } };
    post '/orders' => sub { $ran++; $_[0]->text('order ' . $ran) },
        { idempotent => 1 };
}
{
    $ran = 0;
    my $capp = Custom->to_app;
    my ($s1, $h1) = hit($capp, '/orders', 'c1');
    my ($s2, $h2) = hit($capp, '/orders', 'c1');
    is $ran, 1, 'a backend from outside the distribution replays too';
    is $h2->{'Idempotency-Replayed'}, 'true', '...through the same seam';
}

done_testing;
