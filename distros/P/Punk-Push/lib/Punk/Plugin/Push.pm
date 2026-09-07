package Punk::Plugin::Push;

use 5.010;
use strict;
use warnings;
use parent 'Punk::Plugin';
use Carp ();
use Scalar::Util ();

use VAPID ();
use File::Raw::JSON qw(file_json_encode);
use Punk::Push ();
use Punk::Push::Subscription ();
use Punk::Push::Result ();

our $VERSION = '0.02';

our @OPTIONS = qw(
    subject public_key private_key
    prefix guard assets model table
    ttl urgency queue sqitch timeout
);

our %URGENCY = map { $_ => 1 } qw(very-low low normal high);

sub register {
    my ($self, $app, $opts) = @_;
    $opts ||= {};

    my $cfg = _options($opts);
    $app->{push_config} = $cfg;

    _ensure_model($app, $cfg);
    _sqitch($app, $cfg) if $cfg->{sqitch};
    _queue_task($app, $cfg) if $cfg->{queue};

    # At to_app, so `auth` and the guard may be declared on either side of
    # this line.
    my $routes = sub { _routes($app, $cfg) };
    if ($app->can('on_compile')) { $app->on_compile($routes, __PACKAGE__) }
    else                         { $routes->() }

    $app->helper(push_key => sub { $cfg->{public_key} });

    $app->helper(push_subscribe => sub {
        my ($c, $raw, %args) = @_;
        return __PACKAGE__->store($c->app, $args{user_id} // $c->auth_id,
                                  $raw, $args{user_agent});
    });

    $app->helper(push_send => sub {
        my ($c, $who, $payload, %args) = @_;
        return __PACKAGE__->send_via($c, $who, $payload, %args);
    });

    $app->helper(push_unsubscribe => sub {
        my ($c, $endpoint, %args) = @_;
        return __PACKAGE__->forget($c->app, $args{user_id} // $c->auth_id,
                                   $endpoint);
    });

    return;
}

sub _options {
    my ($opts) = @_;

    my %known = map { $_ => 1 } @OPTIONS;
    for my $k (sort keys %$opts) {
        next if $known{$k};
        Carp::croak("Punk::Plugin::Push: unknown option '$k' (known: "
                  . join(', ', @OPTIONS) . ')');
    }

    for my $k (qw(subject public_key private_key)) {
        next if defined $opts->{$k} && length $opts->{$k};
        Carp::croak("Punk::Plugin::Push: `$k` is required"
            . ($k eq 'subject'
                ? " - RFC 8292 demands it, and a push service rejects a JWT\n"
                . "  without one with a 403 that explains nothing"
                : " - generate a pair with `punk push keys`.\n"
                . "  A key minted at boot would differ per worker and per\n"
                . "  restart, and every subscription made against the old one\n"
                . "  would be undeliverable in silence"));
    }

    # RFC 8292 wants a mailto: or https: contact URI. Deciding that here
    # rather than leaving it to VAPID::validate_subject keeps the refusal a
    # croak with a message, on every URI release: for a subject with neither
    # a scheme nor a host URI->new returns a URI::_generic, and asking one of
    # those for its host is fatal on some installs.
    unless ($opts->{subject} =~ m{\A mailto: \S+ \@ \S+ \z}x
         || $opts->{subject} =~ m{\A https?:// [^/?\#\s]+ }x) {
        Carp::croak("Punk::Plugin::Push: `subject` is not a url or mailto:"
            . " address - RFC 8292 wants a mailto: or https: URI the push\n"
            . "  service can reach you at when it drops your traffic");
    }

    my %cfg = (
        subject     => VAPID::validate_subject($opts->{subject}),
        public_key  => $opts->{public_key},
        private_key => $opts->{private_key},
        prefix      => defined $opts->{prefix}  ? $opts->{prefix}  : '/push',
        guard       => $opts->{guard},
        assets      => exists $opts->{assets}   ? ($opts->{assets} ? 1 : 0) : 1,
        model       => defined $opts->{model}   ? $opts->{model}   : 'PushSubscription',
        table       => $opts->{table},
        ttl         => defined $opts->{ttl}     ? $opts->{ttl}     : 2419200,
        urgency     => defined $opts->{urgency} ? $opts->{urgency} : 'normal',
        queue       => $opts->{queue} ? 1 : 0,
        sqitch      => $opts->{sqitch} ? 1 : 0,
        timeout     => defined $opts->{timeout} ? $opts->{timeout} : 10,
    );

    VAPID::validate_public_key($cfg{public_key});
    VAPID::validate_private_key($cfg{private_key});

    Carp::croak("Punk::Plugin::Push: `prefix` must be a rooted path, not "
              . "'$cfg{prefix}'")
        unless $cfg{prefix} =~ m{\A/} && $cfg{prefix} !~ m{//|[:*]};

    Carp::croak("Punk::Plugin::Push: `urgency` must be one of "
              . join(', ', sort keys %URGENCY) . ", not '$cfg{urgency}'")
        unless $URGENCY{ $cfg{urgency} };

    Carp::croak('Punk::Plugin::Push: `ttl` must not be negative')
        if $cfg{ttl} !~ /\A\d+\z/;

    Carp::croak('Punk::Plugin::Push: `timeout` must be a positive number')
        unless $cfg{timeout} > 0;

    return \%cfg;
}

sub _ensure_model {
    my ($app, $cfg) = @_;
    my $name = $cfg->{model};
    return if $name =~ /::/;

    my $models = $app->{models};
    my $named = 0;
    if (ref $models eq 'ARRAY') {
        for my $m (@$models) {
            next unless defined $m;
            return if $m eq $name;
            $named++;
        }
    }

    if ($app->can('caller_class')) {
        my $full = $app->caller_class . '::Model::' . $name;
        return if eval "require $full; 1";
    }

    $app->model_auto(1) if !$named && !defined $app->{model_auto}
                        && $app->can('model_auto');

    my $shipped = 'Punk::Model::PushSubscription';
    eval "require $shipped; 1" or Carp::croak($@);
    $app->model_class($shipped);
    $cfg->{model} = $shipped;
    return;
}

sub _beside {
    my $pm = $INC{'Punk/Plugin/Push.pm'} or return undef;
    $pm =~ s{\.pm\z}{};
    return -d $pm ? $pm : undef;
}

sub shipped_dir {
    my $dir = _beside() or return undef;
    return -d "$dir/sqitch" ? "$dir/sqitch" : undef;
}

sub _sqitch {
    my ($app, $cfg) = @_;

    my $dir = __PACKAGE__->shipped_dir;
    Carp::croak('Punk::Plugin::Push: sqitch => 1 but the shipped project is '
              . 'not beside this module')
        unless $dir;

    unless (eval { require Punk::Plugin::Sqitch; 1 }) {
        Carp::croak('Punk::Plugin::Push: sqitch => 1 needs Punk::Sqitch '
                  . 'installed');
    }
    Carp::croak('Punk::Plugin::Push: the installed Punk::Sqitch has no '
              . 'project registry; 0.01 or newer is needed')
        unless Punk::Plugin::Sqitch->can('project');

    Punk::Plugin::Sqitch->project($app, 'punk_push', $dir,
                                  engines => [qw(pg sqlite mysql)]);
    return;
}

sub _guard_for {
    my ($app, $cfg) = @_;
    return $cfg->{guard} if defined $cfg->{guard};

    my $auth = $app->can('auth_config') ? $app->auth_config : undef;
    Carp::croak('Punk::Plugin::Push: no `auth` on this application, so '
              . "/subscribe would be an open relay.\n  Declare auth, or pass "
              . 'an explicit `guard` to the plugin.')
        unless $auth;

    return sub {
        my ($c) = @_;
        return 1 if defined $c->auth_id;
        return $c->json({ errors => [ { message => 'Unauthorized' } ] }, 401);
    };
}

sub _fnv32 {
    my ($bytes) = @_;
    my $h = 2166136261;
    for my $c (unpack 'C*', $bytes) {
        $h ^= $c;
        $h = ($h * 16777619) & 0xFFFFFFFF;
    }
    return $h;
}

sub _asset {
    my ($name) = @_;
    my $dir = _beside() or return undef;
    open my $fh, '<:raw', "$dir/$name" or return undef;
    local $/;
    return scalar <$fh>;
}

sub _routes {
    my ($app, $cfg) = @_;
    my $prefix = $cfg->{prefix};

    $app->route('GET', "$prefix/key", sub {
        my ($c) = @_;
        return $c->text($cfg->{public_key});
    }, undef, { sitemap => 0 });

    if ($cfg->{assets}) {
        for my $file (qw(push.js push-sw.js)) {
            my $bytes = _asset($file);
            next unless defined $bytes;
            my $etag = sprintf '"%x-%x"', length($bytes), _fnv32($bytes);

            my @extra = $file eq 'push-sw.js'
                      ? ('Service-Worker-Allowed' => '/') : ();

            $app->route('GET', "$prefix/$file", sub {
                my ($c) = @_;
                my $inm = $c->req->header('If-None-Match');
                return [ 304, [ 'ETag' => $etag, @extra ], [] ]
                    if defined $inm && $inm eq $etag;
                return [ 200, [
                    'Content-Type'   => 'text/javascript; charset=utf-8',
                    'Content-Length' => length $bytes,
                    'ETag'           => $etag,
                    @extra,
                ], [ $bytes ] ];
            }, undef, { sitemap => 0 });
        }
    }

    my $scope = $app->under($prefix => _guard_for($app, $cfg));

    $scope->post('/subscribe' => sub {
        my ($c) = @_;
        my $raw = eval { $c->req->json };
        return $c->json({ errors => [ { message => 'a JSON body is required' } ] }, 400)
            unless ref $raw eq 'HASH';
        my $id = eval {
            __PACKAGE__->store($c->app, $c->auth_id, $raw,
                               $c->req->header('User-Agent'));
        };
        if (my $err = $@) {
            $err =~ s/ at \S+ line \d+\.?\n?\z//;
            return $c->json({ errors => [ { message => $err } ] }, 400);
        }
        return $c->json({ ok => 1, id => $id });
    });

    $scope->post('/unsubscribe' => sub {
        my ($c) = @_;
        my $raw = eval { $c->req->json };
        my $endpoint = ref $raw eq 'HASH' ? $raw->{endpoint} : undef;
        return $c->json({ errors => [ { message => 'an endpoint is required' } ] }, 400)
            unless defined $endpoint && length $endpoint;
        my $gone = __PACKAGE__->forget($c->app, $c->auth_id, $endpoint);
        return $c->json({ ok => 1, removed => $gone });
    });

    return;
}

our $TASK = 'punk.push.send';

sub _queue_task {
    my ($app, $cfg) = @_;

    my $install = sub {
        my $caller = $app->can('caller_class') ? $app->caller_class : undef;
        my $task = $caller && $caller->can('task');
        Carp::croak('Punk::Plugin::Push: queue => 1 needs Punk::Queue, and '
                  . "`plugin 'Queue'` on this application")
            unless $task;
        $task->($TASK, sub {
            my ($job, $id, $payload, @rest) = @_;
            my $app = $job->app;
            my $model = __PACKAGE__->_model($app);
            my $row = $model->get(id => $id);
            # Pruned since the job was enqueued. Not an error: the
            # subscription really is gone, and the job has nothing to do.
            return { gone => 1 } unless $row;
            my $r = __PACKAGE__->send_to($app, $row, $payload, @rest);
            die $r->error || "push failed with status " . ($r->status // '?')
                unless $r->delivered || $r->gone;
            return { status => $r->status, pruned => $r->pruned };
        });
    };

    if ($app->can('on_compile')) { $app->on_compile($install, __PACKAGE__) }
    else                         { $install->() }
    return;
}

sub send_via {
    my ($class, $c, $who, $payload, %opts) = @_;
    my $app = $c->app;
    my $cfg = $class->config_for($app);

    return $class->send($c, $who, $payload, %opts)
        unless $cfg->{queue} && $c->can('enqueue');

    my @subs = ref $who eq 'HASH' ? ($who) : $class->for_user($app, $who);
    my @out;
    for my $sub (@subs) {
        my $id = $sub->{id};
        # A subscription with no id was never stored, so there is nothing for
        # a worker to re-read. Send it inline rather than enqueue a job that
        # cannot find its row.
        if (!defined $id) {
            push @out, $class->send_to($c, $sub, $payload, %opts);
            next;
        }
        my $job = $c->enqueue($TASK, [ $id, $payload, %opts ]);
        push @out, Punk::Push::Result->new(endpoint => $sub->{endpoint},
                                           queued => $job);
    }
    return @out;
}

sub config_for {
    my ($class, $app) = @_;
    my $cfg = $app->{push_config}
        or Carp::croak('Punk::Plugin::Push: the plugin is not registered on '
                     . 'this application');
    return $cfg;
}

sub _model {
    my ($class, $app) = @_;
    my $cfg = $class->config_for($app);
    return $app->model_instance($cfg->{model});
}

sub _one {
    my ($model, $filter) = @_;
    my $page = $model->search($filter, { limit => 1 });
    my $rows = ref $page eq 'HASH' ? $page->{rows} : $page;
    return ($rows && @$rows) ? $rows->[0] : undef;
}

sub _all {
    my ($model, $filter) = @_;
    my @out;
    my %opts;
    while (1) {
        my $page = $model->search($filter, { %opts });
        my $rows = ref $page eq 'HASH' ? $page->{rows} : $page;
        last unless $rows && @$rows;
        push @out, @$rows;
        last unless ref $page eq 'HASH' && $page->{has_more_data}
                 && defined $page->{next};
        $opts{after} = $page->{next};
    }
    return @out;
}

sub _json {
    my ($payload) = @_;
    return $payload unless ref $payload;
    my $bytes = eval { file_json_encode($payload, sort_keys => 1) };
    return $bytes if defined $bytes;
    Carp::croak('Punk::Plugin::Push: the payload is not encodable as JSON. '
              . "Strings must be characters or UTF-8 bytes; a latin-1 byte\n"
              . "  string such as \"caf\\x{e9}\" is neither. ($@)");
}

sub _is_ctx {
    my ($thing) = @_;
    return 0 unless Scalar::Util::blessed($thing);
    return $thing->can('app') ? 1 : 0;
}

sub _app_of {
    my ($thing) = @_;
    return _is_ctx($thing) ? $thing->app : $thing;
}

sub _ua {
    my ($class, $thing) = @_;
    my $app = _app_of($thing);
    my $cfg = $class->config_for($app);

    return $cfg->{ua} if $cfg->{ua};
    return $thing->ua if _is_ctx($thing) && $thing->can('ua');

    require Fetch;
    return $cfg->{fallback_ua} ||= Fetch->new(timeout => $cfg->{timeout});
}

sub _audience {
    my ($endpoint) = @_;
    my ($scheme, $host) = $endpoint =~ m{\A(https?)://([^/?#]+)}
        or Carp::croak("Punk::Plugin::Push: cannot read an origin from "
                     . "'$endpoint'");
    return "$scheme://$host";
}

sub _vapid_header {
    my ($class, $app, $audience) = @_;
    my $cfg = $class->config_for($app);

    my $cached = $cfg->{jwt}{$audience};
    return $cached->{header} if $cached && $cached->{exp} > time + 300;

    my $exp = time + 12 * 60 * 60;
    my $h = VAPID::generate_vapid_header(
        $audience, $cfg->{subject},
        $cfg->{public_key}, $cfg->{private_key},
        $exp, 1,
    );
    $cfg->{jwt}{$audience} = { header => $h->{Authorization}, exp => $exp };
    return $h->{Authorization};
}

sub _keys_of {
    my ($sub) = @_;
    return ($sub->{endpoint}, $sub->{keys}{p256dh}, $sub->{keys}{auth})
        if ref $sub->{keys} eq 'HASH';
    return ($sub->{endpoint}, $sub->{p256dh}, $sub->{auth});
}

our $MAX_BODY = 4096;

sub send_to {
    my ($class, $thing, $sub, $payload, %opts) = @_;
    my $app = _app_of($thing);
    my $cfg = $class->config_for($app);

    my ($endpoint, $p256dh, $auth) = _keys_of($sub);
    my $body = VAPID::encrypt_payload(_json($payload),
        { endpoint => $endpoint, keys => { p256dh => $p256dh, auth => $auth } });

    if (length($body) > $MAX_BODY) {
        Carp::croak(sprintf
            'Punk::Plugin::Push: the encrypted payload is %d octets and a push '
          . 'service guarantees only %d. Shorten the message by at least %d.',
            length($body), $MAX_BODY, length($body) - $MAX_BODY);
    }

    my %headers = (
        'Authorization'    => $class->_vapid_header($app, _audience($endpoint)),
        'TTL'              => defined $opts{ttl} ? $opts{ttl} : $cfg->{ttl},
        'Content-Encoding' => 'aes128gcm',
        'Content-Type'     => 'application/octet-stream',
    );
    my $urgency = defined $opts{urgency} ? $opts{urgency} : $cfg->{urgency};
    $headers{Urgency} = $urgency if $urgency ne 'normal';
    $headers{Topic} = $opts{topic} if defined $opts{topic};

    my ($status, $error);
    my $res = eval {
        $class->_ua($thing)->post($endpoint, headers => \%headers, body => $body)
                           ->get;
    };
    if ($@) { $error = "$@"; chomp $error }
    elsif ($res) { $status = $res->status }

    my $result = Punk::Push::Result->new(endpoint => $endpoint,
                                         status => $status, error => $error);

    if (defined $sub->{id}) {
        if ($result->gone) {
            $result->{pruned} = $class->prune($app, $endpoint) ? 1 : 0;
        }
        elsif (defined $status) {
            $class->touch($app, $endpoint, $status);
        }
    }

    return $result;
}

sub send {
    my ($class, $thing, $who, $payload, %opts) = @_;
    my $app = _app_of($thing);
    my @subs = ref $who eq 'HASH' ? ($who) : $class->for_user($app, $who);
    return () unless @subs;
    return map { $class->send_to($thing, $_, $payload, %opts) } @subs;
}

sub store {
    my ($class, $app, $user_id, $raw, $user_agent) = @_;

    Carp::croak('Punk::Plugin::Push: a subscription needs a user')
        unless defined $user_id && length $user_id;

    my $sub = Punk::Push::Subscription->check($raw);
    my $model = $class->_model($app);
    my $now = time;

    my $existing = _one($model, { endpoint => $sub->{endpoint} });
    if ($existing) {
        $model->update({
            id           => $existing->{id},
            user_id      => $user_id,
            p256dh       => $sub->{p256dh},
            auth         => $sub->{auth},
            user_agent   => $user_agent,
            last_seen_at => $now,
        });
        return $existing->{id};
    }

    return $model->create({
        user_id      => $user_id,
        endpoint     => $sub->{endpoint},
        p256dh       => $sub->{p256dh},
        auth         => $sub->{auth},
        user_agent   => $user_agent,
        created_at   => $now,
        last_seen_at => $now,
    });
}

sub forget {
    my ($class, $app, $user_id, $endpoint) = @_;
    my $model = $class->_model($app);
    my $row = _one($model, { endpoint => $endpoint });
    return 0 unless $row;
    return 0 if defined $user_id && "$row->{user_id}" ne "$user_id";
    $model->delete(id => $row->{id});
    return 1;
}

sub prune {
    my ($class, $app, $endpoint) = @_;
    my $model = $class->_model($app);
    my $row = _one($model, { endpoint => $endpoint });
    return 0 unless $row;
    $model->delete(id => $row->{id});
    return 1;
}

sub for_user {
    my ($class, $app, $user_id) = @_;
    return () unless defined $user_id && length $user_id;
    my $model = $class->_model($app);
    return _all($model, { user_id => $user_id });
}

sub touch {
    my ($class, $app, $endpoint, $status) = @_;
    my $model = $class->_model($app);
    my $row = _one($model, { endpoint => $endpoint });
    return 0 unless $row;
    $model->update({ id => $row->{id}, last_status => $status,
                     last_seen_at => time });
    return 1;
}

1;

__END__

=head1 NAME

Punk::Plugin::Push - Web Push notifications, encrypted end to end

=head1 SYNOPSIS

    package MyApp;
    use Punk;
    use Punk::Plugin::Push;

    host 'https://example.com';
    auth  ...;                       # subscribe and unsubscribe are guarded

    plugin 'Push' => {
        subject     => 'mailto:ops@example.com',
        public_key  => { '$env' => 'VAPID_PUBLIC'  },
        private_key => { '$env' => 'VAPID_PRIVATE' },
    };

    post '/reports' => sub {
        my ($c) = @_;
        $c->push_send($c->auth_id, {
            title => 'Your report is ready',
            body  => 'Three pages, as usual.',
            url   => '/reports/2026-09',
        });
        return $c->json({ ok => 1 });
    };

=head1 DESCRIPTION

An application that wants to reach a user who has closed the tab has one
standard way to do it: the Push API, delivered through the browser vendor's
push service. This is that, for Punk.

The message is encrypted end to end, so the push service relays bytes it
cannot read. L<VAPID> does the cryptography - RFC 8291 message encryption over
the RFC 8188 C<aes128gcm> content encoding, and RFC 8292 identification - and
this plugin supplies the routes, the storage, the delivery and the pruning
around it.

Generate a keypair once with C<punk push keys>.

=head2 What it serves

    GET  /push/key           the VAPID public key, for the browser
    POST /push/subscribe     store a subscription      (guarded)
    POST /push/unsubscribe   remove one                (guarded)
    GET  /push/push.js       the client half           (assets => 1)
    GET  /push/push-sw.js    a minimal service worker  (assets => 1)

C<prefix> moves all five. The assets are read once at C<to_app> and served
from frozen bytes with an C<ETag>.

=head2 An unguarded subscribe is an open relay

A subscription belongs to a user. An unauthenticated C<POST> that writes one
lets anybody who can guess a user id register their own browser to receive
that user's notifications - a disclosure bug with a delivery mechanism
attached.

So the write routes are guarded, by the application's C<auth> unless C<guard>
names something else, and an application with B<neither> is refused at
C<to_app> rather than served unguarded. C<GET /push/key> is not guarded; it is
a public key.

Unsubscribe removes a row only when it belongs to the authenticated user.
Deleting by endpoint alone would let any authenticated user unsubscribe any
other, and an endpoint is not a secret: it is sent to a third party on every
delivery.

=head2 The keys are configuration and are never generated for you

C<subject>, C<public_key> and C<private_key> croak at the C<plugin> line,
because nothing declared later can supply them.

The tempting convenience is to mint a keypair when none is configured. It is
wrong in a way that takes weeks to notice: Hyperman runs a pool, so each worker
would generate a different key, a subscription created against one worker would
be undeliverable from every other, and a restart would invalidate the lot.
Every failure would look like an intermittent push service.

C<subject> is required by RFC 8292 and push services reject a JWT without one,
so leaving it out produces a C<403> whose body explains nothing. It must be a
C<mailto:> address or an C<http:>/C<https:> URL, and anything else croaks at
the C<plugin> line rather than at the first delivery.

=head2 An endpoint is a URL you will POST to, so it is validated like one

The C<endpoint> a browser hands you is a URL this server will POST to, on a
schedule the client chose, with a body the client cannot read. Unconstrained,
that is a server-side request forgery primitive.

So it must be an absolute C<https> URL. C<p256dh> must decode to exactly 65
bytes beginning C<0x04> and C<auth> to exactly 16, both checked on the decoded
bytes - a base64url decoder that ignores a bad character turns a corrupt key
into a short one, and the length is what catches that. See
L<Punk::Push::Subscription>.

=head2 One audience per endpoint

The VAPID token's C<aud> is the endpoint's origin, including a non-default
port. A token minted for one push service is not valid at another, so it is
computed per endpoint and cached against that origin. Caching one across a
fan-out is the bug that makes Firefox work and Chrome fail on the same send.

=head2 A 410 means gone, and gone means deleted

A C<404> or C<410> from the push service means the subscription is permanently
gone, and the row is deleted. Anything else - a C<5xx> included - leaves it
alone: that is the push service having a bad day.

The asymmetry is the point. Deleting on the wrong signal costs a subscription
that cannot be recreated without the user, because they have to grant
permission again and browsers make asking twice deliberately hard. Keeping a
dead one costs a wasted request.

Storage is only touched for a subscription that came from storage. One handed
to L</send_to> directly belongs to its caller.

=head2 There is a hard size limit, and it is smaller than it looks

RFC 8291 guarantees a push service will accept only 4096 octets of B<encrypted>
payload, and the encoding spends 86 bytes on the record header, one on the
padding delimiter and 16 on the authentication tag before any of your message.

An oversize payload croaks with its measured size and by how much to shorten
it. The alternative is discovering it as a C<413> from a push service, per
subscription.

=head2 It sends on the worker's own loop

Inside a request the send goes through C<< $c->ua >> - the one L<Fetch> agent
per worker that L<Punk::UA> builds, bound to the same event loop that serves
inbound requests, with its pooled connections and its fork check.

That is the difference between a send costing the worker nothing and costing
it the whole round trip to the push service. A privately constructed agent
gets a standalone loop, and awaiting a future on it pumps B<that> loop: the
worker stops answering anything else until the push service replies, which is
not a number this application controls.

Outside a request - a job, a cron, C<punk push send> - there is no worker loop
to join, so the plugin builds its own agent and C<< ->get >> blocks. That is
the degradation L<Punk::UA> documents for C<< $c->ua >> itself: slower, never
broken.

L</send_to> and L</send> therefore take B<either> a context or the
application. Hand them the context when you have one.

=head2 Stale by nobody's design

With C<< queue => 0 >>, the default, a C<5xx> is B<reported to the caller and
not retried>. This plugin does not queue, sleep or retry on its own.

C<< queue => 1 >> hands delivery to L<Punk::Queue>, which is where retries and
backoff already live. Note that only the C<< $c->push_send >> helper enqueues:
L</send_to> always sends inline, which is what the worker running the task must
do, or a job would enqueue itself forever.

=head2 The worker is served with Service-Worker-Allowed

A service worker's scope defaults to the directory it is served from, so one
at C</push/push-sw.js> could only ever control C</push/*>. Registering it for
the site is refused outright:

    The path of the provided scope ('/') is not under the max scope
    allowed ('/push/')

Notifications are site-wide - C<notificationclick> focuses whatever page the
user has open - so the worker is served with C<< Service-Worker-Allowed: / >>,
which raises that ceiling.

If you serve the worker yourself (C<< assets => 0 >>), either put it at the
site root or send the same header. This is the first thing to check when
registration fails.

=head2 A service worker outlives your deploy

C<< assets => 1 >> is for getting a demo working.

A service worker is a cache with a lifetime of its own: the browser keeps the
one it has and updates it on its own schedule, so once installed browsers are
asking for C</push/push-sw.js> you cannot simply stop serving it. Past a demo,
copy both files into your own tree, serve them from your own static mount, and
set C<< assets => 0 >>.

There is also only B<one> service worker per scope. If you already register one
for offline support, merge the two handlers into it rather than registering a
second, or whichever registered last wins and the other quietly stops working.

=head1 OPTIONS

    plugin 'Push' => {
        subject     => 'mailto:ops@example.com',  # REQUIRED
        public_key  => '...',                     # REQUIRED
        private_key => '...',                     # REQUIRED
        prefix      => '/push',
        guard       => undef,        # default: the application's auth
        assets      => 1,            # serve push.js and push-sw.js
        model       => 'PushSubscription',
        ttl         => 2419200,      # seconds a push service may hold it
        urgency     => 'normal',     # very-low | low | normal | high
        queue       => 0,            # deliver through Punk::Queue
        sqitch      => 0,            # ship the DDL as a Sqitch project
        timeout     => 10,
    };

An unknown option croaks, naming what was available. A misspelled option is a
setting that silently did not apply, and C<urgencey> would leave every
notification at the default while the application believed otherwise.

=head1 STORAGE

A model, L<Punk::Model::PushSubscription>, registered under its full class name
when the application has not declared one of its own. Declare
C<< model => 'MyName' >> to use yours; the DDL is in that module's POD, and
C<< sqitch => 1 >> ships it as the C<punk_push> Sqitch project when
L<Punk::Sqitch> is installed.

C<endpoint> is unique, and that is load-bearing: a browser re-subscribing
produces the same endpoint, and without the constraint every re-subscribe adds
a row and one send fans out across the duplicates.

=head1 HELPERS

=head2 $c->push_send($who, \%payload, %opts)

C<$who> is a user id, or one subscription hashref. A user id fans out over
every subscription that user has - people have a phone and a laptop, and a
notification that reaches only one of them is a bug report.

Returns a L<Punk::Push::Result> per subscription. One failure does not abort
the rest. A user with no subscriptions is an empty list, not an error: that is
the ordinary state of most users.

C<%opts> takes C<ttl>, C<urgency> and C<topic>. C<topic> is worth knowing
about: a push service B<replaces> an undelivered message carrying the same
topic rather than queueing both, which is the difference between a phone
showing one badge on reconnect and thirty.

=head2 $c->push_subscribe(\%subscription)

Store a subscription for the current user. Upserts on the endpoint.

=head2 $c->push_unsubscribe($endpoint)

Remove one, only when it belongs to the current user.

=head2 $c->push_key

The VAPID public key, for a template that would rather inline it than fetch
C</push/key>.

=head1 OUTSIDE A REQUEST

A job, a cron and the CLI have no C<$c>. These take the compiled application,
which is where the keys and the subscription store live.

=head2 send_to

    Punk::Plugin::Push->send_to($app, $subscription, \%payload, %opts);
    Punk::Plugin::Push->send_to($c,   $subscription, \%payload, %opts);

One subscription, sent inline. Never enqueues, whatever C<queue> says - this is
what the queue worker itself calls.

Takes a context or the application. With a context the send goes on that
worker's loop-bound agent; with the application it builds its own, which is
right where there is no worker loop to join.

=head2 send

    Punk::Plugin::Push->send($app, $user_id, \%payload, %opts);
    Punk::Plugin::Push->send($c,   $user_id, \%payload, %opts);

The same fan-out C<< $c->push_send >> performs. Takes a context or the
application, as L</send_to> does.

=head1 SEE ALSO

L<Punk::Push>, L<Punk::Push::Subscription>, L<Punk::Push::Result>,
L<Punk::Model::PushSubscription>, L<Punk::Command::Push>, L<VAPID>, L<Punk>,
L<Punk::Plugin>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
