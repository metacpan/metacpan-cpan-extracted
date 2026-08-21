#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Punk ();
use File::Temp ();

# Punk::Plugin::CSP, phases 0 and 1: the nonce, and the policy on every
# response.
#
# `headers` can already set a static Content-Security-Policy. The policy that
# actually stops cross-site scripting is script-src 'nonce-...', and a nonce
# is per request by definition - which is why this cannot be a config line.

sub env_for {
    my ($path, %extra) = @_;
    return {
        REQUEST_METHOD => 'GET',
        PATH_INFO      => $path // '/',
        QUERY_STRING   => '',
        'psgi.input'   => undef,
        'psgi.errors'  => \*STDERR,
        %extra,
    };
}
sub policy_of {
    my ($res, $name) = @_;
    my %h = @{ $res->[1] };
    return $h{ $name || 'Content-Security-Policy' };
}
sub nonce_of {
    my ($policy) = @_;
    return unless defined $policy;
    return $policy =~ /'nonce-([A-Za-z0-9_-]+)'/ ? $1 : undef;
}

{
    package Basic;
    use Punk;
    plugin 'CSP';
    get  '/'     => sub { $_[0]->text('ok') };
    get  '/boom' => sub { die "kaboom\n" };
    post '/only' => sub { $_[0]->text('p') };

    package main;
    our $APP = Basic->to_app;
}

# ---- the nonce ---------------------------------------------------------------
{
    my $p = policy_of($main::APP->(env_for('/')));
    my $n = nonce_of($p);

    like($n, qr/\A[A-Za-z0-9_-]{22}\z/,
        '16 bytes of entropy as base64url without padding - 22 characters, '
      . 'and every one of them legal in the CSP base64-value grammar');

    my %seen;
    for (1 .. 500) {
        my $x = nonce_of(policy_of($main::APP->(env_for('/'))));
        $seen{$x}++ if defined $x;
    }
    is(scalar keys %seen, 500,
        '500 responses, 500 distinct nonces - a nonce that repeats is not a '
      . "nonce, it is an attacker's <script nonce=...> working on the next "
      . 'page');
}

# A nonce must be UNPREDICTABLE, not merely unique, which is the stricter
# requirement and the reason a counter was disqualified rather than merely
# rejected. This cannot prove unpredictability, but it can prove the obvious
# tells are absent.
{
    my @n = map { nonce_of(policy_of($main::APP->(env_for('/')))) } 1 .. 20;
    my %chars;
    $chars{$_}++ for map { split // } @n;
    cmp_ok(scalar keys %chars, '>', 30,
        'the nonces are not drawn from a handful of characters');

    my $sequential = 0;
    for my $i (1 .. $#n) { $sequential++ if $n[$i] gt $n[$i - 1] }
    cmp_ok($sequential, '<', 19,
        'and they do not ascend, which a counter or a timestamp prefix would');
}

# ---- every response shape ----------------------------------------------------
# The policy rides the same seam the `headers` keyword uses, which decorates
# from outside the routing branch. An error page is exactly where an injection
# lands - it is the response most likely to render something from the request -
# so a policy covering the 200s and missing the 404s misses the one that
# needed it.
{
    my @shapes = (
        [ 'a matched route',     '/'       ],
        [ 'a 404',               '/nowhere'],
        [ 'a handler that died', '/boom'   ],
    );
    for my $s (@shapes) {
        my ($what, $path) = @$s;
        my $res = $main::APP->(env_for($path));
        like(policy_of($res), qr/script-src[^;]*'nonce-/,
            "$what carries the policy (status $res->[0])");
    }

    my $res405 = $main::APP->(env_for('/only'));
    is($res405->[0], 405, 'and a 405 is a 405');
    like(policy_of($res405), qr/'nonce-/, 'which carries the policy too');
}

# ---- the defaults, and why they are the defaults -----------------------------
{
    my $p = policy_of($main::APP->(env_for('/')));

    like($p, qr/\bdefault-src 'self'/, "default-src 'self'");
    like($p, qr/\bobject-src 'none'/,
        "object-src 'none' closes the plugin-embedding bypasses a "
      . 'script-only policy leaves open');
    like($p, qr/\bbase-uri 'none'/,
        "base-uri 'none' is the one people leave out: an injected <base href> "
      . 'rewrites every relative script URL, so a nonce on a relative '
      . '<script src> would protect nothing');
}

# ---- configuration -----------------------------------------------------------
{
    package Configured;
    use Punk;
    plugin 'CSP' => {
        script_src => q{'self' https://cdn.example 'strict-dynamic'},
        style_src  => q{'self'},
        report_uri => '/csp-report',
    };
    get '/' => sub { $_[0]->text('ok') };

    package main;
    my $p = policy_of(Configured->to_app->(env_for('/')));

    like($p, qr{script-src 'self' https://cdn\.example 'strict-dynamic' 'nonce-},
        'a configured script-src keeps its sources AND gets the nonce, in ONE '
      . 'directive - a second script-src would simply be ignored by the '
      . 'browser');
    like($p, qr/style-src 'self'/,  'other directives are carried through');
    like($p, qr{report-uri /csp-report}, 'including report-uri');
}

# ---- report-only -------------------------------------------------------------
{
    package ReportOnly;
    use Punk;
    plugin 'CSP' => { report_only => 1 };
    get '/' => sub { $_[0]->text('ok') };

    package main;
    my $res = ReportOnly->to_app->(env_for('/'));
    like(policy_of($res, 'Content-Security-Policy-Report-Only'), qr/'nonce-/,
        'report_only sends the report-only header');
    is(policy_of($res), undef, 'and not the enforcing one');
}

# ---- a directive is on its way into a response header ------------------------
# The same class as the header-name check in Punk::Plugin::RequestId: a CR or
# LF in a configured value splits the response.
{
    for my $bad (["a newline", "'self'\r\nX-Injected: 1"],
                 ["a bare LF", "'self'\nX-Injected: 1"],
                 ["a semicolon that would forge a directive",
                  "'self'; object-src *"]) {
        my ($what, $value) = @$bad;
        my $err = do {
            local $@;
            eval "package Bad$$" . int(rand 1e6) . q{;
                use Punk;
                plugin 'CSP' => { script_src => $value };
                get '/' => sub { };
                1;
            };
            $@;
        };
        like($err, qr/cannot appear in one/,
            "$what in a directive croaks AT BOOT rather than shipping a "
          . 'policy that is not the one that was written');
    }
}

# ---- an application that set its own keeps it --------------------------------
{
    package OwnPolicy;
    use Punk;
    plugin 'CSP';
    get '/' => sub {
        my ($c) = @_;
        $c->res->header('Content-Security-Policy' => "default-src 'none'");
        $c->text('ok');
    };

    package main;
    is(policy_of(OwnPolicy->to_app->(env_for('/'))), "default-src 'none'",
        'set-if-absent comes free with the headers seam: a response that set '
      . 'its own policy keeps it');
}

# ---- PHASE 2: the thread to the template -------------------------------------
# The assertion this phase exists for. Not "the template renders a nonce" and
# not "the header carries one" - the two, against each other, on the SAME
# response.
#
# The failure modes are opposite and only one is visible. A nonce in the
# header that no template carries blocks every script on the page: obvious,
# and somebody fixes it within the hour. A nonce in the template that the
# header does not carry blocks nothing, looks perfectly fine, and leaves a
# policy that is decoration. That is the one worth a test.
{
    my $dir = File::Temp::tempdir(CLEANUP => 1);
    open my $t, '>', "$dir/page.tmpl" or die $!;
    print $t qq{<script nonce="{% csp_nonce %}">go()</script>\n};
    close $t;
    open my $p, '>', "$dir/plain.tmpl" or die $!;
    print $p "<p>nothing here</p>\n";
    close $p;

    package Templated;
    use Punk;
    plugin 'CSP';
    views Stencil => { template_dir => $dir };
    get '/'      => sub { $_[0]->render('page') };
    get '/plain' => sub { $_[0]->render('plain') };
    get '/say'   => sub { $_[0]->text($_[0]->csp_nonce) };

    package main;
    my $app = Templated->to_app;

    my $res  = $app->(env_for('/'));
    my $hdr  = nonce_of(policy_of($res));
    my ($body) = ($res->[2][0] // '') =~ /nonce="([A-Za-z0-9_-]+)"/;

    ok(defined $hdr,  'the response carries a nonce in its header');
    ok(defined $body, 'and the template rendered one');
    is($body, $hdr,
        'THE SAME STRING - the value in the <script> tag is the value in the '
      . 'header, on this response. A template nonce that does not match the '
      . 'header protects nothing and looks fine');

    my $res2   = $app->(env_for('/'));
    my $hdr2   = nonce_of(policy_of($res2));
    my ($body2) = ($res2->[2][0] // '') =~ /nonce="([A-Za-z0-9_-]+)"/;
    isnt($hdr2, $hdr, 'a second request gets a different nonce');
    is($body2, $hdr2, 'and its template matches its own header, not the first');

    like(policy_of($app->(env_for('/plain'))), qr/'nonce-/,
        'a template that never asks for the nonce still gets a header with '
      . 'one - the halves are independent in that direction');

    my $said = $app->(env_for('/say'));
    is($said->[2][0], nonce_of(policy_of($said)),
        '$c->csp_nonce is the same value again, for a handler building HTML '
      . 'or a payload by hand');
}

# ---- a long-lived vars hashref must not carry a stale nonce ------------------
# The nonce is SET on the render variables, not set-if-absent. A handler that
# renders with a hashref it keeps between requests would otherwise carry the
# first request's nonce for ever - which is the silent failure above, arrived
# at by a route nobody would suspect.
{
    my $dir = File::Temp::tempdir(CLEANUP => 1);
    open my $t, '>', "$dir/page.tmpl" or die $!;
    print $t qq{<script nonce="{% csp_nonce %}"></script>\n};
    close $t;

    package Reused;
    use Punk;
    plugin 'CSP';
    views Stencil => { template_dir => $dir };
    our %VARS = (title => 'kept between requests');
    get '/' => sub { $_[0]->render('page', \%VARS) };

    package main;
    my $app = Reused->to_app;
    my @seen;
    for (1 .. 3) {
        my $r = $app->(env_for('/'));
        my ($b) = ($r->[2][0] // '') =~ /nonce="([A-Za-z0-9_-]+)"/;
        push @seen, [ $b, nonce_of(policy_of($r)) ];
    }
    is(scalar(grep { defined $_->[0] && $_->[0] eq $_->[1] } @seen), 3,
        'every render matches its own header, even through a hashref the '
      . 'application reuses');
    my %distinct = map { ($_->[0] // '') => 1 } @seen;
    is(scalar keys %distinct, 3, 'and three requests produced three nonces');
}

# ---- any view engine, not just Stencil ---------------------------------------
# The nonce is bound into the variables hashref Punk hands to
# `$engine->render($template, $data)`, so it is not a Stencil feature: any
# engine that receives a vars hash sees `csp_nonce` under whatever syntax it
# uses. Asserted with an engine that is not Stencil, rather than reasoned
# about.
{
    package Toy::Engine;
    sub new { bless {}, shift }
    sub render {
        my ($self, $template, $vars) = @_;
        return "[$template:" . ($vars->{csp_nonce} // 'ABSENT') . ']';
    }

    package ToyApp;
    use Punk;
    plugin 'CSP';
    views '+Toy::Engine';
    get '/' => sub { $_[0]->render('whatever') };

    package main;
    my $res = ToyApp->to_app->(env_for('/'));
    my ($body) = ($res->[2][0] // '') =~ /\[whatever:([A-Za-z0-9_-]+)\]/;
    is($body, nonce_of(policy_of($res)),
        'a view engine that is not Stencil gets the same nonce - the binding '
      . "is at Punk's render call, not inside any one engine");
}

# ---- with no plugin, nothing is injected -------------------------------------
{
    my $dir = File::Temp::tempdir(CLEANUP => 1);
    open my $t, '>', "$dir/page.tmpl" or die $!;
    print $t qq{[{% csp_nonce %}]\n};
    close $t;

    package NoCSP;
    use Punk;
    views Stencil => { template_dir => $dir };
    get '/' => sub { $_[0]->render('page') };

    package main;
    my $res = NoCSP->to_app->(env_for('/'));
    is(policy_of($res), undef, 'no plugin, no policy');
    unlike($res->[2][0] // '', qr/[A-Za-z0-9_-]{22}/,
        'and no nonce is bound into the template variables - the injection '
      . 'is per app, so another app in this process having CSP does not '
      . 'give this one a nonce');
}

# ---- PHASE 3: report-only, and the endpoint ----------------------------------
# A strict CSP always breaks something on first contact. A framework that only
# offers enforcing mode gets switched on once, breaks a page, and is switched
# off for good.
{
    package Both;
    use Punk;
    plugin 'CSP' => {
        script_src  => q{'self' 'unsafe-inline'},          # what is trusted now
        report_only => { script_src => q{'self'} },        # what to move to
    };
    get '/' => sub { $_[0]->text('ok') };

    package main;
    my $res = Both->to_app->(env_for('/'));
    my $enf = policy_of($res);
    my $rep = policy_of($res, 'Content-Security-Policy-Report-Only');

    like($enf, qr/'unsafe-inline'/, 'the enforcing policy is the loose one');
    unlike($rep, qr/'unsafe-inline'/, 'and the reported one is the strict one');
    is(nonce_of($enf), nonce_of($rep),
        'both carry the SAME nonce - they describe one response, and two '
      . 'nonces would mean one of the policies was talking about a page that '
      . 'does not exist');
}

# ---- the endpoint ------------------------------------------------------------
{
    package Reporting;
    use Punk;
    plugin 'CSP' => { report_uri => '/csp-report' };
    logging to => sub { push @main::LOG, $_[0] };
    get '/' => sub { $_[0]->text('ok') };

    package main;
    our @LOG;
    my $app = Reporting->to_app;

    my $post = sub {
        my ($body, %extra) = @_;
        open my $fh, '<', \$body or die $!;
        return $app->({
            REQUEST_METHOD => 'POST', PATH_INFO => '/csp-report',
            QUERY_STRING   => '',
            CONTENT_TYPE   => 'application/csp-report',
            CONTENT_LENGTH => length $body,
            'psgi.input'   => $fh, 'psgi.errors' => \*STDERR,
            %extra,
        });
    };

    require JSON::PP;
    my $enc = JSON::PP->new->canonical;

    @LOG = ();
    my $ok = $post->($enc->encode({ 'csp-report' => {
        'document-uri'       => 'https://example/page',
        'blocked-uri'        => 'inline',
        'violated-directive' => 'script-src',
    }}));
    is($ok->[0], 204, 'a violation report is answered 204');
    is(scalar @LOG, 1, 'and logged once');
    like($LOG[0], qr/violated-directive=script-src/,
        'with the fields that say what broke');

    # Nothing reads the response, and an error status invites a retry from a
    # browser that cannot fix what it sent.
    @LOG = ();
    is($post->('not json at all')->[0], 204,
        'a malformed body is a 204, not a 400');

    is($post->($enc->encode({ 'csp-report' => { 'blocked-uri' => 'x' } }),
               CONTENT_TYPE => 'application/json')->[0], 204,
        'application/json is accepted too - older browsers send it and a '
      . 'collector that takes only one content type collects nothing');

    my %st = Punk::Plugin::CSP->stats;
    cmp_ok($st{reports}, '>', 0, 'reports are counted');
    cmp_ok($st{malformed}, '>', 0,
        'and so are the ones that made no sense, separately - a rising count '
      . 'is somebody probing rather than a browser reporting');
}

# ---- THE GATE: a report cannot forge a log line ------------------------------
# Every field of a violation report is REQUEST BYTES - document-uri,
# blocked-uri, script-sample and referrer all come from a client that can send
# anything, and they are on their way into a log line.
{
    package Inject;
    use Punk;
    plugin 'CSP' => { report_uri => '/r' };
    logging to => sub { push @main::ILOG, $_[0] };
    get '/' => sub { $_[0]->text('ok') };

    package main;
    our @ILOG;
    my $app = Inject->to_app;
    require JSON::PP;

    my $forged = "\r\n" . '[2026-01-01T00:00:00Z] [error] FORGED ENTRY';
    my $body = JSON::PP->new->canonical->encode({ 'csp-report' => {
        'document-uri'  => "https://x/$forged",
        'script-sample' => "a\nb\tc",
        'blocked-uri'   => 'has a space',
    }});

    @ILOG = ();
    open my $fh, '<', \$body or die $!;
    $app->({ REQUEST_METHOD => 'POST', PATH_INFO => '/r', QUERY_STRING => '',
             CONTENT_TYPE => 'application/csp-report',
             CONTENT_LENGTH => length $body,
             'psgi.input' => $fh, 'psgi.errors' => \*STDERR });

    is(scalar @ILOG, 1,
        'ONE log line - a forged entry would have made two');
    my $line = $ILOG[0];
    $line =~ s/\n\z//;
    unlike($line, qr/\n/,
        'and no embedded newline anywhere in it, which is what forging one '
      . 'takes');
    like($line, qr/FORGED ENTRY/,
        "the attacker's text IS there - as escaped data inside a quoted "
      . 'value, which is the right outcome: dropping it would lose the '
      . 'evidence, and passing it through would forge the line');
    like($line, qr/\\r\\n/,
        'the CRLF appears as the two-character escape rather than as bytes');
}

# ---- an absolute report_uri mounts nothing -----------------------------------
{
    package Elsewhere;
    use Punk;
    plugin 'CSP' => { report_uri => 'https://collector.example/csp' };
    get '/' => sub { $_[0]->text('ok') };

    package main;
    my $app = Elsewhere->to_app;
    like(policy_of($app->(env_for('/'))), qr{report-uri https://collector\.example/csp},
        'an absolute report-uri is still named in the policy');
    my $res = $app->(env_for('/csp'));
    is($res->[0], 404,
        'but no route is mounted for it - it is somebody else\'s collector, '
      . 'and mounting one would be answering for a host that is not us');
}

# ---- PHASE 4: the inline-handler check ---------------------------------------
# A script nonce does NOT cover inline event handlers. One onclick= in one
# template silently requires 'unsafe-inline', and adding that back defeats the
# policy for every page - including the ones with no inline handler at all.
#
# Nobody decides on that. They deploy a strict policy, get a console full of
# violations, add 'unsafe-inline' to stop them, and arrive one fix at a time
# at a policy that is a header and nothing more.
SKIP: {
    skip 'the check is development-only and PUNK_ENV is set otherwise', 8
        if ($ENV{PUNK_ENV} || '') ne '' && ($ENV{PUNK_ENV} ne 'development');

    my $dir = File::Temp::tempdir(CLEANUP => 1);
    my %tmpl = (
        bad    => qq{<div onclick="go()">x</div>\n},
        good   => qq{<p>nothing inline here</p>\n},
        exempt => qq{<div onclick="go()">csp-allow-inline</div>\n},
        onload => qq{<body onload="init()">y</body>\n},
    );
    for my $n (keys %tmpl) {
        open my $fh, '>', "$dir/$n.tmpl" or die $!;
        print $fh $tmpl{$n};
        close $fh;
    }

    local $ENV{PUNK_ENV} = 'development';

    package Scanned;
    use Punk;
    plugin 'CSP';
    logging to => sub { push @main::SLOG, $_[0] };
    views Stencil => { template_dir => $dir };
    get '/bad'    => sub { $_[0]->render('bad') };
    get '/good'   => sub { $_[0]->render('good') };
    get '/exempt' => sub { $_[0]->render('exempt') };
    get '/onload' => sub { $_[0]->render('onload') };

    package main;
    our @SLOG;
    my $app = Scanned->to_app;
    my $hit = sub { $app->(env_for($_[0])) };

    @SLOG = ();
    my $first = $hit->('/bad');
    $hit->('/bad') for 2 .. 20;
    is(scalar @SLOG, 1,
        'twenty renders of the same template warn ONCE - the same page '
      . 'warning every request is noise, and noise is ignored, which is '
      . 'exactly how the original problem happens');
    like($SLOG[0], qr/\bbad\b/,     'the warning names the template');
    like($SLOG[0], qr/onclick=/,     'and the attribute it found');

    @SLOG = ();
    $hit->('/good');
    is(scalar @SLOG, 0, 'a clean template says nothing');

    @SLOG = ();
    $hit->('/onload');
    is(scalar @SLOG, 1,
        'onload= is caught too - the check matches the SHAPE of an on*= '
      . 'attribute rather than a list of names, so it catches whatever was '
      . 'added to HTML last year');

    @SLOG = ();
    $hit->('/exempt');
    is(scalar @SLOG, 0,
        'a template carrying csp-allow-inline is exempt - a checker with no '
      . 'way out gets disabled wholesale instead of per template');

    # The warning has no authority over the response. A checker that breaks
    # the page is a checker that gets removed.
    #
    # Compared with the nonce masked, because that is the one thing which
    # differs between any two responses by design - everything else must be
    # identical between the render that warned and the nineteen that did not.
    my $again = $hit->('/bad');
    my $mask = sub {
        my ($r) = @_;
        my $copy = [ $r->[0], [ @{ $r->[1] } ], [ @{ $r->[2] } ] ];
        s/nonce-[A-Za-z0-9_-]+/nonce-X/g for @{ $copy->[1] }, @{ $copy->[2] };
        return $copy;
    };
    is_deeply($mask->($again), $mask->($first),
        'the response is what it would have been anyway - same status, same '
      . 'headers, same body - between the render that warned and one that '
      . 'did not');
}

# ---- and NOT in production ---------------------------------------------------
# Asserted by proving the body was never read, not by observing that no
# warning appeared - "no warning" is also what a broken checker produces.
{
    my $dir = File::Temp::tempdir(CLEANUP => 1);
    open my $fh, '>', "$dir/bad.tmpl" or die $!;
    print $fh qq{<div onclick="go()">x</div>\n};
    close $fh;

    local $ENV{PUNK_ENV} = 'production';

    package Prod;
    use Punk;
    plugin 'CSP';
    logging to => sub { push @main::PLOG, $_[0] };
    views Stencil => { template_dir => $dir };
    get '/' => sub { $_[0]->render('bad') };

    package main;
    our @PLOG;
    my $app = Prod->to_app;

    my %before = Punk::Plugin::CSP->stats;
    @PLOG = ();
    $app->(env_for('/')) for 1 .. 10;
    my %after = Punk::Plugin::CSP->stats;

    is($after{scanned}, $before{scanned},
        'ten responses in production and the scan counter did not move - the '
      . 'body was never read, which is the claim, rather than merely that no '
      . 'warning came out');
    is(scalar @PLOG, 0, 'and nothing was warned');
}

# ---- across a forked pool ----------------------------------------------------
# The phase-0 gate. An entropy buffer filled once and inherited through fork
# hands every worker the same bytes - measured at 767 duplicates in 8000
# across four workers while building Punk::Plugin::RequestId, looking
# perfectly random throughout. For a request id that is a nuisance; for a
# nonce it means one user can predict another's, which is the whole attack.
SKIP: {
    skip 'fork is POSIX-only here', 2 if $^O eq 'MSWin32';

    my $workers = 4;
    my $per     = 250;
    pipe my $rd, my $wr or die "pipe: $!";

    # Draw in the PARENT first, so the buffer is warm and inherited - which is
    # exactly the condition an unguarded buffer fails under. A test that
    # forked before touching the generator would pass against the bug.
    $main::APP->(env_for('/'));

    my @pids;
    for (1 .. $workers) {
        my $pid = fork // die "fork: $!";
        if (!$pid) {
            close $rd;
            my $out = '';
            for (1 .. $per) {
                my $n = nonce_of(policy_of($main::APP->(env_for('/'))));
                $out .= ($n // '') . "\n";
            }
            syswrite $wr, $out;
            close $wr;
            exit 0;
        }
        push @pids, $pid;
    }
    close $wr;

    my (%seen, $lines);
    while (my $l = <$rd>) { chomp $l; next unless length $l; $seen{$l}++; $lines++ }
    close $rd;
    waitpid $_, 0 for @pids;

    is($lines, $workers * $per, "all $workers workers reported");
    is(scalar keys %seen, $lines,
        'EVERY nonce is unique across the pool - the entropy buffer is filled '
      . 'per process, not inherited from the parent that warmed it')
        or diag sprintf 'got %d distinct from %d', scalar keys %seen, $lines;
}

# ---- the SYNOPSIS, executed --------------------------------------------------
# Read out of the POD rather than copied, for the reason `t/0001-synopsis.t`
# exists: Punk.pm's SYNOPSIS opened with a line that croaked for the whole
# life of the distribution, and nothing noticed because nothing ran it. A copy
# in a test file drifts the same way; reading the POD cannot.
#
# And it is the right thing to assert for THIS plugin specifically, because
# its SYNOPSIS is a documented PAIRING - a header and a template - and a
# documented pairing that stops matching is the silent failure the whole plan
# is about.
{
    # NOT %INC. The `plugin` keyword only requires the .pm when the class
    # has no `register` method, and this plugin's register is XS - so the
    # module is never loaded and %INC never hears about it. The same
    # short-circuit that kept Punk::Cache's backends from loading their own
    # .pm. Here it means the file has to be found the way perl would.
    my ($pm) = grep { -r } map { "$_/Punk/Plugin/CSP.pm" } @INC;
    SKIP: {
        skip 'cannot locate Punk/Plugin/CSP.pm in @INC', 4 unless $pm;

        my $pod = do { open my $fh, '<', $pm or die $!; local $/; <$fh> };
        my ($synopsis) = $pod =~ /^=head1 SYNOPSIS\s*\n(.*?)^=head1 /ms;
        ok($synopsis, 'the SYNOPSIS is where it says it is');

        my @code = map  { my $l = $_; $l =~ s/\A    //; $l }
                   grep { /\A(?:    |\s*\z)/ }
                   split /\n/, $synopsis;
        my $code = join "\n", @code;

        # the app half, up to the template line
        my ($app_code) = $code =~ /\A(.*?)\n\s*<script/s;
        my ($tmpl)     = $code =~ /(<script[^\n]*>)/;

        like($app_code, qr/plugin 'CSP'/, 'it registers the plugin');
        like($tmpl, qr/\{%\s*csp_nonce\s*%\}/,
            'and its template asks for the nonce');

        my $dir = File::Temp::tempdir(CLEANUP => 1);
        open my $t, '>', "$dir/page.tmpl" or die $!;
        print $t "$tmpl\n";
        close $t;

        # The SYNOPSIS does not show a `views` line - an application already
        # has one - so it is appended INSIDE the same package, where `views`
        # is a keyword, and everything the SYNOPSIS does runs verbatim above
        # it.
        my $ok = eval qq{$app_code\nviews Stencil => { template_dir => '$dir' };\n1};
        my $err = $@;

        SKIP: {
            skip "the SYNOPSIS did not compile: $err", 1 unless $ok;
            my $res = MyApp->to_app->(env_for('/'));
            my ($body) = ($res->[2][0] // '') =~ /nonce="([A-Za-z0-9_-]+)"/;
            is($body, nonce_of(policy_of($res)),
                'THE GATE: the nonce the SYNOPSIS shows in the template is '
              . 'the nonce it shows in the header, executed rather than '
              . 'promised');
        }
    }
}

done_testing;
