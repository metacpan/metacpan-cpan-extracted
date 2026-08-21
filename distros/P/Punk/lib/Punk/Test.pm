package Punk::Test;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.27';

use Test::Builder ();
use Scalar::Util ();
use Socket qw(AF_UNIX SOCK_STREAM PF_UNSPEC);
use POSIX ();
use File::Raw::JSON qw(file_json_encode file_json_decode);
use Punk::Test::WS ();
use Punk::Test::WS::Conn ();

# An in-process test client for a compiled Punk application: one object is
# one browser - it keeps a cookie jar, so sessions, CSRF and flash flows
# test the way they run. Every assertion returns $self for chaining and
# reports through the one Test::Builder singleton, so it works under
# Test::More and Test2 alike.

my $TB = Test::Builder->new;
my %APPS;

sub new {
    my ($class, $app, %opts) = @_;
    my $app_class = ref $app ? undef : $app;
    if (ref $app ne 'CODE') {
        my $name = $app;
        unless ($name->can('to_app')) {
            eval "require $name"
                or die "Punk::Test: could not load $name: $@";
        }
        $name->can('to_app')
            or die "Punk::Test: $name has no to_app - not a Punk app?\n";
        # to_app compiles once per class, and two clients against one app
        # (two browsers, one server) is a thing tests want - so the frozen
        # coderef is shared
        $app = $APPS{$name} //= $name->to_app;
    }
    return bless {
        app         => $app,
        class       => $app_class,
        jar         => {},
        timeout     => $opts{timeout}     // 5,
        max_bytes   => $opts{max_bytes}   // 1_000_000,
        csrf_cookie => $opts{csrf_cookie} // 'csrf',
        csrf_header => $opts{csrf_header} // 'X-CSRF-Token',
        res         => undef,
    }, $class;
}

# ---- requests ----------------------------------------------------------------

sub get_ok     { my $self = shift; $self->_request_ok('GET',     @_) }
sub post_ok    { my $self = shift; $self->_request_ok('POST',    @_) }
sub put_ok     { my $self = shift; $self->_request_ok('PUT',     @_) }
sub patch_ok   { my $self = shift; $self->_request_ok('PATCH',   @_) }
sub delete_ok  { my $self = shift; $self->_request_ok('DELETE',  @_) }
sub head_ok    { my $self = shift; $self->_request_ok('HEAD',    @_) }
sub options_ok { my $self = shift; $self->_request_ok('OPTIONS', @_) }

# Sign a user straight into the jar - the signed session cookie is minted
# through the app's own session config, so tests reach guarded pages without
# driving a login flow first. Takes an id or a user row; needs a client
# built from a class name (the app object holds the session secret).
sub login_as {
    my ($self, $user) = @_;
    my $class = $self->{class}
        or die "Punk::Test: login_as needs a client built from a class "
             . "name, not a coderef\n";
    my $app  = $class->punk_app;
    my $auth = $app->{auth} || {};
    my $key  = $auth->{session_key} // 'user_id';
    my $idf  = ($auth->{fields} || {})->{id} // 'id';
    my $id   = ref $user eq 'HASH' ? $user->{$idf} : $user;
    defined $id or die "Punk::Test: login_as needs a user row or id\n";
    # _seal_session, not _seal: an application with `session store => ...`
    # keeps the payload server-side, so a cookie with the session sealed into
    # it is no session at all there. This writes it wherever the application
    # will look.
    my ($name, $value) = Punk::Session::_seal_session($app, { $key => $id });
    $self->{jar}{$name} = $value;
    return $self;
}

sub _urlenc {
    my ($s) = @_;
    $s = '' unless defined $s;
    utf8::encode($s) if utf8::is_utf8($s);
    $s =~ s/([^A-Za-z0-9_.~-])/sprintf '%%%02X', ord $1/ge;
    return $s;
}

sub _build_env {
    my ($self, $method, $path, %o) = @_;
    my $query = $o{query} // '';
    ($path, $query) = ($1, $2) if !length $query && $path =~ /\A([^?]*)\?(.*)\z/s;

    my ($body, $type) = ('', $o{type});
    if (exists $o{json}) {
        $body = file_json_encode($o{json});
        $type //= 'application/json';
    }
    elsif (exists $o{form}) {
        my $f = $o{form};
        $body = join '&', map { _urlenc($_) . '=' . _urlenc($f->{$_}) }
                          sort keys %$f;
        $type //= 'application/x-www-form-urlencoded';
    }
    elsif (defined $o{body}) {
        $body = $o{body};
    }

    open my $in, '<', \$body or die "Punk::Test: $!";
    my $env = {
        REQUEST_METHOD    => $method,
        PATH_INFO         => $path,
        QUERY_STRING      => $query,
        SERVER_NAME       => 'localhost',
        SERVER_PORT       => 80,
        HTTP_HOST         => 'localhost',
        'psgi.url_scheme' => 'http',
        'psgi.input'      => $in,
        'psgi.errors'     => \*STDERR,
        'psgi.version'    => [ 1, 1 ],
    };
    if (length $body or defined $type) {
        $env->{CONTENT_LENGTH} = length $body;
        $env->{CONTENT_TYPE}   = $type // '';
    }
    if (my $h = $o{headers}) {
        for my $k (keys %$h) {
            my $ek = uc $k;
            $ek =~ tr/-/_/;
            $ek = "HTTP_$ek"
                unless $ek eq 'CONTENT_TYPE' || $ek eq 'CONTENT_LENGTH';
            $env->{$ek} = $h->{$k};
        }
    }
    if ($o{csrf}) {
        my $tok = $self->csrf_token;
        if (defined $tok) {
            my $ek = uc $self->{csrf_header};
            $ek =~ tr/-/_/;
            $env->{"HTTP_$ek"} = $tok;
        }
        else {
            $TB->diag("csrf => 1, but the jar holds no "
                    . "'$self->{csrf_cookie}' cookie yet - GET a page first");
        }
    }
    if (my $jar = $self->_jar_header) { $env->{HTTP_COOKIE} = $jar }
    %$env = (%$env, %{ $o{env} }) if $o{env};
    return $env;
}

sub _request_ok {
    my ($self, $method, $path, %o) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 2;
    my $env = $self->_build_env($method, $path, %o);
    my $r = eval { $self->{app}->($env) };
    my $err = $@;
    if (ref $r eq 'CODE') {                 # a psgi.streaming response
        $r = eval { $self->_drive_streaming($r) };
        $err ||= $@;
    }
    if (ref $r eq 'ARRAY') {
        $self->_set_response($r);
        $TB->ok(1, $o{name} // "$method $path");
    }
    else {
        $self->{res} = undef;
        $TB->ok(0, $o{name} // "$method $path");
        $TB->diag($err ? "the application died: $err"
                       : 'the application did not return a PSGI response');
    }
    return $self;
}

# Drive a delayed-response coderef to completion, collecting the writes.
sub _drive_streaming {
    my ($self, $code) = @_;
    my ($status, $headers, @writes, $closed);
    my $max = $self->{max_bytes};
    my $got = 0;
    my $writer = Punk::Test::_Writer->new(sub {
        $got += length $_[0];
        die "Punk::Test: stream exceeded $max bytes without closing\n"
            if $got > $max;
        push @writes, $_[0];
    }, \$closed);
    my $ret = $code->(sub {
        my ($triplet) = @_;
        ($status, $headers) = @$triplet[0, 1];
        return $writer if @$triplet < 3;
        push @writes, @{ $triplet->[2] };
        $closed = 1;
        return;
    });
    return [ $status, $headers // [], [ join '', @writes ] ];
}

sub _set_response {
    my ($self, $r) = @_;
    my $body = $r->[2];
    if (ref $body eq 'ARRAY') {
        $body = join '', grep { defined } @$body;
    }
    elsif (Scalar::Util::blessed($body) && $body->can('getline')) {
        my @chunks;                         # a PSGI body object (send_file)
        while (defined(my $chunk = $body->getline)) { push @chunks, $chunk }
        eval { $body->close };
        $body = join '', @chunks;
    }
    else {                                  # a filehandle (Punk::Static)
        local $/;
        my $fh = $body;
        $body = <$fh> // '';
        eval { $fh->close };
    }
    $self->{res} = { status => $r->[0], headers => $r->[1], body => $body };
    delete $self->{json};
    my @h = @{ $r->[1] };
    while (my ($k, $v) = splice @h, 0, 2) {
        next unless lc $k eq 'set-cookie';
        my ($name, $value) = $v =~ /\A\s*([^=;\s]+)=([^;]*)/ or next;
        if ($value eq '' || $v =~ /;\s*Max-Age\s*=\s*0\s*(?:;|\z)/i) {
            delete $self->{jar}{$name};
        }
        else {
            $self->{jar}{$name} = $value;
        }
    }
    return;
}

sub _jar_header {
    my ($self) = @_;
    my $jar = $self->{jar};
    return unless %$jar;
    return join '; ', map { "$_=$jar->{$_}" } sort keys %$jar;
}

# ---- the response ------------------------------------------------------------

sub status { $_[0]{res} ? $_[0]{res}{status} : undef }
sub body   { $_[0]{res} ? $_[0]{res}{body}   : undef }

sub header {
    my ($self, $name) = @_;
    return unless $self->{res};
    my @h = @{ $self->{res}{headers} };
    while (my ($k, $v) = splice @h, 0, 2) {
        return $v if lc $k eq lc $name;
    }
    return undef;
}

sub json {
    my ($self) = @_;
    return unless $self->{res};
    return $self->{json} //= eval { file_json_decode($self->{res}{body}) };
}

sub cookie { $_[0]{jar}{ $_[1] } }

sub csrf_token { $_[0]{jar}{ $_[0]{csrf_cookie} } }

sub reset_session { %{ $_[0]{jar} } = (); $_[0] }

# ---- assertions --------------------------------------------------------------

sub _no_response {
    my ($self, $name) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $TB->ok(0, $name);
    $TB->diag('no response - did the last *_ok request fail?');
    return $self;
}

sub status_is {
    my ($self, $want, $name) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $name //= "status is $want";
    return $self->_no_response($name) unless $self->{res};
    $TB->is_num($self->{res}{status}, $want, $name)
        or $TB->diag('body: ' . $self->_body_head);
    return $self;
}

sub status_isnt {
    my ($self, $want, $name) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $name //= "status is not $want";
    return $self->_no_response($name) unless $self->{res};
    $TB->isnt_num($self->{res}{status}, $want, $name);
    return $self;
}

sub header_is {
    my ($self, $h, $want, $name) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $name //= "$h header is " . (defined $want ? "'$want'" : 'undef');
    return $self->_no_response($name) unless $self->{res};
    $TB->is_eq($self->header($h), $want, $name);
    return $self;
}

sub header_like {
    my ($self, $h, $re, $name) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $name //= "$h header matches";
    return $self->_no_response($name) unless $self->{res};
    $TB->like($self->header($h) // '', $re, $name);
    return $self;
}

sub header_exists {
    my ($self, $h, $name) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $name //= "$h header exists";
    return $self->_no_response($name) unless $self->{res};
    $TB->ok(defined $self->header($h), $name);
    return $self;
}

sub content_is {
    my ($self, $want, $name) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $name //= 'exact body';
    return $self->_no_response($name) unless $self->{res};
    $TB->is_eq($self->{res}{body}, $want, $name);
    return $self;
}

sub content_like {
    my ($self, $re, $name) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $name //= 'body matches';
    return $self->_no_response($name) unless $self->{res};
    $TB->like($self->{res}{body}, $re, $name);
    return $self;
}

sub content_unlike {
    my ($self, $re, $name) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $name //= 'body does not match';
    return $self->_no_response($name) unless $self->{res};
    $TB->unlike($self->{res}{body}, $re, $name);
    return $self;
}

# RFC 6901: '' is the whole document, '/a/0/b' walks in. Returns
# (found, value).
sub _ptr_get {
    my ($doc, $ptr) = @_;
    return (1, $doc) if !defined $ptr || $ptr eq '';
    return (0, undef) unless $ptr =~ s{\A/}{};
    for my $tok (split m{/}, $ptr, -1) {
        $tok =~ s/~1/\//g;
        $tok =~ s/~0/~/g;
        if (ref $doc eq 'HASH') {
            return (0, undef) unless exists $doc->{$tok};
            $doc = $doc->{$tok};
        }
        elsif (ref $doc eq 'ARRAY') {
            return (0, undef) unless $tok =~ /\A\d+\z/ && $tok <= $#$doc;
            $doc = $doc->[$tok];
        }
        else { return (0, undef) }
    }
    return (1, $doc);
}

sub _json_at {
    my ($self, $ptr, $name) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $doc = $self->json;
    unless (defined $doc) {
        $TB->ok(0, $name);
        $TB->diag('the body did not decode as JSON: ' . $self->_body_head);
        return;
    }
    my ($found, $got) = _ptr_get($doc, $ptr);
    unless ($found) {
        $TB->ok(0, $name);
        $TB->diag("nothing at JSON pointer '$ptr' in " . $self->_body_head);
        return;
    }
    return \$got;
}

sub json_is {
    my ($self, $ptr, $want, $name) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $name //= "json at '$ptr'";
    return $self->_no_response($name) unless $self->{res};
    my $slot = $self->_json_at($ptr, $name) or return $self;
    my $got = $$slot;
    if (ref $got || ref $want) {
        # deep-compare through canonical JSON, wrapped so scalars encode
        $TB->is_eq(file_json_encode([$got],  sort_keys => 1),
                   file_json_encode([$want], sort_keys => 1), $name);
    }
    else {
        $TB->is_eq($got, $want, $name);
    }
    return $self;
}

sub json_has {
    my ($self, $ptr, $name) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $name //= "json has '$ptr'";
    return $self->_no_response($name) unless $self->{res};
    my $slot = $self->_json_at($ptr, $name) or return $self;
    $TB->ok(1, $name);
    return $self;
}

sub json_like {
    my ($self, $ptr, $re, $name) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $name //= "json at '$ptr' matches";
    return $self->_no_response($name) unless $self->{res};
    my $slot = $self->_json_at($ptr, $name) or return $self;
    $TB->like(defined $$slot && !ref $$slot ? $$slot : '', $re, $name);
    return $self;
}

sub _body_head {
    my ($self) = @_;
    my $b = $self->{res} ? $self->{res}{body} : '';
    $b = substr($b, 0, 500) . '...' if length $b > 500;
    return length $b ? $b : '(empty body)';
}

# ---- server-sent events ------------------------------------------------------

sub sse_ok {
    my ($self, $path, %o) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $name = $o{name} // "SSE $path";
    $o{headers}{Accept} //= 'text/event-stream';
    my $env = $self->_build_env(GET => $path, %o);
    $env->{'psgi.streaming'} = 1;
    delete $self->{sse};
    my $r = eval { $self->{app}->($env) };
    my $err = $@;
    if (ref $r eq 'CODE') {
        $r = eval { $self->_drive_streaming($r) };
        $err ||= $@;
    }
    unless (ref $r eq 'ARRAY') {
        $self->{res} = undef;
        $TB->ok(0, $name);
        $TB->diag($err ? "the application died: $err"
                       : 'no response from the sse route');
        return $self;
    }
    $self->_set_response($r);
    my $ct = $self->header('Content-Type') // '';
    if ($r->[0] == 200 && $ct =~ m{\Atext/event-stream}) {
        $self->{sse} = _parse_sse($self->{res}{body});
        $TB->ok(1, $name);
    }
    else {
        $TB->ok(0, $name);
        $TB->diag("expected a 200 text/event-stream, got $r->[0] "
                . ($ct || '(no content type)') . ': ' . $self->_body_head);
    }
    return $self;
}

# The spec's dispatch loop: fields accumulate, a blank line dispatches.
sub _parse_sse {
    my ($bytes) = @_;
    my (@events, @comments, %cur);
    for my $line (split /\n/, $bytes, -1) {
        $line =~ s/\r\z//;
        if ($line eq '') {
            push @events, {%cur} if %cur;
            %cur = ();
            next;
        }
        if ($line =~ /\A:\s?(.*)\z/s) { push @comments, $1; next }
        my ($field, $value) = $line =~ /\A([^:]+)(?::\s?(.*))?\z/s;
        $value //= '';
        if    ($field eq 'data')  { $cur{data} = defined $cur{data}
                                              ? "$cur{data}\n$value" : $value }
        elsif ($field eq 'event') { $cur{event} = $value }
        elsif ($field eq 'id')    { $cur{id}    = $value }
        elsif ($field eq 'retry') { $cur{retry} = $value }
    }
    return { events => \@events, comments => \@comments };
}

sub sse_events   { $_[0]{sse} ? $_[0]{sse}{events}   : undef }
sub sse_comments { $_[0]{sse} ? $_[0]{sse}{comments} : undef }

sub _sse_event {
    my ($self, $i, $name) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    unless ($self->{sse}) {
        $TB->ok(0, $name);
        $TB->diag('no SSE stream - did sse_ok pass?');
        return;
    }
    my $ev = $self->{sse}{events}[$i];
    unless ($ev) {
        $TB->ok(0, $name);
        $TB->diag("no event $i - the stream held "
                . scalar(@{ $self->{sse}{events} }) . ' event(s)');
        return;
    }
    return $ev;
}

sub sse_event_is {
    my ($self, $i, $event, $data, $name) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $name //= "event $i is $event";
    my $ev = $self->_sse_event($i, $name) or return $self;
    if (($ev->{event} // '') eq $event) {
        $TB->is_eq($ev->{data} // '', $data, $name);
    }
    else {
        $TB->ok(0, $name);
        $TB->diag("event $i is named '" . ($ev->{event} // '')
                . "', not '$event'");
    }
    return $self;
}

sub sse_data_is {
    my ($self, $i, $data, $name) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $name //= "event $i data";
    my $ev = $self->_sse_event($i, $name) or return $self;
    $TB->is_eq($ev->{data} // '', $data, $name);
    return $self;
}

sub sse_json_is {
    my ($self, $i, $ptr, $want, $name) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $name //= "event $i json at '$ptr'";
    my $ev = $self->_sse_event($i, $name) or return $self;
    my $doc = eval { file_json_decode($ev->{data} // '') };
    unless (defined $doc) {
        $TB->ok(0, $name);
        $TB->diag("event $i data is not JSON: " . ($ev->{data} // ''));
        return $self;
    }
    my ($found, $got) = _ptr_get($doc, $ptr);
    unless ($found) {
        $TB->ok(0, $name);
        $TB->diag("nothing at JSON pointer '$ptr' in event $i");
        return $self;
    }
    if (ref $got || ref $want) {
        $TB->is_eq(file_json_encode([$got],  sort_keys => 1),
                   file_json_encode([$want], sort_keys => 1), $name);
    }
    else {
        $TB->is_eq($got, $want, $name);
    }
    return $self;
}

# ---- websockets --------------------------------------------------------------

# Whether the live (forked Hyperman) transport can run here at all - tests
# use this to SKIP, the same way t/1011-ws-live.t does.
sub ws_live_available {
    return eval {
        require Hyperman;
        require Punk::WebSocket;
        Punk::WebSocket::_hm_available();
    } ? 1 : 0;
}

sub websocket_ok {
    my ($self, $path, %o) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $name = $o{name} // "websocket $path";
    $self->_ws_teardown;

    if (!$o{live}) {
        my ($conn, $hdr, $key, $status) = $self->_ws_inprocess($path, %o);
        if ($status == 101) {
            my ($acc) = $hdr =~ /Sec-WebSocket-Accept: (\S+)/i;
            $self->{ws}     = $conn;
            $self->{ws_hdr} = $hdr;
            $TB->is_eq($acc // '', Punk::Test::WS::accept_key($key), $name);
            return $self;
        }
        $conn->close if $conn;
        if ($status != 501) {   # 501 = this transport cannot upgrade; go live
            $TB->ok(0, $name);
            $TB->diag($status
                ? "the upgrade was answered with a $status:\n$hdr"
                : 'no bytes came back from the upgrade request');
            return $self;
        }
    }

    unless (ws_live_available()) {
        $TB->ok(0, $name);
        $TB->diag('this route needs the live transport (Hyperman 0.11+); '
                . 'guard the test with Punk::Test::ws_live_available');
        return $self;
    }
    my ($conn, $hdr, $key) = $self->_ws_live($path, %o);
    unless ($conn) {
        $TB->ok(0, $name);
        $TB->diag($hdr // 'could not connect to the live worker');
        return $self;
    }
    if ($hdr =~ m{\AHTTP/1\.1 101 }) {
        my ($acc) = $hdr =~ /Sec-WebSocket-Accept: (\S+)/i;
        $self->{ws}     = $conn;
        $self->{ws_hdr} = $hdr;
        $TB->is_eq($acc // '', Punk::Test::WS::accept_key($key), $name);
    }
    else {
        $conn->close;
        $TB->ok(0, $name);
        my ($line) = split /\r\n/, $hdr;
        $TB->diag('the upgrade was answered with: ' . ($line // '(nothing)'));
    }
    return $self;
}

# In-process transport: the app runs in a fork with one end of a socketpair
# as psgix.io - so a blocking => 1 route streams to us in real time while
# this side sends and asserts interactively. The child answers non-upgrade
# triplets (a guard's 403, the 501 of a route this transport cannot carry)
# as minimal HTTP so the parent can see why.
sub _ws_inprocess {
    my ($self, $path, %o) = @_;
    my ($env, $key) = Punk::Test::WS::upgrade_env(
        path => $path, query => $o{query}, protocol => $o{protocol});
    if (my $h = $o{headers}) {
        for my $k (keys %$h) {
            my $ek = uc $k; $ek =~ tr/-/_/;
            $env->{"HTTP_$ek"} = $h->{$k};
        }
    }
    if (my $jar = $self->_jar_header) { $env->{HTTP_COOKIE} = $jar }

    socketpair(my $ours, my $theirs, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
        or die "Punk::Test: socketpair: $!";
    my $pid = fork // die "Punk::Test: fork: $!";
    if (!$pid) {
        # the child owns no test state: keep it off the TAP pipe entirely,
        # and leave through _exit so no END blocks or destructors run
        close $ours;
        open STDIN,  '<', '/dev/null';
        open STDOUT, '>', '/dev/null';
        open STDERR, '>', '/dev/null';
        $env->{'psgix.io'} = $theirs;
        my $r = eval { $self->{app}->($env) };
        if (ref $r eq 'ARRAY') {
            # a successful blocking upgrade already spoke on the socket and
            # returns the empty 200 sentinel; anything else (a guard's 403,
            # the 501 of a route this transport cannot carry, a plain route
            # answering) is relayed as minimal HTTP so the parent sees why
            my $body = ref $r->[2] eq 'ARRAY'
                ? join('', grep { defined } @{ $r->[2] }) : '';
            syswrite $theirs, "HTTP/1.1 $r->[0] X\r\n"
                            . "Content-Length: " . length($body) . "\r\n"
                            . "\r\n$body"
                unless $r->[0] == 200 && !length $body;
        }
        elsif (!defined $r) {
            syswrite $theirs, "HTTP/1.1 500 X\r\n\r\n";
        }
        POSIX::_exit(0);
    }
    close $theirs;
    my $conn = Punk::Test::WS::Conn->new(
        sock => $ours, timeout => $self->{timeout}, pid => $pid);
    my $hdr = $conn->read_headers;
    my ($status) = $hdr =~ m{\AHTTP/1\.1 (\d+)};
    return ($conn, $hdr, $key, $status // 0);
}

# Live transport: one forked Hyperman worker per client, started on first
# use, speaking real TCP - fully interactive, and the same machinery as
# t/1011-ws-live.t.
sub _ws_live {
    my ($self, $path, %o) = @_;
    my $host = $self->_live_host or return (undef, 'live worker failed to start');
    require IO::Socket::INET;
    my $sock = IO::Socket::INET->new(PeerAddr => $host)
        or return (undef, "connect $host: $!");
    $sock->autoflush(1);
    my @extra = map { my $k = $_; "$k: $o{headers}{$k}" }
                keys %{ $o{headers} || {} };
    if (my $jar = $self->_jar_header) { push @extra, "Cookie: $jar" }
    my ($req, $key) = Punk::Test::WS::handshake_request(
        host => $host, path => $path, protocol => $o{protocol},
        extra => \@extra);
    syswrite $sock, $req;
    my $conn = Punk::Test::WS::Conn->new(
        sock => $sock, timeout => $self->{timeout});
    my $hdr = $conn->read_headers;
    return ($conn, $hdr, $key);
}

sub _live_host {
    my ($self) = @_;
    return $self->{live}{host} if $self->{live};
    require IO::Socket::INET;
    my $port = 27000 + ($$ % 400);
    my $pid  = fork // die "Punk::Test: fork: $!";
    if (!$pid) {
        open STDIN,  '<', '/dev/null';
        open STDOUT, '>', '/dev/null';
        open STDERR, '>', '/dev/null';
        eval {
            Hyperman->run(app => $self->{app}, host => '127.0.0.1',
                          port => $port, workers => 1);
        };
        POSIX::_exit(0);
    }
    my $host = "127.0.0.1:$port";
    for (1 .. 100) {
        my $s = IO::Socket::INET->new(PeerAddr => $host);
        if ($s) { close $s; $self->{live} = { pid => $pid, host => $host };
                  return $host }
        select undef, undef, undef, 0.1;
    }
    kill 'KILL', $pid;
    waitpid $pid, 0;
    return;
}

sub send_ok {
    my ($self, $payload, %o) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $name = $o{name} // 'send';
    unless ($self->{ws}) {
        $TB->ok(0, $name);
        $TB->diag('no websocket - did websocket_ok pass?');
        return $self;
    }
    my $n = $self->{ws}->send_frame(
        opcode  => $o{binary} ? 2 : ($o{opcode} // 1),
        payload => $payload);
    $TB->ok(defined $n, $name);
    return $self;
}

# The next data frame's payload, reassembling fragments, skipping pongs.
sub _next_message {
    my ($self) = @_;
    my $payload = '';
    while (1) {
        my $f = $self->{ws}->read_frame or return undef;
        next if $f->{opcode} == 10;              # a pong
        return { close => 1, frame => $f } if $f->{opcode} == 8;
        $payload .= $f->{payload};
        return { payload => $payload, frame => $f } if $f->{fin};
    }
}

sub message_is {
    my ($self, $want, $name) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $name //= 'message';
    unless ($self->{ws}) {
        $TB->ok(0, $name);
        $TB->diag('no websocket - did websocket_ok pass?');
        return $self;
    }
    my $m = $self->_next_message;
    if (!$m)             { $TB->ok(0, $name); $TB->diag('no frame arrived (timeout or EOF)') }
    elsif ($m->{close})  { $TB->ok(0, $name); $TB->diag('the server closed instead') }
    else                 { $TB->is_eq($m->{payload}, $want, $name) }
    return $self;
}

sub message_like {
    my ($self, $re, $name) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $name //= 'message matches';
    unless ($self->{ws}) {
        $TB->ok(0, $name);
        $TB->diag('no websocket - did websocket_ok pass?');
        return $self;
    }
    my $m = $self->_next_message;
    if (!$m)             { $TB->ok(0, $name); $TB->diag('no frame arrived (timeout or EOF)') }
    elsif ($m->{close})  { $TB->ok(0, $name); $TB->diag('the server closed instead') }
    else                 { $TB->like($m->{payload}, $re, $name) }
    return $self;
}

sub finish_ok {
    my ($self, $name) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $name //= 'clean close';
    unless ($self->{ws}) {
        $TB->ok(0, $name);
        $TB->diag('no websocket - did websocket_ok pass?');
        return $self;
    }
    $self->{ws}->send_frame(opcode => 8, payload => pack('n', 1000));
    my $echoed = 0;
    while (my $f = $self->{ws}->read_frame) {
        if ($f->{opcode} == 8) { $echoed = 1; last }
    }
    $TB->ok($echoed, $name);
    $TB->diag('the close was never echoed') unless $echoed;
    $self->_ws_teardown;
    return $self;
}

sub _ws_teardown {
    my ($self) = @_;
    if (my $ws = delete $self->{ws}) { $ws->close }
    delete $self->{ws_hdr};
    return;
}

sub DESTROY {
    my ($self) = @_;
    $self->_ws_teardown;
    if (my $live = delete $self->{live}) {
        kill 'TERM', $live->{pid};
        waitpid $live->{pid}, 0;
    }
    return;
}

# The psgi.streaming writer handed to a delayed response.
package 
    Punk::Test::_Writer;
sub new   { bless { w => $_[1], c => $_[2] }, $_[0] }
sub write { $_[0]{w}->($_[1]) }
sub close { ${ $_[0]{c} } = 1 }

package Punk::Test;

1;

__END__

=head1 NAME

Punk::Test - an in-process test client for Punk applications

=head1 SYNOPSIS

    use Test::More;
    use Punk::Test;

    my $t = Punk::Test->new('MyApp');

    $t->get_ok('/books')
      ->status_is(200)
      ->header_is('Content-Type' => 'application/json')
      ->json_is('/books/0/title' => 'Neuromancer')
      ->json_has('/page');

    $t->post_ok('/login', form => { user => 'a', pass => 'b' })
      ->status_is(302)
      ->header_like(Location => qr{^/});

    $t->get_ok('/me')->content_like(qr/hello a/);   # the jar kept the session

    $t->post_ok('/save', form => { a => 1 }, csrf => 1)
      ->status_is(200);

    $t->sse_ok('/events')
      ->sse_event_is(0, tick => 'hi')
      ->sse_json_is(1, '/n' => 2);

    $t->websocket_ok('/echo')
      ->send_ok('hi')
      ->message_is('echo:hi')
      ->finish_ok;

    done_testing;

=head1 DESCRIPTION

One C<Punk::Test> object is one browser against one compiled application:
requests run in-process against the same frozen PSGI coderef a server
would run, a cookie jar carries the session (and the CSRF mirror cookie)
between them, and every assertion returns the object so tests chain.
Assertions report through the one L<Test::Builder> singleton, so this
works under L<Test::More> and Test2 alike; a failing assertion diags the
method, path, status and the head of the body.

The application is compiled once, at C<new> - which means a test is also
a boot test.

There are deliberately no HTML-selector assertions: use C<content_like>
on the rendered page.

=head1 CONSTRUCTOR

=head2 new($app, %options)

C<$app> is a class name (C<to_app> is called, after a C<require> if the
class is not yet loaded) or a PSGI coderef. C<to_app> compiles once per
class, so the frozen coderef is shared: a second client on the same
class is a second browser against the same server. Options: C<timeout>
(seconds
for socket reads, default 5), C<max_bytes> (the most a stream may write
without closing before the test dies, default 1MB), C<csrf_cookie> and
C<csrf_header> (the mirror cookie read and the header written by
C<< csrf => 1 >>, defaults C<csrf> and C<X-CSRF-Token> - match them to a
C<csrf> keyword that renames things).

=head1 REQUESTS

=head2 get_ok / post_ok / put_ok / patch_ok / delete_ok / head_ok / options_ok

    $t->get_ok('/path?x=1');
    $t->post_ok('/save', form => { a => 1 });
    $t->post_ok('/api',  json => { a => 1 });
    $t->put_ok('/raw', body => $bytes, type => 'application/octet-stream');

One request; the assertion is that the application answered at all (a
die fails and diags the error). Options: C<form> (a hashref,
url-encoded), C<json> (encoded, C<application/json>), C<body> + C<type>
(raw), C<query> (overrides any C<?query> in the path), C<headers> (a
hashref of request headers), C<csrf> (send the jar's CSRF token in the
configured header), C<env> (raw PSGI env keys, merged last), C<name>
(the test name). A C<psgi.streaming> response is driven to completion
and its writes become the body.

=head2 login_as($user_or_id)

    $t->login_as($user->{id});
    $t->get_ok('/account')->status_is(200);

Sign a user straight into the cookie jar: a session cookie minted through
the application's own session config (and the C<auth> keyword's
C<session_key>), so guarded pages are reachable without driving a login
flow first. Takes an id or a user row; needs a client built from a class
name. Chainable.

=head1 THE RESPONSE

=head2 status / body / header($name) / json

The last response's status, body, one header (case-insensitive), and
the body decoded as JSON (cached; undef if it does not decode).

=head2 cookie($name) / csrf_token / reset_session

One cookie from the jar; the CSRF mirror cookie's value; empty the jar
(a fresh browser).

=head1 ASSERTIONS

All return C<$self>; all take an optional trailing test name.

=head2 status_is($code) / status_isnt($code)

=head2 header_is($name, $value) / header_like($name, qr) / header_exists($name)

=head2 content_is($body) / content_like(qr) / content_unlike(qr)

=head2 json_is($pointer, $want) / json_has($pointer) / json_like($pointer, qr)

The pointer is RFC 6901: C<''> is the whole document, C<'/a/0/b'> walks
in. C<json_is> deep-compares references through canonical JSON.

=head1 SERVER-SENT EVENTS

=head2 sse_ok($path, %options)

Drive an C<sse> route through the C<psgi.streaming> transport to
completion and parse the stream. The assertion is a 200
C<text/event-stream>. The handler must close deterministically: a
stream that writes more than C<max_bytes> without closing dies the
test rather than hanging it.

=head2 sse_event_is($i, $event, $data) / sse_data_is($i, $data) / sse_json_is($i, $pointer, $want)

Assert on the i-th dispatched event: its C<event:> name and data, its
data alone, or its data decoded as JSON at a pointer.

=head2 sse_events / sse_comments

The parsed events (hashrefs of C<event>, C<data>, C<id>, C<retry>) and
comment lines, for anything the assertions above do not cover.

=head1 WEBSOCKETS

=head2 websocket_ok($path, %options)

Open a websocket and assert the 101 - the C<Sec-WebSocket-Accept> is
verified against this module's own independent digest. Options:
C<protocol> (offer a subprotocol), C<headers>, C<live> (skip straight
to the live transport), C<name>.

Two transports, chosen automatically. A C<< blocking => 1 >> route runs
B<in-process>: the application runs in a fork with one end of a
socketpair as C<psgix.io>, so the conversation is fully interactive and
no server is needed. Any other route needs the B<live> transport - a
real L<Hyperman> worker forked once per client on first use - because
only Hyperman can detach the socket. Guard live-transport tests with
L</ws_live_available>, the way the dist's own suite does.

=head2 send_ok($payload, %options)

Send one frame - masked, as a client must. C<< binary => 1 >> sends
opcode 2; C<opcode> overrides outright.

=head2 message_is($want) / message_like(qr)

The next data message from the server (fragments reassembled, pongs
skipped) compared to a string or a pattern.

=head2 finish_ok

Send a clean close (1000) and assert the server echoes it; then tear
the connection down.

=head2 ws_live_available

    plan skip_all => 'Hyperman required'
        unless Punk::Test::ws_live_available;

Whether the live transport can run here at all: Hyperman 0.11+ with the
detach ABI. A function, not a method.

=head1 SEE ALSO

L<Punk>, L<Punk::Test::WS>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
