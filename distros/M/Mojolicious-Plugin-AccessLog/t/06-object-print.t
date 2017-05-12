#!/usr/bin/env perl

use Mojo::Base -strict;

# Disable IPv6 and libev
BEGIN {
    $ENV{MOJO_NO_IPV6} = 1;
    $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll';
}

use lib 't/lib';

use MPA_Test qw(log2unixtime);
use Test::More;

use Mojo::Util qw(b64_encode);
use Mojolicious::Lite;
use Test::Mojo;
use Time::HiRes ();

{
    package Logger;

    sub new {
        my ($class, $logref) = @_;
        bless $logref, $class;
    }

    sub print {
        my $self = shift;

        $$self = join '', @_;
    }

    sub peek { ${$_[0]} }
}

# and now disable log output written with Mojo::Log methods
app->log->unsubscribe('message');

my $log = Logger->new(\my $b);

plugin 'AccessLog', log => $log, format => 'combined';

any '/:any' => sub {
    my $c = shift;
    my $req_h = $c->req->headers;
    my $xuser = $req_h->header('X-User');
    my $delay = $req_h->header('X-Delay') || 0;

    while ($delay > 0) {
        $delay -= Time::HiRes::sleep($delay);
    }

    $c->req->env->{REMOTE_USER} = $xuser if $xuser;
    $c->render(text => 'done');
};

my $t = Test::Mojo->new;

sub req_ok {
    my ($method, $url, $code, $opts) = @_;
    my $m = $t->can($method . '_ok')
        or return fail "Cannot $method $url";
    my $user = '-';

    $opts = {} unless ref $opts eq 'HASH';

    if (index($url, '@') > -1) {
        ($user, $url) = split '@', $url, 2;
        $opts->{Authorization} = 'Basic ' . b64_encode($user . ':pass', '');
        $user =~ s/([^[:print:]]|\s)/'\x' . unpack('H*', $1)/eg;
    }
    elsif ($opts->{'X-User'}) {
        $user = $opts->{'X-User'};
        $user =~ s/([^[:print:]]|\s)/'\x' . unpack('H*', $1)/eg;
    }

    my $x = sprintf qq'^%s - %s (%s) "%s %s HTTP/1.1" %d %s "%s" "%s"\$',
        '127\.0\.0\.1',
        quotemeta($user),
        '\[\d{1,2}/\w{3}/\d{4}:\d{2}:\d{2}:\d{2} [\+\-]\d{4}\]',
        uc($method),
        quotemeta($url),
        $code,
        '\d+',
        $opts->{Referer} ? quotemeta($opts->{Referer}) : '-',
        quotemeta('Mojolicious (Perl)');

    # issue request
    $m->($t, $url, $opts)->status_is($code);

    # check log line
    my $l = $log->peek;
    chomp $l;

    if (like($l, qr/$x/, $l) and $opts->{'X-Delay'}) {
        $l =~ qr/$x/;
        my $reqtime = log2unixtime($1);
        cmp_ok $reqtime, '<', time, "request time is before current time";
    }
}

req_ok(get => '/' => 404, {Referer => 'http://www.example.com/'});
req_ok(get => '/slow' => 200, {Referer => '/', 'X-Delay' => 2});
req_ok(post => '/a_letter' => 200, {Referer => '/'});
req_ok(put => '/option' => 200);
{
    req_ok(get => "3v!l b0y\@/more?foo=bar&foo=baz" => 200);
    req_ok(get => "/more?foo=bar&foo=baz" => 200, {'X-User' => 'good boy'});
}
req_ok(delete => '/fb_account' => 200, {Referer => '/are_you_sure?'});

done_testing;
