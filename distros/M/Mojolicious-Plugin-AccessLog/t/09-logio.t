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

# Logger
my $log = '';
open my $fh, '>>:scalar', \$log or die;

# redirect all logging to $log
app->log->handle($fh);

# disable log output written with Mojo::Log methods
app->log->unsubscribe('message');

plugin 'AccessLog', format => 'combinedio';

get '/dynamic' => sub {
    my $c = shift;

    $c->res->code(200);
    $c->res->headers->content_type('text/plain');

    return if $c->res->content->skip_body;

    my $delay1 = my $delay2 = ($c->req->headers->header('X-Delay') || 0) / 2;

    $c->write_chunk('He' => sub {
        my $c = shift;

        while ($delay1 > 0) {
            $delay1 -= Time::HiRes::sleep($delay1);
        }

        $c->write_chunk('ll' => sub {
            my $c = shift;

            while ($delay2 > 0) {
                $delay2 -= Time::HiRes::sleep($delay2);
            }
            $c->finish('o!');
        });
    });
};

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
    my $query = '';
    my $pos;

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

    # issue request
    my $br = my $bw = '';
    my $start = $t->ua->on(start => sub {
        my ($ua, $tx) = @_;
        $tx->on(connection => sub {
            my ($tx, $connection) = @_;
            my $s = Mojo::IOLoop->stream($connection);
            my $r = $s->on(read  => sub { $bw .= $_[1] });
            my $w = $s->on(write => sub { $br .= $_[1] });

            $tx->on(finish => sub {
                $s->unsubscribe(read  => $r);
                $s->unsubscribe(write => $w);
            });
        });
    });

    my $res = $m->($t, $url . $query, $opts)
        ->status_is($code)
        ->tx->res;
    $t->ua->unsubscribe(start => $start);
    my $empty_line_pos = index($bw, "\r\n\r\n");
    my ($header_size, $body_size);

    if ($empty_line_pos > 0) {
        $header_size = $empty_line_pos + 4;
        $body_size = length($bw) - $header_size;
    }

    my $x = sprintf qq'^%s - %s (%s) "%s %s HTTP/1.1" %d %s "%s" "%s" %s %d\$',
        '127\.0\.0\.1',
        quotemeta($user),
        '\[\d{1,2}/\w{3}/\d{4}:\d{2}:\d{2}:\d{2} [\+\-]\d{4}\]',
        uc($method),
        quotemeta($url),
        $code,
        $opts->{nolength} ? '-' : $body_size || '-',
        $opts->{Referer} ? quotemeta($opts->{Referer}) : '-',
        quotemeta('Mojolicious (Perl)'),
        length($br),
        length($bw);

    # check last log line
    my ($l) = (split $/, $log)[-1];
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
    req_ok(get => "3v!l b0y\ntoy\@/more?foo=bar&foo=baz" => 200);
    req_ok(get => "/more?foo=bar&foo=baz" => 200, {'X-User' => 'good boy'});
}
req_ok(delete => '/fb_account' => 200, {Referer => '/are_you_sure?'});
req_ok(get => '/dynamic' => 200, {'X-Delay' => 2});
req_ok(head => '/dynamic' => 200);
req_ok(get => '/static.txt' => 206, {Range => 'bytes=2-6'});

done_testing;

__DATA__
@@ static.txt (base64)
dGVzdCAxMjMKbGFsYWxh
