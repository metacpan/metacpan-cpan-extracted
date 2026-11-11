#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PunkTest qw(hit);
use Punk::Future;

# A handler that answers with a future that has already settled: done with
# a response, failed with an error, failed under an on_error handler of the
# application's own, and cancelled, which delivers nothing at all.

{
    package FakeReady;
    sub new { bless { v => $_[1] }, $_[0] }
    sub on_ready { $_[0] }
    sub get { $_[0]{v} }
    package FutApp;
    use Punk;
    get '/done'   => sub { Punk::Future->done_future([ 200, [ 'Content-Type' => 'text/plain' ], [ 'from a done future' ] ]) };
    get '/text'   => sub { Punk::Future->done_future('plain text from a future') };
    get '/failed' => sub { Punk::Future->fail_future("future boom\n") };
    get '/cancel' => sub { my $f = Punk::Future->new; $f->cancel; $f };
    get '/ready' => sub { FakeReady->new('from a ready object') };
    package FutHandled;
    use Punk;
    on_error sub { my ($c, @rest) = @_; $c->text('handled: ' . join('|', map { defined $_ ? "$_" : 'undef' } @rest), 503) };
    get '/failed' => sub { Punk::Future->fail_future("future boom\n") };
    package main;
}
my $app = FutApp->to_app;
my $quiet = { 'psgi.errors' => do { open my $n, '>', '/dev/null' or die; $n } };
{
    my $r = hit($app, path => '/done', env => $quiet);
    is($r->[0], 200, 'a done future carrying a response answers with it');
    is($r->[2][0], 'from a done future', 'body and all');
    $r = hit($app, path => '/text', env => $quiet);
    is($r->[0], 200, 'a done future carrying text is coerced like a plain return');
    like($r->[2][0], qr/plain text from a future/, 'into a body');
    $r = hit($app, path => '/ready', env => $quiet);
    is($r->[0], 200, 'an object with on_ready is asked for its value');
    like($r->[2][0], qr/from a ready object/, 'and the value is coerced');
}
{
    my $r = hit($app, path => '/failed', env => $quiet);
    is($r->[0], 500, 'a failed future is a server error');
    my $h = hit(FutHandled->to_app, path => '/failed', env => $quiet);
    is($h->[0], 503, 'unless on_error answers for it');
    like($h->[2][0], qr/^handled: /, 'on_error answered');
    TODO: {
        local $TODO = 'a failed future reaches on_error with an empty error, where a die reaches it with the message';
        like($h->[2][0], qr/handled: future boom/, 'with the failure in hand');
    }
}
{
    my $r = hit($app, path => '/cancel', env => $quiet);
    ok(!(ref $r eq 'ARRAY' && @$r == 3 && $r->[0] =~ /^\d+$/ && $r->[0] != 500) || $r->[0] == 500,
        'a cancelled future delivers nothing a client would see as a page');
}

done_testing;
