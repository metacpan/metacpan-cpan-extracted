#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Punk ();

# The id on every log line.
#
# This is the reason anyone installs the plugin: a user quotes the id their
# browser showed them, and that one string finds every line the request wrote.
# A design where the developer passes the id explicitly is a design where it
# is missing from the one line that mattered.

our @LINES;   # package, not lexical: the logging closure pushes to
              # @main::LINES, and `my` here would be a different array
sub env_for {
    my (%extra) = @_;
    return {
        REQUEST_METHOD => 'GET',
        PATH_INFO      => '/',
        QUERY_STRING   => '',
        'psgi.input'   => undef,
        'psgi.errors'  => \*STDERR,
        %extra,
    };
}

{
    package LogApp;
    use Punk;

    plugin 'RequestId';
    logging to => sub { push @main::LINES, $_[0] };

    get '/' => sub {
        my ($c) = @_;
        $c->log->info('first line');
        $c->log->info({ message => 'with fields', books => 12 });
        $c->text($c->request_id);
    };

    package main;
    our $APP = LogApp->to_app;
}

# ---- the id in the log is the id the client got ------------------------------
{
    @LINES = ();
    my $res = $main::APP->(env_for());
    my $id  = $res->[2][0];
    my %h   = @{ $res->[1] };

    is($h{'X-Request-Id'}, $id, 'the client and the handler agree on the id');
    is(scalar @LINES, 2, 'both log calls emitted');

    my @carrying = grep { /\brequest_id=\Q$id\E\b/ } @LINES;
    is(scalar @carrying, 2,
        'EVERY line carries it, including the one that passed no fields - '
      . 'a design where the developer passes it explicitly is one where it '
      . 'is missing from the line that mattered');
}

# ---- a field, not a seventh position -----------------------------------------
# The compatibility decision. The line keeps its shape, so anything already
# splitting on the prefix still works.
{
    @LINES = ();
    $main::APP->(env_for());
    like($LINES[0], qr/\A\[[^\]]+\] \[info\] GET \/ - first line request_id=/,
        'the line format is unchanged up to the message: timestamp, level, '
      . 'method, path, message - and the id joins the FIELDS after it');
    like($LINES[1], qr/books=12 request_id=/,
        'and it sits alongside a record\'s own fields rather than displacing '
      . 'them');
}

# ---- two requests do not borrow each other's ---------------------------------
{
    @LINES = ();
    my $one = $main::APP->(env_for())->[2][0];
    my $first_batch = [ @LINES ];
    @LINES = ();
    my $two = $main::APP->(env_for())->[2][0];
    my $second_batch = [ @LINES ];

    isnt($one, $two, 'two requests, two ids');
    # Refuse to assert on empty batches: "none of the first's id appears in
    # the second's lines" is trivially true of no lines at all, and would
    # pass just as well with the logging broken.
    cmp_ok(scalar @$first_batch,  '>', 0, 'the first request logged something');
    cmp_ok(scalar @$second_batch, '>', 0, 'and so did the second');
    is(scalar(grep { /\Q$one\E/ } @$second_batch), 0,
        "the second request's lines carry none of the first's id");
    is(scalar(grep { /\Q$two\E/ } @$first_batch), 0,
        'and the first carries none of the second - the id is read from each '
      . "request's own env, so there is no worker-wide `current id` to leak");
}

# ---- outside a request -------------------------------------------------------
# The failure mode to test for is invisible and wrong: a log call outside a
# request carrying the id of the last request this worker served.
{
    @LINES = ();
    $main::APP->(env_for());
    my $served = $LINES[0];
    like($served, qr/request_id=/, 'a request logged with an id');

    @LINES = ();
    LogApp->punk_app->log->info('a worker starting up');
    is(scalar @LINES, 1, 'the application logger emitted');
    unlike($LINES[0], qr/request_id=/,
        'a line logged OUTSIDE a request carries no id - and specifically '
      . 'not the id of the last request this worker served, which would be '
      . 'wrong in a way nobody would ever notice');
}

# ---- json carries it too -----------------------------------------------------
{
    package JsonApp;
    use Punk;
    plugin 'RequestId';
    logging format => 'json', to => sub { push @main::LINES, $_[0] };
    get '/' => sub { $_[0]->log->info('json line'); $_[0]->text('ok') };

    package main;
    @LINES = ();
    my $res = JsonApp->to_app->(env_for());
    my %h = @{ $res->[1] };
    like($LINES[0], qr/"request_id"\s*:\s*"\Q$h{'X-Request-Id'}\E"/,
        'the json format carries request_id as its own key');
}

# ---- the client's header does NOT reach the log by itself --------------------
# Punk's logger used to fall back to HTTP_X_REQUEST_ID when psgix.request_id
# was absent - that is, to whatever the client sent, with no validation and no
# opt in. A log field is the one place attacker-chosen bytes should never
# arrive by default, and `request_id` is a field a reader trusts to identify a
# request rather than to quote a stranger.
{
    package PlainApp;
    use Punk;
    logging to => sub { push @main::LINES, $_[0] };
    get '/' => sub { $_[0]->log->info('no plugin here'); $_[0]->text('ok') };

    package main;
    @LINES = ();
    PlainApp->to_app->(env_for(HTTP_X_REQUEST_ID => 'client-chose-this'));
    unlike($LINES[0], qr/client-chose-this/,
        'with no plugin loaded, a client-supplied X-Request-Id does NOT '
      . 'become the logged request_id');
    unlike($LINES[0], qr/request_id=/,
        'and no request_id is logged at all - adopting an inbound id is '
      . "the plugin's trust_header option, which validates first");
}

# ---- THE GATE ----------------------------------------------------------------
# Given one id, grep finds every line that request produced and nothing else.
{
    @LINES = ();
    my @ids;
    push @ids, $main::APP->(env_for())->[2][0] for 1 .. 5;

    is(scalar @LINES, 10, 'five requests, two lines each');

    my $target = $ids[2];
    my @found  = grep { /\Q$target\E/ } @LINES;
    is(scalar @found, 2,
        'grepping for ONE id finds exactly the lines that request produced - '
      . 'every one of them, and not one belonging to another request');

    my %by_id;
    for my $line (@LINES) {
        $by_id{$1}++ if $line =~ /request_id=(\S+)/;
    }
    is(scalar keys %by_id, 5, 'five distinct ids across the ten lines');
    is_deeply([ sort values %by_id ], [ (2) x 5 ],
        'two lines under each, with none unaccounted for');
}

done_testing;
