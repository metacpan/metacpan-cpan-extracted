#!/usr/bin/env perl

use Mojo::Base -strict;

# Disable IPv6 and libev
BEGIN {
    $ENV{MOJO_NO_IPV6} = 1;
    $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll';
}

use Test::More;

use Fcntl qw(:seek);
use File::Spec;
use IO::File;
use Mojo::Util qw(b64_encode);
use Mojolicious::Lite;
use Test::Mojo;

my $logfile = File::Spec->catfile(
    File::Spec->tmpdir, join('.', 'accesslog', time, $$, int(rand(1000)))
);

my $logfh = IO::File->new($logfile, O_WRONLY|O_CREAT)
    or die "failed to open logfile $logfile for writing: $!";

# disable log output written with Mojo::Log methods
app->log->unsubscribe('message');

plugin 'AccessLog',
    log => $logfh,
    format =>
        '"%{Referer}i" "%{User-Agent}i" "%{Set-Cookie}i" ' .
        '%s %{Content-Length}o "%{Content-Type}o" "%{Date}o" ' .
        '%{%s}t [%{%d/%b/%Y %H:%M:%S}t.%{msec_frac}t %{%z}t]';

put '/option' => sub {
    my $self = shift;
    $self->res->code(403);
    $self->render(text => 'done');
};

any '/:any' => sub {
    my $c = shift;
    my $xuser = $c->req->headers->header('X-User');

    $c->req->env->{REMOTE_USER} = $xuser if $xuser;
    $c->render(text => 'done');
};

my $t = Test::Mojo->new;

open my $tail, '<', $logfile
    or die "failed to open logfile $logfile: $!";

seek $tail, 0, SEEK_END;   # goto eof

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
    }
    elsif ($opts->{'X-User'}) {
        $user = $opts->{'X-User'};
        $user =~ s/([^[:print:]]|\s)/'\x' . unpack('H*', $1)/eg;
    }

    $pos = index($url, '?');

    if ($pos > -1) {
        $query = substr $url, $pos;
        $url = substr $url, 0, $pos;
    }

    my $x = sprintf '^"%s" "%s" "%s" %d %s "%s" "%s" %s \[%s\]$',
        $opts->{Referer} ? quotemeta($opts->{Referer}) : '-',
        quotemeta('Mojolicious (Perl)'),
        $opts->{'Set-Cookie'} ? quotemeta($opts->{'Set-Cookie'}) : '-',
        $code,
        $code < 300 ? '4' : '\d+',
        quotemeta('text/html;charset=UTF-8'),
        '(Mon|Tue|Wed|Thu|Fri|Sat|Sun)\, \d{2} (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) \d{4} \d{2}:\d{2}:\d{2} GMT',
        '\d{10}',
        '\d{2}/\w{3}/\d{4} \d{2}:\d{2}:\d{2}\.\d{3} [\+\-]\d{4}';

    # issue request
    my $t = $m->($t, $url . $query, $opts)->status_is($code)->tx->res->headers;

    # check last log line
    seek $tail, 0, SEEK_CUR;  # clear EOF condition

    defined(my $l = <$tail>)
        or return fail "no tail line in log file";
    chomp $l;

    eof $tail
        or return fail "not eof after reading last log line";

    like $l, qr{$x}, $l;
}

req_ok(
    get => '/' => 404,
    {
        Referer => 'http://www.example.com/',
        'Set-Cookie' => 'SID=4711; Path=/; Domain=example.org',
    }
);
req_ok(post => '/a_letter' => 200, {Referer => '/'});
req_ok(put => '/option' => 403);
{
    req_ok(get => "3v!lb0y\@/more?foo=bar&foo=baz" => 200);
    req_ok(get => "/more?foo=bar&foo=baz" => 200, {'X-User' => 'good boy'});
}
req_ok(delete => '/fb_account' => 200, {Referer => '/are_you_sure?'});

1 while unlink $logfile;

done_testing;
