package Mailer;

use Punk;
use Punk::Plugin::Queue;          # compile time: the queue/task/cron keywords
use File::Basename ();

# Punk Mailer - the Punk::Queue example application.
#
# A signup form that hands the slow part to the queue, the pages that watch
# a job through, a nightly digest and a recurring report - and the admin UI
# mounted inside the same app, behind the same guard stack.
#
# The shape to notice: nothing in a request handler waits for a task. The
# handler enqueues and answers; a worker process runs the body later, and
# the same body runs whether it was enqueued by the form, by the cron
# scheduler or by hand from the CLI.
#
# Two entry points use this class:
#
#     plackup -p 5000 app.psgi                        # the web tier
#     punk-queue worker --app bin/queue.pl -j 2       # the worker pool
#
# See README.pod.

my $home = File::Basename::dirname(__FILE__) . '/..';

views Stencil => {
    template_dir => "$home/root/templates",
    wrapper      => 'layout.tmpl',
};

static '/static' => "$home/root/static";

# The admin UI's writes are CSRF-protected, which needs a session, which
# needs a signing key. In a real app that key comes from the secret system
# (`secret 'session.key'`, resolved from punk.yml) - never from a literal
# and never from a default like the one below.
session secret => $ENV{MAILER_SECRET} || 'development-secret-do-not-ship',
        expires => '1d';
csrf;

# ---- the queue -------------------------------------------------------------

# One dsn for the app and the worker pool: they meet in the database, which
# is the entire point of a durable queue.
plugin 'Queue' => {
    dsn => $ENV{MAILER_QUEUE_DSN}
         || "dbi:SQLite:dbname=$home/queue.db",

    admin => {
        prefix => '/queue',
        guard  => 'Web::Auth#admin',      # REQUIRED - see Web::Auth
        live   => 1,                      # websocket updates on Hyperman
    },

    # Off by default. MAILER_IN_SERVER=1 runs the welcome mail on the web
    # workers' own event loops instead - fine for this, wrong for anything
    # with real volume, and railed to an explicit task allowlist.
    in_server => $ENV{MAILER_IN_SERVER}
        ? { tasks => ['mail.welcome'], queues => ['mail'], cap => 5 }
        : undef,
};

# Queue-level defaults: every job landing in `mail` inherits these unless
# it says otherwise. Application configuration, not schema - it lives on
# the queue object, not in the database.
queue 'mail'    => { attempts => 5, timeout => 30 };
queue 'reports' => { attempts => 1, timeout => 120 };

# ---- the tasks -------------------------------------------------------------

# A task target reads like a route target: 'Job::Mail#welcome' is
# Mailer::Controller::Job::Mail::welcome, resolved at to_app, so a typo is
# a boot croak rather than a job that fails at 3am. The third argument is
# that task's own defaults.
task 'mail.welcome'   => 'Job::Mail#welcome',    { queue => 'mail' };
task 'mail.digest'    => 'Job::Mail#digest',     { queue => 'mail' };
task 'report.signups' => 'Job::Report#signups',  { queue => 'reports' };

# A coderef works too, for the small ones. The body gets the job first and
# the enqueued arguments after - there is no invocant, because a task is a
# body, not a method call.
task 'ping' => sub {
    my ($job, $note) = @_;
    $job->note(seen => 1);
    return { pong => $note // 'hello', at => time };
};

# ---- the crons -------------------------------------------------------------

# A cron whose target names a registered task reuses it; one that names a
# 'Class#method' registers a task of its own. Both are validated at to_app.
cron '*/5 * * * *' => 'report.signups';
cron '0 6 * * *'   => 'Job::Mail#digest', {
    name  => 'daily-digest',
    queue => 'mail',
    args  => ['daily'],
};

# ---- the web tier ----------------------------------------------------------

get  '/'          => 'Web::Home#index';
post '/signup'    => 'Web::Home#signup';
get  '/jobs/:id'  => 'Web::Home#job';
post '/ping'      => 'Web::Home#ping';

1;

__END__

=head1 NAME

Mailer - the Punk::Queue example application

=head1 DESCRIPTION

See F<README.pod> in this directory.

=cut
