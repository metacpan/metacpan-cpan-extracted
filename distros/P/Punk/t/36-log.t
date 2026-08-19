#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Raw::JSON qw(file_json_decode);

# $c->log / $app->log: a level-based logger that honours psgix.logger, else
# emits a readable (or JSON) line; a level threshold; the request's method/path.

my @sink;                                   # a `to => sub` capture
sub reset_sink { @sink = () }

{
    package LApp;
    use Punk;
    logging level => 'info', to => sub { push @sink, $_[0] };

    get '/hi' => sub {
        my ($c) = @_;
        $c->log->info('hello %s', 'world');
        $c->log->debug('noisy');            # dropped at the info threshold
        $c->text('ok');
    };
    get '/warn' => sub {
        my ($c) = @_;
        $c->log->warn('careful');
        $c->text('ok');
    };
    get '/rec' => sub {
        my ($c) = @_;
        $c->log->info({ message => 'served', books => 12, user => 7 });
        $c->text('ok');
    };
    get '/rec-nomsg' => sub {
        my ($c) = @_;
        $c->log->info({ books => 3 });
        $c->text('ok');
    };
    package main;
}

my $app = LApp->to_app;
sub hit {
    my ($path, %env) = @_;
    reset_sink();
    return $app->({ REQUEST_METHOD => 'GET', PATH_INFO => $path, %env });
}

# --- psgix.logger delegation ------------------------------------------------
{
    my @seen;
    hit('/hi', 'psgix.logger' => sub { push @seen, $_[0] });
    is(scalar @seen, 1, 'psgix.logger receives one record (debug dropped)');
    is($seen[0]{level}, 'info', 'record carries the level');
    like($seen[0]{message}, qr/GET \/hi - hello world/,
        'message carries method, path and the sprintf result');
    is(scalar @sink, 0, 'psgix.logger present: the `to` sink is not used');
}

# --- plain line to a `to` sink (no psgix.logger) ----------------------------
{
    hit('/hi');
    is(scalar @sink, 1, 'without psgix.logger, the `to` sink gets one line');
    like($sink[0], qr/^\[\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ\] \[info\] /,
        'plain line has an ISO-8601 UTC timestamp and the level');
    like($sink[0], qr/GET \/hi - hello world\n\z/,
        'plain line ends with method, path, message and a newline');
}

# --- threshold ---------------------------------------------------------------
{
    my $lg = bless { level => 1, format => 'plain', to => sub { push @sink, $_[0] } },
        'Punk::Logger';
    reset_sink();
    $lg->debug('x'); is(scalar @sink, 0, 'debug dropped when threshold is info');
    $lg->info('y');  is(scalar @sink, 1, 'info passes at the info threshold');

    my $dbg = bless { level => 0, format => 'plain', to => sub { push @sink, $_[0] } },
        'Punk::Logger';
    reset_sink();
    $dbg->debug('z'); is(scalar @sink, 1, 'debug passes when threshold is debug');
}

# --- json format -------------------------------------------------------------
{
    my $lg = bless { level => 1, format => 'json', to => sub { push @sink, $_[0] } },
        'Punk::Logger';
    reset_sink();
    $lg->error('boom %d', 42);
    is(scalar @sink, 1, 'json: one line');
    my $o = file_json_decode($sink[0]);
    is($o->{level}, 'error', 'json has the level');
    is($o->{message}, 'boom 42', 'json message is the sprintf result');
    like($o->{time}, qr/^\d{4}-\d\d-\d\dT/, 'json has a timestamp');
    ok(!exists $o->{method}, 'app logger json has no method');
}

# --- $app->log: no request context ------------------------------------------
{
    reset_sink();
    LApp->punk_app->log->warn('startup');
    is(scalar @sink, 1, 'app logger emits');
    like($sink[0], qr/\[warn\] startup\n\z/,
        'app logger line has no method/path, just the message');
}

# --- sprintf edge: a lone message with a % is passed through untouched -------
{
    my $lg = bless { level => 1, format => 'plain', to => sub { push @sink, $_[0] } },
        'Punk::Logger';
    reset_sink();
    $lg->info('100% done');
    like($sink[0], qr/100% done\n\z/, 'a single-arg message is not run through sprintf');
}

# --- levels via the generic log($level, ...) --------------------------------
{
    my $lg = bless { level => 0, format => 'plain', to => sub { push @sink, $_[0] } },
        'Punk::Logger';
    reset_sink();
    $lg->log(fatal => 'n=%d', 7);
    like($sink[0], qr/\[fatal\] n=7\n\z/, 'log($level, ...) picks the level and formats');
}

# --- records: a lone unblessed hashref is fields, `message` is the message ---

sub logger {
    my (%o) = @_;
    reset_sink();
    return bless { level => 1, format => 'plain',
                   to => sub { push @sink, $_[0] }, %o }, 'Punk::Logger';
}

{
    my $lg = logger();
    $lg->info({ message => 'listing books', books => 12, user => 7 });
    is(scalar @sink, 1, 'record: one line');
    like($sink[0], qr/\[info\] listing books books=12 user=7\n\z/,
        'record: the message, then the fields as logfmt pairs');
}

# sorted, whatever order the keys were written in
{
    my $lg = logger();
    $lg->info({ message => 'm', zebra => 1, apple => 2, mango => 3 });
    like($sink[0], qr/m apple=2 mango=3 zebra=1\n\z/,
        'record: fields are sorted by key, not left in hash order');
}

# --- reserved keys ------------------------------------------------------------
{
    my $lg = logger();
    $lg->info({ level => 'fatal', time => 'nope', message => 'real' });
    like($sink[0], qr/\[info\] real\n\z/,
        'plain: a field cannot forge level or time, and is dropped');
    unlike($sink[0], qr/fatal|nope/, 'plain: the forged values do not appear');

    my $j = logger(format => 'json');
    $j->error({ level => 'debug', message => 'real', method => 'PATCH',
                path => '/forged', request_id => 'x', time => 'nope',
                kept => 1 });
    my $o = file_json_decode($sink[0]);
    is($o->{level}, 'error', 'json: level is the house level, not the field');
    is($o->{message}, 'real', 'json: message is the record message');
    like($o->{time}, qr/^\d{4}-/, 'json: time is the house timestamp');
    ok(!exists $o->{method}, 'json: a method field is dropped (app logger has none)');
    ok(!exists $o->{path}, 'json: a path field is dropped');
    ok(!exists $o->{request_id}, 'json: a request_id field is dropped');
    is($o->{kept}, 1, 'json: an unreserved field is merged');
}

# --- json merge ---------------------------------------------------------------
{
    my $lg = logger(format => 'json');
    $lg->info({ message => 'j', books => 12, nested => { x => [1, 2] } });
    my $o = file_json_decode($sink[0]);
    is($o->{message}, 'j', 'json: message');
    is($o->{books}, 12, 'json: a scalar field');
    is_deeply($o->{nested}, { x => [1, 2] }, 'json: a nested field keeps its shape');
    is(scalar(() = $sink[0] =~ /\n/g), 1, 'json: still exactly one line');
}

# --- logfmt quoting -----------------------------------------------------------
{
    my $lg = logger();
    $lg->info({ message => 'q', sp => 'a b', quo => 'he"llo', eq => 'a=b',
                empty => '', plain => 'simple' });
    like($sink[0], qr/empty="" eq="a=b" plain=simple quo="he\\"llo" sp="a b"/,
        'logfmt: empty, space, = and " are quoted; a plain word is not');
}

{
    my $lg = logger();
    $lg->info({ message => 'inject', evil => "one\ntwo\r[fatal] forged" });
    is(scalar(() = $sink[0] =~ /\n/g), 1,
        'logfmt: a newline in a value cannot split the line');
    like($sink[0], qr/evil="one\\ntwo\\r\[fatal\] forged"/,
        'logfmt: the newline and carriage return are escaped');
}

{
    my $lg = logger();
    $lg->info({ message => 'keys', "bad key=x" => 1 });
    like($sink[0], qr/bad_key_x=1/,
        'logfmt: a key that would break the line is sanitised');
}

{
    my $lg = logger();
    $lg->info({ message => 'u', undefined => undef });
    like($sink[0], qr/undefined=\n\z/, 'logfmt: an undef field is a bare key=');
}

{
    my $lg = logger();
    $lg->info({ message => 'r', h => { x => [1, 2] } });
    like($sink[0], qr/h="\{\\"x\\":\[1,2\]\}"/,
        'logfmt: a reference field is compact JSON, quoted and escaped');
}

# --- a value frj refuses must not take the request down ----------------------
{
    my $lg = logger();
    my $ok = eval { $lg->info({ message => 'c', code => sub { 1 } }); 1 };
    ok($ok, 'a coderef field does not croak out of the logger');
    is(scalar @sink, 1, 'and the line is still emitted');
    like($sink[0], qr/code=CODE\(0x[0-9a-f]+\)/, 'the coderef is stringified');

    my $j = logger(format => 'json');
    $ok = eval { $j->info({ message => 'c', rx => qr/a b/,
                            deep => { fh => \*STDOUT, list => [ sub { 1 } ] } }); 1 };
    ok($ok, 'json: a regexp, a glob and a nested coderef do not croak');
    my $o = file_json_decode($sink[0]);
    like($o->{rx}, qr/a b/, 'json: the regexp is stringified');
    like($o->{deep}{list}[0], qr/^CODE\(0x/,
        'json: a coderef nested two levels down is stringified too');
}

# --- a blessed reference is a message, not a record --------------------------
{
    package LOver;
    use overload '""' => sub { $_[0]{s} }, fallback => 1;
    sub new { bless { s => 'I am a message', secret => 'not a field' }, shift }
    package main;

    my $lg = logger();
    $lg->info(LOver->new);
    like($sink[0], qr/\[info\] I am a message\n\z/,
        'an object with an overloaded "" still stringifies as the message');
    unlike($sink[0], qr/secret|not a field/,
        'and its guts are not dumped as fields');

    my $plain = logger();
    $plain->info(bless { a => 1 }, 'LNoOver');
    like($sink[0], qr/LNoOver=HASH\(0x[0-9a-f]+\)/,
        'a blessed hashref with no overload stringifies as before');
}

# --- shapes without a message ------------------------------------------------
{
    my $lg = logger();
    $lg->info({ books => 3 });
    like($sink[0], qr/\[info\] books=3\n\z/,
        'a record with no message key is just its fields');

    $lg = logger();
    $lg->info({});
    like($sink[0], qr/\[info\] \n\z/, 'an empty record emits an empty message');

    $lg = logger();
    $lg->info({ message => 'only' });
    like($sink[0], qr/\[info\] only\n\z/,
        'a record with nothing but a message reads as a plain line');
}

# --- with a request context ---------------------------------------------------
{
    hit('/rec');
    like($sink[0], qr/\[info\] GET \/rec - served books=12 user=7\n\z/,
        'request logger: method, path, message, then the fields');

    hit('/rec-nomsg');
    like($sink[0], qr/\[info\] GET \/rec-nomsg - books=3\n\z/,
        'request logger: no message leaves no dangling separator');
}

# --- psgix.logger carries the fields in the message --------------------------
{
    my @seen;
    hit('/rec', 'psgix.logger' => sub { push @seen, $_[0] });
    is(scalar @seen, 1, 'psgix.logger: one record');
    is($seen[0]{level}, 'info', 'psgix.logger: the level');
    like($seen[0]{message}, qr/GET \/rec - served books=12 user=7\z/,
        'psgix.logger: the fields are folded into the message, nothing lost');
    is_deeply([sort keys %{ $seen[0] }], ['level', 'message'],
        'psgix.logger: still only the two keys PSGI defines');
}

# --- below the threshold, nothing happens at all -----------------------------
{
    my $lg = logger(level => 1);
    $lg->debug({ message => 'x', a => 1 });
    is(scalar @sink, 0, 'a below-threshold record emits nothing');
}

{
    package LCount;
    our $n = 0;
    use overload '""' => sub { $n++; 'stringified' }, fallback => 1;
    sub new { bless {}, shift }
    package main;

    local $LCount::n = 0;
    my $lg = logger(level => 1);
    $lg->debug('%s', LCount->new);
    is(scalar @sink, 0, 'below-threshold sprintf call emits nothing');
    is($LCount::n, 0,
        'and does no formatting: the argument was never stringified');

    $lg->info('%s', LCount->new);
    is($LCount::n, 1, 'at or above the threshold it does format');
}

# --- the generic log($level, \%record) and chaining ---------------------------
{
    my $lg = logger(level => 0);
    $lg->log(fatal => { message => 'n', a => 1 });
    like($sink[0], qr/\[fatal\] n a=1\n\z/, 'log($level, \%record) takes a record');

    reset_sink();
    my $ret = $lg->info({ message => 'one' });
    is($ret, $lg, 'a record call still returns the logger');
    $ret->warn('two');
    is(scalar @sink, 2, 'so calls still chain');
}

# --- $app->log takes records too ---------------------------------------------
{
    reset_sink();
    LApp->punk_app->log->warn({ message => 'startup', pid => 'x' });
    like($sink[0], qr/\[warn\] startup pid=x\n\z/,
        'the app logger takes a record, with no method or path');
}

# --- trace_id / span_id are reserved -----------------------------------------
# A telemetry layer writes these from the active span. An application field of
# the same name would forge a correlation, pointing a reader at somebody
# else's trace.
{
    my $lg = logger(format => 'json');
    $lg->info({ message => 'x', trace_id => 'forged', span_id => 'forged',
                kept => 1 });
    my $o = file_json_decode($sink[0]);
    ok(!exists $o->{trace_id}, 'a trace_id field cannot forge a correlation');
    ok(!exists $o->{span_id},  'nor a span_id field');
    is($o->{kept}, 1, 'while an ordinary field is still merged');

    $lg = logger();
    $lg->info({ message => 'x', trace_id => 'forged' });
    unlike($sink[0], qr/forged/, 'and the same holds for the plain format');
}

done_testing;
