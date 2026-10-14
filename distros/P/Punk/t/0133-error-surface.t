#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use Punk ();

# What leaves the application when something goes wrong, and what a handler
# is allowed to put on the status line, in a header and in a log.
#
# PUNK_ENV is set per block here, on purpose: most of this is the difference
# between the environments.

my @log;
sub call {
    my ($app, $path, %o) = @_;
    open my $in, '<', \'' or die $!;
    my $r = $app->({ REQUEST_METHOD => $o{method} // 'GET', PATH_INFO => $path,
                     QUERY_STRING => $o{query} // '', 'psgi.input' => $in,
                     'psgi.errors' => \*STDERR, %{ $o{env} || {} } });
    my $body = ref $r->[2] eq 'ARRAY' ? join('', @{ $r->[2] }) : '';
    return ($r->[0], { @{ $r->[1] } }, $body, $r);
}

{
    package Surface;
    use Punk;
    logging to => sub { push @log, $_[0] };

    get '/die'  => sub { die "secret dsn dbi:Pg:host=db1 at /srv/app/lib/X.pm line 9.\n" };
    get '/obj'  => sub { die { code => 42 } };
    get '/text' => sub { $_[0]->text('x', $_[0]->req->query->{s}) };
    get '/html' => sub { $_[0]->html('x', $_[0]->req->query->{s}) };
    get '/json' => sub { $_[0]->json({ ok => 1 }, $_[0]->req->query->{s}) };
    get '/pend' => sub { $_[0]->status($_[0]->req->query->{s})->text('x') };
    get '/resp' => sub {
        require Punk::Response;
        Punk::Response->new(status => $_[0]->req->query->{s}, body => 'x');
    };
    get '/cookie-then-bad' => sub {
        my ($c) = @_;
        $c->cookie(sid => 'secret-session-value');
        $c->json({ ok => 1 }, 999);
    };
    get '/raw' => sub {
        my $kind = $_[0]->req->query->{k} // '';
        return [ 999, [ 'Set-Cookie' => 'sid=leak', 'Content-Type' => 'text/plain' ], ['x'] ]
            if $kind eq 'bad';
        return [ 0, [ 'Set-Cookie' => 'sid=leak' ], ['x'] ] if $kind eq 'zero';
        return [ 1, 2, 3 ] if $kind eq 'nums';
        return [ 'series', [ 1, 2 ], [ 3, 4 ] ] if $kind eq 'series';
        return [ 5, [ 1, 2 ], [ 3, 4 ] ] if $kind eq 'pairs';
        return [ 201, [ 'Content-Type' => 'text/plain' ], ['made'] ];
    };
    get '/go'  => sub { $_[0]->redirect($_[0]->req->query->{to}, $_[0]->req->query->{s}) };
    get '/log' => sub { $_[0]->log->info($_[0]->req->query->{m}); $_[0]->text('ok') };
}
my $app = Surface->to_app;

# ---- a 500 says what died only to somebody who may be told --------------------
{
    for my $env (undef, 'production', 'staging', 'live') {
        local $ENV{PUNK_ENV} = $env;
        delete $ENV{PUNK_ENV} unless defined $env;
        @log = ();
        my $name = $env // 'unset';
        my ($st, $h, $body) = call($app, '/die');
        is($st, 500, "PUNK_ENV $name: a die is a 500");
        is($body, '{"errors":[{"message":"Internal Server Error"}]}',
            '...with a fixed body');
        unlike($body, qr/dsn|dbi:|\.pm|line \d/, '...and nothing of the die text');
        is(scalar @log, 1, '...which went to the log instead, once');
        like($log[0], qr/\[error\] GET \/die - secret dsn dbi:Pg:host=db1 at \/srv\/app\/lib\/X\.pm line 9\.$/,
            '...whole, at error, with the request it belongs to');
    }
    for my $env ('development', 'test') {
        local $ENV{PUNK_ENV} = $env;
        @log = ();
        my ($st, $h, $body) = call($app, '/die');
        is($st, 500, "PUNK_ENV $env: a die is a 500");
        like($body, qr/secret dsn dbi:Pg:host=db1 at \/srv\/app\/lib\/X\.pm line 9/,
            '...and the body says what died');
        is(scalar @log, 0, '...with nothing extra in the log');
    }
    {
        local $ENV{PUNK_ENV} = 'production';
        @log = ();
        my ($st, $h, $body) = call($app, '/obj');
        is($body, '{"errors":[{"message":"Internal Server Error"}]}',
            'a die with a reference is the fixed body too');
        is(scalar @log, 1, '...and is logged');
    }
}

# ---- a status is 100 to 599 -----------------------------------------------------
{
    local $ENV{PUNK_ENV} = 'test';
    for my $route (qw(/text /html /json /pend /resp)) {
        for my $bad (999, 1, 99, 600, -5, 'abc', '2oo', '200.5') {
            my ($st, $h, $body) = call($app, $route, query => "s=$bad");
            is($st, 500, "$route with status '$bad' is an error");
            like($body, qr/a response status must be a number from 100 to 599/,
                '...that says so');
        }
        for my $good (100, 200, 204, 404, 599) {
            my ($st) = call($app, $route, query => "s=$good");
            is($st, $good, "$route with status $good is sent as $good");
        }
        my ($st) = call($app, $route, query => 's=0');
        is($st, 200, "$route with status 0 is the default, as before");
        ($st) = call($app, $route);
        is($st, 200, "$route with no status is the default");
    }

    my ($st, $h, $body) = call($app, '/cookie-then-bad');
    is($st, 500, 'a bad status after a cookie was set is an error');
    unlike($body, qr/secret-session-value|Set-Cookie/,
        '...and the cookie is not in the body, where it used to be dumped');
}

# ---- a response built by hand with a bad status is not data --------------------
{
    local $ENV{PUNK_ENV} = 'test';
    for my $kind (qw(bad zero)) {
        my ($st, $h, $body) = call($app, '/raw', query => "k=$kind");
        is($st, 500, "a hand-built response with a $kind status is an error");
        like($body, qr/status is not a number from 100 to 599/, '...that says so');
        unlike($body, qr/sid=leak/, '...and its headers are not encoded into a body');
    }
    my ($st, $h, $body) = call($app, '/raw');
    is($st, 201, 'a hand-built response with a real status passes through');
    is($body, 'made', '...as it was');

    ($st, $h, $body) = call($app, '/raw', query => 'k=nums');
    is($body, '[1,2,3]', 'three numbers are still data');
    ($st, $h, $body) = call($app, '/raw', query => 'k=series');
    is($body, '["series",[1,2],[3,4]]', '...a label and two lists are still data');
    ($st, $h, $body) = call($app, '/raw', query => 'k=pairs');
    is($body, '[5,[1,2],[3,4]]', '...and so is a number and two lists of numbers');
}

# ---- a Location is one line ------------------------------------------------------
{
    local $ENV{PUNK_ENV} = 'test';
    for my $case ([ '/x%0d%0aSet-Cookie:%20a=b', 'CRLF' ], [ '/x%0aX:%20y', 'LF' ],
                  [ '/x%0dy', 'CR' ], [ '/x%00y', 'NUL' ]) {
        my ($st, $h, $body, $r) = call($app, '/go', query => "to=$case->[0]");
        is($st, 500, "a redirect to a URL with $case->[1] is refused");
        like($body, qr/a redirect location may not contain CR, LF or NUL/, '...by name');
        ok(!exists $h->{Location} && !grep({ /a=b|X: y/ } @{ $r->[1] }),
            '...and no header is sent for it');
    }
    my ($st, $h) = call($app, '/go', query => 'to=/next%3Fa=1%26b=2');
    is($st, 302, 'an ordinary redirect is a 302');
    is($h->{Location}, '/next?a=1&b=2', '...to the URL given');
    ($st) = call($app, '/go', query => 'to=/next&s=303');
    is($st, 303, '...with the status asked for');
    ($st) = call($app, '/go', query => 'to=/next&s=999');
    is($st, 500, '...unless that is not a status');
}

# ---- a log line is one line --------------------------------------------------------
{
    local $ENV{PUNK_ENV} = 'test';
    @log = ();
    call($app, '/log', query => 'm=hello%0A[2026-01-01T00:00:00Z]%20[error]%20forged%0D%1b[2Jx%00y%7f');
    is(scalar @log, 1, 'a message with a newline in it is one record');
    is(($log[0] =~ tr/\n//), 1, '...on one line');
    like($log[0], qr/ - hello\\n\[2026-01-01T00:00:00Z\] \[error\] forged\\r\\x1b\[2Jx\\x00y\\x7f$/,
        '...with every control byte written out');
    unlike($log[0], qr/\e|\r|\0/, '...and none of them left in it');

    @log = ();
    call($app, "/log\n[2026-01-01T00:00:00Z] [error] path", query => 'm=x');
    @log = ();
    call($app, '/log', query => 'm=plain%20text%20caf%C3%A9');
    like($log[0], qr/ - plain text caf\xC3\xA9$/, 'an ordinary message is unchanged');
}
{
    # the path is request bytes too, and it is in every request's line
    package PathLog;
    use Punk;
    logging to => sub { push @log, $_[0] };
    hook before_request => sub { $_[0]->log->info('seen'); return };
    get '/x' => sub { $_[0]->text('x') };
    package main;
    @log = ();
    call(PathLog->to_app, "/a\n[2026-01-01T00:00:00Z] [error] forged");
    is(scalar @log, 1, 'a path with a newline in it is one record');
    is(($log[0] =~ tr/\n//), 1, '...on one line');
    like($log[0], qr{GET /a\\n\[2026}, '...with the newline written out');
}

# ---- a class named in a keyword or in punk.yml is a class name -----------------
{
    our $INJECTED = 0;
    for my $name ('+Punk::Config; $main::INJECTED++; package Punk::Config; sub register {1}; 1; #',
                  '+Nope; $main::INJECTED++; #', "+Foo\nBar", '+Foo::', '+::Foo',
                  '+Foo:Bar', '+9Foo', '+Foo Bar', '+') {
        my $err = '';
        eval { Punk::App->new->plugin($name); 1 } or $err = $@;
        (my $show = $name) =~ s/\n/\\n/g;
        like($err, qr/is not a class name, so it will not be loaded/,
            "plugin '$show' is refused");
    }
    is($INJECTED, 0, '...and none of them ran anything');

    my $err = '';
    eval { Punk::App->new->plugin('+Punk::Plugin::NoSuchPluginAtAll'); 1 } or $err = $@;
    like($err, qr/failed to load/, 'a real class name that does not exist fails as before');
    unlike($err, qr/not a class name/, '...for that reason');

    $err = '';
    eval {
        package EvilViews;
        use Punk;
        views 'Stencil; $main::INJECTED++; #' => {};
        EvilViews->to_app;
        1;
    } or $err = $@;
    like($err, qr/is not a class name|unknown|Stencil/, 'a view engine name is checked too');
    is($INJECTED, 0, '...and ran nothing');
}

# ---- logging to a path -------------------------------------------------------------
{
    my $dir = File::Temp->newdir;
    my $file = "$dir/app.log";
    {
        package FileLog;
        use Punk;
        logging to => $file, level => 'info';
        get '/x' => sub { $_[0]->log->info('to a file'); $_[0]->text('ok') };
    }
    my $fapp = FileLog->to_app;
    ok(-e $file, 'a path is opened when the keyword runs');
    my ($st, $h, $body) = call($fapp, '/x');
    is($st, 200, 'a request that logs is served, where it used to be a 500');
    call($fapp, '/x');
    open my $fh, '<', $file or die $!;
    my @lines = <$fh>;
    close $fh;
    is(scalar @lines, 2, 'each line is in the file as soon as it is written');
    like($lines[0], qr/\[info\] GET \/x - to a file$/, '...in the usual format');

    open my $pre, '>', $file or die $!; print {$pre} "earlier\n"; close $pre;
    {
        package FileLog2;
        use Punk;
        logging to => $file;
        get '/x' => sub { $_[0]->log->info('appended'); $_[0]->text('ok') };
    }
    call(FileLog2->to_app, '/x');
    open $fh, '<', $file or die $!;
    @lines = <$fh>;
    close $fh;
    is($lines[0], "earlier\n", 'an existing file is appended to, not truncated');

    my $err = '';
    eval { Punk::App->new->logging(to => "$dir/no/such/dir/app.log"); 1 } or $err = $@;
    like($err, qr/logging cannot open '.*app\.log' for append/,
        'a path that cannot be opened is a boot error, by name');
}

done_testing;
