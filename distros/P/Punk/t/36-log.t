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

done_testing;
