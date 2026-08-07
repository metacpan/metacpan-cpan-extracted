#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use PunkTest;

# $c->cookie: set a Set-Cookie on the response, read a request cookie, delete.

{
    package CApp;
    use Punk;
    get '/set' => sub { my $c = shift;
        $c->cookie(sid => 'abc', max_age => 3600, httponly => 1,
                   samesite => 'Lax', secure => 1);
        $c->text('ok');
    };
    get '/two' => sub { my $c = shift;
        $c->cookie(a => 1); $c->cookie(b => 2); $c->text('ok');
    };
    get '/del'  => sub { my $c = shift; $c->cookie(sid => undef); $c->text('bye') };
    get '/enc'  => sub { my $c = shift; $c->cookie(x => 'a b;c'); $c->text('ok') };
    get '/read' => sub { my $c = shift; $c->text($c->cookie('sid') // 'none') };
    package main;
}

my $app = CApp->to_app;
sub set_cookies {
    my ($r) = @_;
    my @c;
    for (my $i = 0; $i < @{ $r->[1] }; $i += 2) {
        push @c, $r->[1][$i + 1] if $r->[1][$i] eq 'Set-Cookie';
    }
    return @c;
}

my ($sc) = set_cookies(hit($app, path => '/set'));
like($sc, qr/^sid=abc;/, 'sets the cookie value');
like($sc, qr/Path=\//,        'Path=/ by default');
like($sc, qr/Max-Age=3600/,   'Max-Age');
like($sc, qr/HttpOnly/,       'HttpOnly');
like($sc, qr/SameSite=Lax/,   'SameSite');
like($sc, qr/Secure/,         'Secure');

my @two = set_cookies(hit($app, path => '/two'));
is(scalar @two, 2, 'two cookies -> two Set-Cookie headers');

my ($del) = set_cookies(hit($app, path => '/del'));
like($del, qr/sid=; .*Max-Age=0/, 'undef value deletes the cookie');

my ($enc) = set_cookies(hit($app, path => '/enc'));
like($enc, qr/^x=a%20b%3Bc;/, 'unsafe value bytes are percent-encoded');

my $r = hit($app, path => '/read', env => { HTTP_COOKIE => 'sid=abc; k=v' });
is($r->[2][0], 'abc', 'one-arg cookie() reads the request cookie');

done_testing;
