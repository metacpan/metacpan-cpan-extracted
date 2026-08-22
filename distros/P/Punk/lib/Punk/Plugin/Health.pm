package Punk::Plugin::Health;

use 5.010;
use strict;
use warnings;
use Punk ();

our $VERSION = '0.28';

1;

__END__

=head1 NAME

Punk::Plugin::Health - liveness and readiness probes that mean different things

=head1 SYNOPSIS

    package MyApp;
    use Punk;

    plugin 'Health' => {
        version => $ENV{APP_VERSION},
        detail  => 1,
        checks => {
            db => sub {
                my ($c) = @_;
                $c->model('User')->backend->dbh->do('SELECT 1');
                1;
            },
        },
    };

    # GET /healthz
    #   200 {"status":"ok","version":"1.4.2"}
    #
    # GET /readyz
    #   200 {"status":"ok","version":"1.4.2",
    #        "checks":{"db":{"ok":true,"ms":0.31}}}
    #   503 {"status":"unready","version":"1.4.2",
    #        "checks":{"db":{"ok":false,"ms":31.20,"why":"connect failed"}}}
    #
    # Without `detail` - the default - both bodies are {"status":"ok"} or
    # {"status":"unready"} and nothing else.

=head1 DESCRIPTION

Every deployment target - a load balancer, Kubernetes, an ELB target group, a
systemd watchdog - asks for a probe endpoint, so every application writes one.
What gets written is a route that returns C<200> without checking anything,
which answers "is the process up" - a question the TCP connect already
answered - and keeps answering C<200> while the database is gone.

=head2 Liveness is not readiness

This distinction is the whole plugin, and it is the thing hand-rolled probes
collapse.

B<C</healthz> is liveness>: is this process wedged? It must not check a
dependency. Failing a liveness probe gets the worker B<killed and restarted>,
and restarting a worker does not fix a database - it removes capacity at the
moment of maximum load. One slow dependency then restarts every worker in the
fleet, in a loop, which is a much worse outage than the one that started it.

So the liveness handler runs B<no checks at all>. Not the cheap ones, none. It
does not have access to the check list, which is how that stays true.

B<C</readyz> is readiness>: should this worker be sent traffic right now? This
is where dependencies belong. Failing it takes the worker out of the pool
without killing it, and it returns to the pool when the dependency does.
C<unready> answers C<503>, which a load balancer knows how to act on.

=head2 The budget is not a timeout

C<timeout> bounds a readiness pass, and it is important to be exact about
what that can do: B<nothing here can interrupt a check that has already
blocked inside a driver>. Punk runs on a single-threaded event loop, so a
blocked check blocks the worker, and arming C<SIGALRM> inside a request would
be a worse cure than the disease.

What the budget does is refuse to B<start> a check once the time is spent,
report that one as skipped, and answer unready. It stops a slow pass getting
slower; it cannot rescue one already hanging.

B<So a check that can hang must carry its own driver-level timeout.> That is
C<< Timeout >> / C<< mysql_read_timeout >> / C<< statement_timeout >> in your
C<DBI> connect arguments, not something this plugin can supply for you.

=head2 The answer is cached

A readiness answer is reused for C<ttl> seconds, which is what stops a probe
every 100ms becoming load in its own right. The cache is per worker and
stamped with the pid, so a worker that forked after an answer was computed
never serves its parent's verdict about a connection it does not have.

Both endpoints send C<Cache-Control: no-store>. A probe answer that anything
downstream is allowed to keep is a health check reporting the past.

=head2 What it says, and to whom

Both endpoints answer a bare C<< {"status":"ok"} >> by default. Health output
names an application's internal dependencies, and probe endpoints are
unauthenticated because a probe cannot hold a credential - so per-check detail
is behind C<< detail => 1 >>, to be turned on when the endpoints are bound
somewhere only the platform can reach.

With C<detail>:

    {"status":"unready","version":"1.4.2",
     "checks":{"cache":{"ok":true,"ms":0.04},
               "db":{"ok":false,"ms":31.20,"why":"connect failed"}}}

Checks are reported in name order, so two answers can be diffed and show what
changed rather than what moved.

=head2 Metrics

Punk writes no access log of its own, so there is nothing here to exclude
these routes from. But a probe every second will dominate any metric an
observer keeps, and an observer can only skip what it can name:

    my @skip = Punk::Plugin::Health->paths($app);

Both routes are already excluded from L<Punk::Plugin::Sitemap>: a probe
endpoint is not a page.

=head1 OPTIONS

=head2 checks

A hashref of C<< name => sub { ... } >>, run only by C</readyz>. The callback
receives the context.

A check that returns true is ready. One that returns false is not, with no
reason given. One that B<dies> is not ready and the exception is the reason.
All three are ordinary answers - a readiness probe exists to be told no, so
none of them is an error.

=head2 detail

Report per-check results and the version. Off by default; see above.

=head2 version

A version string, reported with C<detail>, so a probe answers "which code is
this" as well as "is it alive".

=head2 ttl

Seconds a readiness answer may be reused. Default C<1>. Zero disables the
cache, which is reasonable when the checks are free.

=head2 timeout

The budget for a whole readiness pass, in seconds. Default C<2>. Read "The
budget is not a timeout" above before relying on it.

=head2 liveness / readiness

The paths, defaulting to C</healthz> and C</readyz>. An explicit C<undef>
disables that endpoint, for a platform that only probes one of them.

=head1 METHODS

=head2 Punk::Plugin::Health->paths($app)

The paths this plugin serves.

=head1 SEE ALSO

L<Punk>, L<Punk::Plugin::Sitemap>

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
