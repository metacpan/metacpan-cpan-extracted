######################################################################
# 0003-reqres.t - unit tests for PSGI::Handy::Request and ::Response
#
# ina closure-array pattern: one assertion per closure, plan count
# derived from scalar(@tests) and never hard-coded.
######################################################################
use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use PSGI::Handy;

# Minimal in-memory PSGI input, so these unit tests need no server.
# read($buf, $len) fills $buf with up to $len bytes and returns the count.
{
    package PSGITestInput;
    sub new {
        my ($class, $data) = @_;
        $data = '' unless defined $data;
        return bless { buf => $data, pos => 0 }, $class;
    }
    sub read {
        my $self  = $_[0];
        my $len   = $_[2];
        my $chunk = substr($self->{buf}, $self->{pos}, $len);
        $self->{pos} += length($chunk);
        $_[1] = $chunk;
        return length($chunk);
    }
}

# --- minimal TAP helpers --------------------------------------------
my $count = 0;
sub ok {
    my ($cond, $label) = @_;
    $count++;
    print(($cond ? "ok" : "not ok") . " $count - " . (defined $label ? $label : '') . "\n");
    return $cond;
}

# Build a PSGI env with an in-memory input object for psgi.input.
sub make_env {
    my (%a) = @_;
    my $body = defined $a{body} ? $a{body} : '';
    my %env = (
        REQUEST_METHOD => (defined $a{method} ? $a{method} : 'GET'),
        PATH_INFO      => (defined $a{path}   ? $a{path}   : '/'),
        QUERY_STRING   => (defined $a{query}  ? $a{query}  : ''),
        CONTENT_TYPE   => (defined $a{type}   ? $a{type}   : ''),
        CONTENT_LENGTH => length($body),
        'psgi.input'   => PSGITestInput->new($body),
    );
    if ($a{headers}) {
        my $k;
        for $k (keys %{ $a{headers} }) { $env{$k} = $a{headers}{$k}; }
    }
    return \%env;
}

# find value for a key in a flat PSGI header list
sub hdr {
    my ($flat, $want) = @_;
    my $i;
    for ($i = 0; $i < scalar(@$flat); $i += 2) {
        return $flat->[$i + 1] if lc($flat->[$i]) eq lc($want);
    }
    return undef;
}

my @tests = (
    # ---- Request -------------------------------------------------
    # 1
    sub {
        my $r = PSGI::Handy::Request->new(make_env(method => 'GET', path => '/x'));
        ok($r->method eq 'GET' && $r->path eq '/x', 'method and path accessors');
    },
    # 2
    sub {
        my $r = PSGI::Handy::Request->new(make_env(query => 'a=1&b=2'));
        ok($r->param('a') eq '1' && $r->param('b') eq '2', 'query params parsed');
    },
    # 3
    sub {
        my $r = PSGI::Handy::Request->new(make_env(query => 'q=hello+world'));
        ok($r->param('q') eq 'hello world', 'query value url-decoded (+ to space)');
    },
    # 4
    sub {
        my $r = PSGI::Handy::Request->new(make_env(
            method => 'POST',
            type   => 'application/x-www-form-urlencoded',
            body   => 'name=ina&msg=hi',
        ));
        ok($r->param('name') eq 'ina' && $r->param('msg') eq 'hi',
           'urlencoded POST body params parsed');
    },
    # 5
    sub {
        my $r = PSGI::Handy::Request->new(make_env(query => 'tag=a&tag=b&tag=c'));
        my @t = $r->param_all('tag');
        ok(scalar(@t) == 3 && $t[0] eq 'a' && $t[2] eq 'c', 'multi-value param_all');
    },
    # 6
    sub {
        my $r = PSGI::Handy::Request->new(make_env(
            method => 'POST',
            type   => 'application/x-www-form-urlencoded',
            query  => 'a=fromquery',
            body   => 'b=frombody',
        ));
        ok($r->param('a') eq 'fromquery' && $r->param('b') eq 'frombody',
           'query and body params merged');
    },
    # 7
    sub {
        my $r = PSGI::Handy::Request->new(make_env(
            headers => { HTTP_USER_AGENT => 'curl/8' },
        ));
        ok($r->header('User-Agent') eq 'curl/8', 'HTTP_ header lookup by friendly name');
    },
    # 8
    sub {
        my $r = PSGI::Handy::Request->new(make_env(
            type => 'text/plain; charset=utf-8',
        ));
        ok($r->header('Content-Type') eq 'text/plain; charset=utf-8',
           'Content-Type header (no HTTP_ prefix) resolved');
    },
    # 9
    sub {
        my $r = PSGI::Handy::Request->new(make_env(
            headers => { HTTP_COOKIE => 'sid=abc123; theme=dark' },
        ));
        ok($r->cookie('sid') eq 'abc123' && $r->cookie('theme') eq 'dark',
           'cookies parsed from Cookie header');
    },
    # 10
    sub {
        my $r = PSGI::Handy::Request->new(make_env(
            method => 'POST',
            type   => 'application/json',
            body   => '{"k":1}',
        ));
        ok($r->body eq '{"k":1}', 'raw body available for non-form content type');
    },
    # 11 - non-form body must NOT populate params
    sub {
        my $r = PSGI::Handy::Request->new(make_env(
            method => 'POST',
            type   => 'application/json',
            body   => 'k=should_not_parse',
        ));
        ok(!defined($r->param('k')), 'json body is not parsed as form params');
    },

    # ---- Response ------------------------------------------------
    # 12
    sub {
        my $a = PSGI::Handy::Response->html('<h1>Hi</h1>')->finalize;
        ok($a->[0] == 200 && hdr($a->[1], 'Content-Type') eq 'text/html; charset=utf-8'
              && $a->[2][0] eq '<h1>Hi</h1>',
           'html() finalizes to 200 + html CT + body');
    },
    # 13
    sub {
        my $a = PSGI::Handy::Response->text('nope', 404)->finalize;
        ok($a->[0] == 404 && hdr($a->[1], 'Content-Type') =~ m{text/plain},
           'text() honours status code');
    },
    # 14
    sub {
        my $a = PSGI::Handy::Response->json('{"ok":1}')->finalize;
        ok(hdr($a->[1], 'Content-Type') eq 'application/json', 'json() sets JSON CT');
    },
    # 14b - json() rejects a reference (must be a pre-encoded string)
    sub {
        my $ok = eval { PSGI::Handy::Response->json({ ok => 1 }); 1 };
        ok(!$ok && $@ =~ /pre-encoded JSON string/,
           'json() croaks when given a reference');
    },
    # 15
    sub {
        my $a = PSGI::Handy::Response->redirect('/login')->finalize;
        ok($a->[0] == 302 && hdr($a->[1], 'Location') eq '/login',
           'redirect() is 302 with Location');
    },
    # 16 - Content-Length computed at finalize
    sub {
        my $a = PSGI::Handy::Response->html('12345')->finalize;
        ok(hdr($a->[1], 'Content-Length') == 5, 'Content-Length computed from body');
    },
    # 17 - set_header replaces, header appends
    sub {
        my $res = PSGI::Handy::Response->new;
        $res->header('X-A', '1')->set_header('Content-Type', 'a')
            ->set_header('Content-Type', 'b');
        my $a = $res->finalize;
        ok(hdr($a->[1], 'Content-Type') eq 'b' && hdr($a->[1], 'X-A') eq '1',
           'set_header replaces, header appends');
    },
    # 18 - chained builder with status + body
    sub {
        my $a = PSGI::Handy::Response->new->set_status(201)
                  ->content_type('text/html')->set_body('made')->finalize;
        ok($a->[0] == 201 && $a->[2][0] eq 'made', 'chained build produces 201 + body');
    },
    # 19 - cookie header present and value percent-encoded
    sub {
        my $a = PSGI::Handy::Response->new->cookie('sid', 'a b', path => '/')->finalize;
        my $sc = hdr($a->[1], 'Set-Cookie');
        ok(defined($sc) && $sc =~ /sid=a%20b/ && $sc =~ m{Path=/},
           'Set-Cookie present, value encoded, Path set');
    },
);

print "1.." . scalar(@tests) . "\n";
my $t;
for $t (@tests) {
    $t->();
}
