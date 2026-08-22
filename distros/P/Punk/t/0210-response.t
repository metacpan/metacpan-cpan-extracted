#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PunkTest;
use File::Raw::JSON qw(file_json_decode);

# Return-value coercion: triplet passthrough (and its heuristic edges),
# Punk::Response, auto-JSON with folded status/headers, the context
# builders, on_error, and after_dispatch.

{
    package RespApp;
    use Punk;
    use Punk::Response;
    get '/triplet' => sub {
        [ 418, ['Content-Type' => 'text/plain', 'Content-Length' => 3],
          ['tea'] ];
    };
    get '/three-numbers' => sub { [ 1, 2, 3 ] };
    get '/data' => sub { { pets => [ { id => 1 } ] } };
    get '/created' => sub {
        my ($c) = @_;
        $c->status(201)->header('X-Made' => 'yes');
        return { id => 9 };
    };
    get '/builder' => sub {
        Punk::Response->new(status => 202, body => { queued => 1 });
    };
    get '/builder-html' => sub {
        Punk::Response->new(body => '<p>hi</p>');
    };
    get '/ctx-json' => sub { $_[0]->json({ a => 1 }, 203) };
    get '/ctx-text' => sub { $_[0]->text('plain') };
    get '/ctx-html' => sub { $_[0]->html('<b>x</b>') };
    get '/ctx-redirect' => sub { $_[0]->redirect('/data') };
    get '/ctx-notfound' => sub { $_[0]->not_found };
    get '/boom' => sub { die "kapow\n" };
    package main;
}

my $app = RespApp->to_app;

is_deeply(hit($app, path => '/triplet'),
    [ 418, ['Content-Type' => 'text/plain', 'Content-Length' => 3], ['tea'] ],
    'triplet passes through untouched');
{
    my $r = hit($app, path => '/three-numbers');
    is($r->[0], 200, 'a 3-element data array is NOT mistaken for a triplet');
    is_deeply(file_json_decode($r->[2][0]), [ 1, 2, 3 ], 'it is JSON data');
}
{
    my $r = hit($app, path => '/data');
    my %h = @{ $r->[1] };
    like($h{'Content-Type'}, qr{^application/json}, 'auto-JSON content type');
    is($h{'Content-Length'}, length $r->[2][0], 'auto-JSON content length');
    is(file_json_decode($r->[2][0])->{pets}[0]{id}, 1, 'auto-JSON body');
}
{
    my $r = hit($app, path => '/created');
    is($r->[0], 201, 'status set via $c folds into auto-JSON');
    my %h = @{ $r->[1] };
    is($h{'X-Made'}, 'yes', 'header set via $c folds in');
}
is(hit($app, path => '/builder')->[0], 202, 'Punk::Response finalizes');
{
    my %h = @{ hit($app, path => '/builder-html')->[1] };
    is($h{'Content-Type'}, 'text/html; charset=utf-8',
        'string builder body defaults to html');
}
is(hit($app, path => '/ctx-json')->[0], 203, '$c->json with status');
is(hit($app, path => '/ctx-text')->[2][0], 'plain', '$c->text');
{
    my %h = @{ hit($app, path => '/ctx-redirect')->[1] };
    is($h{Location}, '/data', '$c->redirect');
}
is(hit($app, path => '/ctx-notfound')->[0], 404, '$c->not_found');
{
    my $r = hit($app, path => '/boom');
    is($r->[0], 500, 'a die is a 500');
    is(file_json_decode($r->[2][0])->{errors}[0]{message}, "kapow\n",
        'error body carries the message');
}

# ---- on_error can take over --------------------------------------------------
{
    package RescueApp;
    use Punk;
    on_error sub {
        my ($c, $err) = @_;
        return $c->json({ rescued => "$err" }, 599);
    };
    get '/boom' => sub { die "oops\n" };
    package main;
    my $r = hit(RescueApp->to_app, path => '/boom');
    is($r->[0], 599, 'on_error response wins');
    is(file_json_decode($r->[2][0])->{rescued}, "oops\n", 'and sees the error');
}

# ---- after_dispatch ----------------------------------------------------------
{
    package AfterApp;
    use Punk;
    hook after_dispatch => sub {
        my ($c, $resp) = @_;
        push @{ $resp->[1] }, 'X-Seen' => $resp->[0];
        return;
    };
    get '/x' => sub { $_[0]->text('x') };
    package main;
    my %h = @{ hit(AfterApp->to_app, path => '/x')->[1] };
    is($h{'X-Seen'}, 200, 'after_dispatch mutates the finalized triplet');
}

# ---- middleware wraps outermost ----------------------------------------------
{
    package MwApp;
    use Punk;
    middleware sub {
        my ($inner) = @_;
        sub {
            my ($env) = @_;
            my $r = $inner->($env);
            push @{ $r->[1] }, 'X-Wrapped' => 1;
            return $r;
        };
    };
    get '/x' => sub { $_[0]->text('x') };
    package main;
    my $r = hit(MwApp->to_app, path => '/nope');
    my %h = @{ $r->[1] };
    is($h{'X-Wrapped'}, 1, 'middleware sees even 404s (outermost wrap)');
}

# ---- finalize, called directly ----------------------------------------------
# Every test above reaches the triplet through a handler. `finalize` is the
# documented method that produces it, and its three defaulting rules - a
# reference becomes JSON, a string becomes text/html, nothing becomes an empty
# text/plain 200 - are only ever observed through helpers that set the type
# themselves, so nothing pinned the defaults down.
{
    my $res = Punk::Response->new;
    my $t = $res->body({ ok => 1 })->finalize;
    is($t->[0], 200, 'a bare response finalizes as 200');
    my %h = @{ $t->[1] };
    is($h{'Content-Type'}, 'application/json',
        'a REFERENCE body is JSON - the rule that decides it is the body, not '
      . 'a type somebody remembered to set');
    like($t->[2][0], qr/"ok"\s*:\s*1/, 'encoded through the JSON ABI');
    is($h{'Content-Length'}, length $t->[2][0], 'Content-Length always set');

    my $s = Punk::Response->new->body('<p>hi</p>')->finalize;
    my %sh = @{ $s->[1] };
    like($sh{'Content-Type'}, qr{^text/html; charset=utf-8},
        'a STRING body defaults to text/html, charset included');
    is($sh{'Content-Length'}, 9, 'with its length');

    my $e = Punk::Response->new->finalize;
    my %eh = @{ $e->[1] };
    is($e->[0], 200, 'no body at all is still a 200');
    like($eh{'Content-Type'}, qr{^text/plain; charset=utf-8}, 'as empty text/plain');
    is($eh{'Content-Length'}, 0, 'with a zero length rather than none');

    my $x = Punk::Response->new->type('text/csv')->body('a,b')->finalize;
    my %xh = @{ $x->[1] };
    is($xh{'Content-Type'}, 'text/csv', 'an explicit type wins over the default');
}

done_testing();
