######################################################################
# 0005-app.t - integration tests for PSGI::Handy
#
# Drives the assembled PSGI app via to_app() by calling $app->($env)
# directly (no live socket). ina closure-array pattern: one assertion
# per closure, plan count derived from scalar(@tests).
######################################################################
use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use PSGI::Handy;

# Minimal in-memory PSGI input, so these tests need no server.
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
    return \%env;
}

sub hdr {
    my ($flat, $want) = @_;
    my $i;
    for ($i = 0; $i < scalar(@$flat); $i += 2) {
        return $flat->[$i + 1] if lc($flat->[$i]) eq lc($want);
    }
    return undef;
}

# body string from a PSGI response arrayref
sub body_of {
    my ($psgi) = @_;
    return join('', @{ $psgi->[2] });
}

# A trivial template renderer: replaces {{ key }} with vars{key}.
my $renderer = sub {
    my ($template, $vars) = @_;
    my $out = $template;
    $out =~ s/\{\{\s*(\w+)\s*\}\}/defined $vars->{$1} ? $vars->{$1} : ''/eg;
    return $out;
};

# A fake DB handle: remembers rows pushed to it.
my $fake_db = bless { rows => [] }, 'FakeDB';
sub FakeDB::insert { my ($s, $r) = @_; push @{ $s->{rows} }, $r; return scalar @{ $s->{rows} }; }
sub FakeDB::count  { my ($s) = @_; return scalar @{ $s->{rows} }; }

# Build one configured app reused by most tests.
sub build_app {
    my $app = PSGI::Handy->new(renderer => $renderer, db => $fake_db);
    $app->get('/', sub { my $c = shift; return $c->html('<h1>home</h1>'); });
    $app->get('/users/:id', sub {
        my $c = shift;
        return $c->text('id=' . $c->param('id'));
    });
    $app->post('/users', sub {
        my $c = shift;
        $c->db->insert({ name => $c->param('name') });
        return $c->redirect('/');
    });
    $app->get('/tmpl', sub {
        my $c = shift;
        $c->stash(greeting => 'Hi');
        return $c->render('{{ greeting }}, {{ who }}!', { who => 'ina' });
    });
    $app->get('/raw',    sub { return [200, ['Content-Type','text/plain'], ['raw-array']]; });
    $app->get('/str',    sub { return 'plain-string'; });
    $app->get('/boom',   sub { die "kaboom\n"; });
    return $app;
}

my @tests = (
    # 1: GET / -> 200 + body
    sub {
        my $a = build_app()->to_app;
        my $r = $a->(make_env(path => '/'));
        ok($r->[0] == 200 && body_of($r) eq '<h1>home</h1>', 'GET / returns 200 + body');
    },
    # 2: path parameter reaches the handler via $c->param
    sub {
        my $a = build_app()->to_app;
        my $r = $a->(make_env(path => '/users/42'));
        ok($r->[0] == 200 && body_of($r) eq 'id=42', 'path param via $c->param');
    },
    # 3: 404 for unknown path
    sub {
        my $a = build_app()->to_app;
        my $r = $a->(make_env(path => '/nope'));
        ok($r->[0] == 404, 'unknown path returns 404');
    },
    # 4: 405 with Allow header (GET implies HEAD; OPTIONS always offered)
    sub {
        my $a = build_app()->to_app;
        my $r = $a->(make_env(method => 'DELETE', path => '/users/42'));
        ok($r->[0] == 405 && hdr($r->[1], 'Allow') eq 'GET, HEAD, OPTIONS',
           'method mismatch returns 405 + augmented Allow');
    },
    # 4b: OPTIONS on a known path is answered with 204 + Allow
    sub {
        my $a = build_app()->to_app;
        my $r = $a->(make_env(method => 'OPTIONS', path => '/users/42'));
        ok($r->[0] == 204
           && hdr($r->[1], 'Allow') eq 'GET, HEAD, OPTIONS'
           && body_of($r) eq '',
           'OPTIONS on known path returns 204 + Allow, empty body');
    },
    # 5: POST body param + db injection + redirect
    sub {
        my $app  = build_app();
        my $a    = $app->to_app;
        my $before = $app->db->count;
        my $r = $a->(make_env(
            method => 'POST', path => '/users',
            type   => 'application/x-www-form-urlencoded',
            body   => 'name=ina',
        ));
        ok($r->[0] == 302 && $app->db->count == $before + 1,
           'POST uses body param + db, then redirects (302)');
    },
    # 6: render via injected renderer, stash + vars merged
    sub {
        my $a = build_app()->to_app;
        my $r = $a->(make_env(path => '/tmpl'));
        ok($r->[0] == 200 && body_of($r) eq 'Hi, ina!',
           'render merges stash and vars');
    },
    # 7: handler may return a raw PSGI arrayref
    sub {
        my $a = build_app()->to_app;
        my $r = $a->(make_env(path => '/raw'));
        ok($r->[0] == 200 && body_of($r) eq 'raw-array', 'raw arrayref passes through');
    },
    # 8: handler may return a plain string -> html 200
    sub {
        my $a = build_app()->to_app;
        my $r = $a->(make_env(path => '/str'));
        ok($r->[0] == 200 && body_of($r) eq 'plain-string'
              && hdr($r->[1], 'Content-Type') =~ m{text/html},
           'plain string becomes html 200');
    },
    # 9: a dying handler is caught and yields 500
    sub {
        my $a = build_app()->to_app;
        my $r = $a->(make_env(path => '/boom'));
        ok($r->[0] == 500, 'dying handler yields 500');
    },
    # 10: HEAD on a GET route -> empty body, Content-Length preserved
    sub {
        my $a = build_app()->to_app;
        my $r = $a->(make_env(method => 'HEAD', path => '/'));
        ok($r->[0] == 200 && body_of($r) eq '' && hdr($r->[1], 'Content-Length') == 13,
           'HEAD keeps headers, drops body');
    },
    # 11: before hook short-circuits (handler not reached)
    sub {
        my $app = PSGI::Handy->new;
        $app->before(sub {
            my $c = shift;
            return $c->text('blocked', 403) if $c->req->path eq '/secret';
            return;
        });
        $app->get('/secret', sub { return 'SHOULD NOT RUN'; });
        my $r = $app->to_app->(make_env(path => '/secret'));
        ok($r->[0] == 403 && body_of($r) eq 'blocked', 'before hook short-circuits');
    },
    # 12: after hook can add a header to the response
    sub {
        my $app = PSGI::Handy->new;
        $app->get('/', sub { return shift->html('x'); });
        $app->after(sub {
            my ($c, $out) = @_;
            $out->set_header('X-Powered-By', 'PSGI::Handy') if ref($out);
            return $out;
        });
        my $r = $app->to_app->(make_env(path => '/'));
        ok(hdr($r->[1], 'X-Powered-By') eq 'PSGI::Handy', 'after hook adds header');
    },
    # 13: any() registers the handler for multiple methods
    sub {
        my $app = PSGI::Handy->new;
        $app->any('/ping', sub { return shift->text('pong'); });
        my $g = $app->to_app->(make_env(method => 'GET',  path => '/ping'));
        my $p = $app->to_app->(make_env(method => 'POST', path => '/ping'));
        ok($g->[0] == 200 && $p->[0] == 200, 'any() matches GET and POST');
    },
    # 14: custom not_found handler is used
    sub {
        my $app = PSGI::Handy->new(
            not_found => sub { return shift->text('custom 404', 404); },
        );
        my $r = $app->to_app->(make_env(path => '/missing'));
        ok($r->[0] == 404 && body_of($r) eq 'custom 404', 'custom not_found handler used');
    },
    # 15: $c->config exposes injected config
    sub {
        my $app = PSGI::Handy->new(config => { site => 'PSGI' });
        $app->get('/cfg', sub { my $c = shift; return $c->text($c->config('site')); });
        my $r = $app->to_app->(make_env(path => '/cfg'));
        ok($r->[0] == 200 && body_of($r) eq 'PSGI', 'config value reachable in handler');
    },
);

print "1.." . scalar(@tests) . "\n";
my $t;
for $t (@tests) {
    $t->();
}
