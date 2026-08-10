package Punk::Queue::Command;

use 5.010;
use strict;
use warnings;
use Getopt::Long ();
use Punk::Queue ();

our $VERSION = '0.02';

# The subcommands behind `punk-queue`. Each returns an exit code - 0 fine,
# 1 the thing you asked about is wrong (job not found, schema behind), 2
# the command was used wrongly - and prints its own report, so bin/punk-queue
# stays a dispatcher. This is the Punk::Command shape.
#
# The governing rule from the plan: anything the admin UI can do, the CLI
# can do, and every subcommand works from --dsn alone - inspection must
# never require loading the app.

our @COMMANDS = qw(worker enqueue job jobs workers stats repair locks
                   lock unlock broadcast crons cron migrate reset version
                   help);

sub commands { @COMMANDS }

sub main {
    my (@argv) = @_;

    if (!@argv || $argv[0] eq '-h' || $argv[0] eq '--help') {
        usage(\*STDOUT);
        return 0;
    }
    if ($argv[0] eq '-v' || $argv[0] eq '--version') {
        print "punk-queue $VERSION (Punk::Queue $Punk::Queue::VERSION)\n";
        return 0;
    }

    my $cmd = shift @argv;
    my %commands = (
        worker    => \&worker,
        enqueue   => \&enqueue,
        job       => \&job,
        jobs      => \&jobs,
        workers   => \&workers,
        stats     => \&stats,
        repair    => \&repair,
        locks     => \&locks,
        lock      => \&lock,
        unlock    => \&unlock,
        broadcast => \&broadcast,
        crons   => \&crons,
        cron    => \&cron,
        migrate => \&migrate,
        reset   => \&reset,
        version => sub {
            print "punk-queue $VERSION (Punk::Queue $Punk::Queue::VERSION)\n";
            0;
        },
        help    => sub { usage(\*STDOUT); 0 },
    );
    my $run = $commands{$cmd} or do {
        print STDERR "punk-queue: unknown command '$cmd'\n\n";
        usage(\*STDERR);
        return 2;
    };
    return $run->(@argv);
}

sub usage {
    my ($fh) = @_;
    print {$fh} <<'EOU';
Usage: punk-queue COMMAND [options]

Every command takes --dsn DSN or --app CLASS-OR-FILE to reach the queue;
inspection never requires the app. Read commands take --json.

Commands:
  worker    run a supervised worker pool
              -q, --queue NAME     (repeatable, or comma separated)
              -t, --task NAME      restrict to these tasks (repeatable)
              -j, --jobs N         child processes (default 1)
              --interval SECS      idle claim interval (default 0.5)
              --max-jobs N         recycle a child after N jobs
              --graceful-timeout S wait this long on shutdown (default 60)
              --fail-fast          exit 1 if children keep dying at boot
              --no-scheduler       do not run the cron scheduler in this pool
  enqueue   add a job: punk-queue enqueue TASK [ARGS...]
              -q, --queue NAME  -p, --priority N  --delay SECS
              --attempts N  --expire SECS  --timeout SECS
              --parent ID (repeatable)  --lax  --unique KEY
              --json '[...]' (whole args array)
  job       one job: punk-queue job ID [ID...]
              --retry [--delay S --priority N --queue NAME]
              --remove   --fail REASON   --json
              --log      print the job's log (lifecycle + $job->log lines)
  jobs      list jobs
              --state S --queue Q --task T --worker W
              --limit N --offset N --json
  workers   list workers            [--role R --json]
  stats     queue statistics        [--json]
  repair    fix what crashes leave  [--deep: recompute dependency counters]
  locks     list locks              [--name N --json]
  lock      acquire: punk-queue lock NAME [--duration S --limit N --owner ID]
  unlock    release: punk-queue unlock NAME [--owner ID]
  broadcast send a command to workers: punk-queue broadcast CMD [ARGS]
              [--worker ID (repeatable; default all)]
  crons     list recurring jobs      [--json]
  cron      one cron:
              run NAME       enqueue its job now (schedule untouched)
              enable NAME    resume firing (next_run recomputed from now)
              disable NAME   stop firing (history and row kept)
              next EXPR      print the next occurrences [--tz TZ --count N]
                             (needs no database)
  migrate   apply schema migrations  [--check: exit 1 if behind]
  reset     empty the queue          (requires --yes)
  version   print the version
  help      this text
EOU
    return 0;
}

# ---- shared plumbing --------------------------------------------------------

sub _getopt {
    my ($argv, @spec) = @_;
    my $p = Getopt::Long::Parser->new(
        config => [qw(no_ignore_case bundling pass_through)]);
    return $p->getoptionsfromarray($argv, @spec);
}

# The queue, from --dsn or --app. --app takes a class name (which must
# provide ->queue) or a file (which must return a Punk::Queue) - the file
# form is how a worker gets its task registry before phase 8 wires the
# Punk plugin.
sub _queue {
    my ($opt) = @_;
    if (defined $opt->{app} && length $opt->{app}) {
        my $app = $opt->{app};
        if (-f $app) {
            my $q = do $app;
            if (!(ref $q && eval { $q->isa('Punk::Queue') })) {
                print STDERR defined $q
                    ? "punk-queue: $app did not return a Punk::Queue\n"
                    : "punk-queue: could not load $app: " . ($@ || $!) . "\n";
                return undef;
            }
            return $q;
        }
        (my $file = "$app.pm") =~ s{::}{/}g;
        my $loaded = eval { require $file; 1 };
        if (!$loaded) {
            print STDERR "punk-queue: could not load $app: $@";
            return undef;
        }
        if (!$app->can('queue')) {
            print STDERR "punk-queue: $app has no queue() method\n";
            return undef;
        }
        return $app->queue;
    }
    if (defined $opt->{dsn} && length $opt->{dsn}) {
        my $q = eval { Punk::Queue->new(dsn => $opt->{dsn}) };
        print STDERR "punk-queue: $@" if !$q;
        return $q;
    }
    print STDERR "punk-queue: need --dsn or --app\n";
    return undef;
}

sub _json {
    my ($data) = @_;
    require File::Raw::JSON;
    print File::Raw::JSON::file_json_encode($data, canonical => 1), "\n";
    return 0;
}

sub _epoch {
    my ($t) = @_;
    return '-' unless defined $t;
    my @lt = localtime int $t;
    return sprintf '%04d-%02d-%02d %02d:%02d:%02d',
        $lt[5] + 1900, $lt[4] + 1, @lt[3, 2, 1, 0];
}

sub _table {
    my ($cols, $rows) = @_;
    my @w = map { length } @$cols;
    for my $r (@$rows) {
        $w[$_] = length $r->[$_] > $w[$_] ? length $r->[$_] : $w[$_]
            for 0 .. $#$cols;
    }
    my $fmt = join('  ', map { "%-${_}s" } @w) . "\n";
    printf $fmt, @$cols;
    printf $fmt, @$_ for @$rows;
    return 0;
}

# ---- worker -----------------------------------------------------------------

sub worker {
    my (@argv) = @_;
    my %opt = (queue => [], task => []);
    _getopt(\@argv,
        'dsn=s'              => \$opt{dsn},
        'app=s'              => \$opt{app},
        'queue|q=s@'         => $opt{queue},
        'task|t=s@'          => $opt{task},
        'jobs|j=i'           => \$opt{jobs},
        'interval=f'         => \$opt{interval},
        'max-jobs=i'         => \$opt{max_jobs},
        'graceful-timeout=f' => \$opt{graceful},
        'fail-fast'          => \$opt{fail_fast},
        'no-scheduler'       => \$opt{no_scheduler},
    ) or return 2;

    my $q = _queue(\%opt) or return 2;
    my @queues = map { split /,/ } @{ $opt{queue} };
    my @tasks  = map { split /,/ } @{ $opt{task} };

    my %wopts;
    $wopts{queues}   = \@queues        if @queues;
    $wopts{tasks}    = \@tasks         if @tasks;
    $wopts{interval} = $opt{interval}  if defined $opt{interval};
    $wopts{max_jobs} = $opt{max_jobs}  if defined $opt{max_jobs};

    # The oneshot seam runs a single in-process worker - no fork, no
    # supervisor - which is how t/ drives a real worker without hanging.
    if ($ENV{PUNK_QUEUE_ONESHOT}) {
        my $n = $q->worker(%wopts)->run;
        return $n ? 0 : 1;
    }

    return Punk::Queue::Supervisor->run($q,
        workers          => $opt{jobs} // 1,
        graceful_timeout => $opt{graceful} // 60,
        fail_fast        => $opt{fail_fast} ? 1 : 0,
        scheduler        => $opt{no_scheduler} ? 0 : 1,
        %wopts,
    );
}

# ---- enqueue ----------------------------------------------------------------

# Bare args are JSON when they parse as JSON, strings otherwise; --json
# passes the whole array unambiguously. Decoded through frj, so the CLI
# and the app agree byte for byte on what the task receives.
sub _parse_arg {
    my ($raw) = @_;
    require File::Raw::JSON;
    my $v = eval { File::Raw::JSON::file_json_decode($raw) };
    return $@ ? $raw : $v;
}

sub enqueue {
    my (@argv) = @_;
    my %opt = (parent => []);
    _getopt(\@argv,
        'dsn=s'        => \$opt{dsn},
        'app=s'        => \$opt{app},
        'queue|q=s'    => \$opt{queue},
        'priority|p=i' => \$opt{priority},
        'delay=f'      => \$opt{delay},
        'attempts=i'   => \$opt{attempts},
        'expire=f'     => \$opt{expire},
        'timeout=f'    => \$opt{timeout},
        'parent=i@'    => $opt{parent},
        'lax'          => \$opt{lax},
        'unique=s'     => \$opt{unique},
        'json=s'       => \$opt{json},
    ) or return 2;

    my $task = shift @argv;
    if (!defined $task) {
        print STDERR "punk-queue: enqueue needs a task name\n";
        return 2;
    }
    my $q = _queue(\%opt) or return 2;

    my $args;
    if (defined $opt{json}) {
        require File::Raw::JSON;
        $args = eval { File::Raw::JSON::file_json_decode($opt{json}) };
        if ($@ || ref $args ne 'ARRAY') {
            print STDERR "punk-queue: --json must be a JSON array\n";
            return 2;
        }
    }
    else {
        $args = [ map { _parse_arg($_) } @argv ];
    }

    my %eopts;
    $eopts{$_} = $opt{$_}
        for grep { defined $opt{$_} }
            qw(queue priority delay attempts expire timeout unique);
    $eopts{lax}     = 1              if $opt{lax};
    $eopts{parents} = $opt{parent}   if @{ $opt{parent} };

    my $id = eval { $q->enqueue($task, $args, %eopts) };
    if (!$id) { print STDERR "punk-queue: $@"; return 1; }
    print "$id\n";
    return 0;
}

# ---- job (read and write) ---------------------------------------------------

sub job {
    my (@argv) = @_;
    my %opt;
    _getopt(\@argv,
        'dsn=s'      => \$opt{dsn},
        'app=s'      => \$opt{app},
        'retry'      => \$opt{retry},
        'remove'     => \$opt{remove},
        'fail=s'     => \$opt{fail},
        'delay=f'    => \$opt{delay},
        'priority=i' => \$opt{priority},
        'queue=s'    => \$opt{queue},
        'log'        => \$opt{log},
        'json'       => \$opt{json},
    ) or return 2;

    my @ids = grep { /^\d+$/ } @argv;
    if (!@ids) {
        print STDERR "punk-queue: job needs at least one numeric id\n";
        return 2;
    }
    my $writes = grep { defined } @opt{qw(retry remove fail)};
    if ($writes > 1) {
        print STDERR "punk-queue: --retry, --remove and --fail are exclusive\n";
        return 2;
    }
    my $q = _queue(\%opt) or return 2;

    my $rc = 0;
    for my $id (@ids) {
        my $info = $q->job_info($id);
        if (!$info) {
            print STDERR "punk-queue: no job $id\n";
            $rc = 1;
            next;
        }

        if ($opt{retry}) {
            my %r;
            $r{$_} = $opt{$_}
                for grep { defined $opt{$_} } qw(delay priority queue);
            my $ok = $q->retry_job($id, $info->{retries}, \%r);
            print $ok ? "job $id retried\n" : "job $id not retried\n";
            $rc = 1 unless $ok;
        }
        elsif ($opt{remove}) {
            my $ok = $q->remove_job($id);
            print $ok ? "job $id removed\n"
                      : "job $id not removed (active? retry it first)\n";
            $rc = 1 unless $ok;
        }
        elsif (defined $opt{fail}) {
            my $ok = $q->fail_job($id, $info->{retries}, $opt{fail});
            print $ok ? "job $id failed\n"
                      : "job $id not failed (not active)\n";
            $rc = 1 unless $ok;
        }
        elsif ($opt{log}) {
            my $log = $q->job_log($id);
            if ($opt{json}) { _json($log) }
            elsif (!@$log) { print "job $id has no log lines\n" }
            else {
                printf "%s  %-5s  %s\n",
                    _epoch($_->{created}), $_->{level}, $_->{message}
                    for @$log;
            }
        }
        elsif ($opt{json}) {
            _json($info);
        }
        else {
            for my $k (qw(id task queue state priority retries attempts)) {
                printf "%-9s %s\n", $k, $info->{$k} // '-';
            }
            printf "%-9s %s\n", $_, _epoch($info->{$_})
                for qw(created delayed started finished);
            require File::Raw::JSON;
            printf "%-9s %s\n", 'args',
                File::Raw::JSON::file_json_encode($info->{args});
            printf "%-9s %s\n", 'result',
                defined $info->{result}
                    ? File::Raw::JSON::file_json_encode($info->{result}) : '-';
            printf "%-9s %s\n", 'notes',
                File::Raw::JSON::file_json_encode($info->{notes});
        }
    }
    return $rc;
}

# ---- lists and stats --------------------------------------------------------

sub jobs {
    my (@argv) = @_;
    my %opt;
    _getopt(\@argv,
        'dsn=s'    => \$opt{dsn},
        'app=s'    => \$opt{app},
        'state=s'  => \$opt{state},
        'queue=s'  => \$opt{queue},
        'task=s'   => \$opt{task},
        'worker=i' => \$opt{worker},
        'limit=i'  => \$opt{limit},
        'offset=i' => \$opt{offset},
        'json'     => \$opt{json},
    ) or return 2;
    my $q = _queue(\%opt) or return 2;

    my %f;
    $f{$_} = $opt{$_}
        for grep { defined $opt{$_} } qw(state queue task worker);
    my $r = $q->list_jobs($opt{offset} // 0, $opt{limit} // 0, \%f);

    return _json($r) if $opt{json};
    print "total: $r->{total}\n";
    return _table(
        [qw(id task queue state pri try created)],
        [ map { [ @{$_}{qw(id task queue state priority)},
                  "$_->{retries}/$_->{attempts}",
                  _epoch($_->{created}) ] } @{ $r->{jobs} } ]);
}

sub workers {
    my (@argv) = @_;
    my %opt;
    _getopt(\@argv,
        'dsn=s'  => \$opt{dsn},
        'app=s'  => \$opt{app},
        'role=s' => \$opt{role},
        'json'   => \$opt{json},
    ) or return 2;
    my $q = _queue(\%opt) or return 2;

    my $r = $q->list_workers(0, 0,
        defined $opt{role} ? { role => $opt{role} } : undef);
    return _json($r) if $opt{json};
    print "total: $r->{total}\n";
    return _table(
        [qw(id host pid role queues notified)],
        [ map { [ @{$_}{qw(id host pid role)},
                  join(',', @{ $_->{queues} || [] }),
                  _epoch($_->{notified}) ] } @{ $r->{workers} } ]);
}

sub stats {
    my (@argv) = @_;
    my %opt;
    _getopt(\@argv,
        'dsn=s' => \$opt{dsn},
        'app=s' => \$opt{app},
        'json'  => \$opt{json},
    ) or return 2;
    my $q = _queue(\%opt) or return 2;

    my $s = $q->stats;
    return _json($s) if $opt{json};
    printf "%-15s %s\n", $_, $s->{$_}
        for qw(inactive_jobs active_jobs failed_jobs finished_jobs
               delayed_jobs total_jobs workers schema_version);
    return 0;
}

# ---- repair, locks, broadcast -----------------------------------------------

sub repair {
    my (@argv) = @_;
    my %opt;
    _getopt(\@argv,
        'dsn=s' => \$opt{dsn},
        'app=s' => \$opt{app},
        'deep'  => \$opt{deep},
        'json'  => \$opt{json},
    ) or return 2;
    my $q = _queue(\%opt) or return 2;

    my $r = $q->repair($opt{deep} ? (deep => 1) : ());
    return _json($r) if $opt{json};
    printf "%-20s %d\n", $_, $r->{$_} for sort keys %$r;
    return 0;
}

sub locks {
    my (@argv) = @_;
    my %opt;
    _getopt(\@argv,
        'dsn=s'  => \$opt{dsn},
        'app=s'  => \$opt{app},
        'name=s' => \$opt{name},
        'json'   => \$opt{json},
    ) or return 2;
    my $q = _queue(\%opt) or return 2;

    my $r = $q->list_locks(0, 0,
        defined $opt{name} ? { name => $opt{name} } : undef);
    return _json($r) if $opt{json};
    print "total: $r->{total}\n";
    return _table(
        [qw(id name owner expires)],
        [ map { [ $_->{id}, $_->{name}, $_->{owner} // '-',
                  _epoch($_->{expires}) ] } @{ $r->{locks} } ]);
}

sub lock {
    my (@argv) = @_;
    my %opt;
    _getopt(\@argv,
        'dsn=s'      => \$opt{dsn},
        'app=s'      => \$opt{app},
        'duration=f' => \$opt{duration},
        'limit=i'    => \$opt{limit},
        'owner=i'    => \$opt{owner},
    ) or return 2;
    my $name = shift @argv;
    if (!defined $name) {
        print STDERR "punk-queue: lock needs a name\n";
        return 2;
    }
    my $q = _queue(\%opt) or return 2;
    my $got = $q->lock($name, $opt{duration} // 60,
        (defined $opt{limit} ? (limit => $opt{limit}) : ()),
        (defined $opt{owner} ? (owner => $opt{owner}) : ()));
    print $got ? "acquired\n" : "held\n";
    return $got ? 0 : 1;
}

sub unlock {
    my (@argv) = @_;
    my %opt;
    _getopt(\@argv,
        'dsn=s'   => \$opt{dsn},
        'app=s'   => \$opt{app},
        'owner=i' => \$opt{owner},
    ) or return 2;
    my $name = shift @argv;
    if (!defined $name) {
        print STDERR "punk-queue: unlock needs a name\n";
        return 2;
    }
    my $q = _queue(\%opt) or return 2;
    my $ok = $q->unlock($name,
                        defined $opt{owner} ? $opt{owner} : ());
    print $ok ? "released\n" : "not held\n";
    return $ok ? 0 : 1;
}

sub broadcast {
    my (@argv) = @_;
    my %opt = (worker => []);
    _getopt(\@argv,
        'dsn=s'      => \$opt{dsn},
        'app=s'      => \$opt{app},
        'worker=i@'  => $opt{worker},
    ) or return 2;
    my $cmd = shift @argv;
    if (!defined $cmd) {
        print STDERR "punk-queue: broadcast needs a command\n";
        return 2;
    }
    my $q = _queue(\%opt) or return 2;
    my $n = $q->broadcast($cmd, [@argv],
                          @{ $opt{worker} } ? $opt{worker} : ());
    print "sent to $n worker(s)\n";
    return $n ? 0 : 1;
}

# ---- cron -------------------------------------------------------------------

sub crons {
    my (@argv) = @_;
    my %opt;
    _getopt(\@argv,
        'dsn=s' => \$opt{dsn},
        'app=s' => \$opt{app},
        'json'  => \$opt{json},
    ) or return 2;
    my $q = _queue(\%opt) or return 2;

    my $r = $q->list_crons;
    return _json($r) if $opt{json};
    print "total: $r->{total}\n";
    return _table(
        [qw(name expr tz enabled next_run last_run task)],
        [ map { [ $_->{name}, $_->{expr}, $_->{tz},
                  $_->{enabled} ? 'yes' : 'no',
                  _epoch($_->{next_run}), _epoch($_->{last_run}),
                  $_->{task} ] } @{ $r->{crons} } ]);
}

sub cron {
    my (@argv) = @_;
    my $verb = shift @argv;
    if (!defined $verb) {
        print STDERR "punk-queue: cron needs run|enable|disable|next\n";
        return 2;
    }

    # `cron next` is pure arithmetic - no database, no --dsn
    if ($verb eq 'next') {
        my %opt;
        _getopt(\@argv,
            'tz=s'    => \$opt{tz},
            'count=i' => \$opt{count},
        ) or return 2;
        my $expr = shift @argv;
        if (!defined $expr) {
            print STDERR "punk-queue: cron next needs an expression\n";
            return 2;
        }
        my $err;
        {
            local $@;
            eval { Punk::Queue::Cron->check($expr, $opt{tz}); 1 }
                or $err = $@;
        }
        if (defined $err) {
            print STDERR "punk-queue: $err";
            return 1;
        }
        my $from = time;
        for (1 .. ($opt{count} // 10)) {
            my $at = Punk::Queue::Cron->next_after($expr, $from, $opt{tz});
            last unless defined $at;
            print _epoch($at), "\n";
            $from = $at;
        }
        return 0;
    }

    if ($verb ne 'run' && $verb ne 'enable' && $verb ne 'disable') {
        print STDERR "punk-queue: unknown cron action '$verb'\n";
        return 2;
    }

    my %opt;
    _getopt(\@argv,
        'dsn=s' => \$opt{dsn},
        'app=s' => \$opt{app},
    ) or return 2;
    my $name = shift @argv;
    if (!defined $name) {
        print STDERR "punk-queue: cron $verb needs a name\n";
        return 2;
    }
    my $q = _queue(\%opt) or return 2;
    my $info = $q->cron_info($name);
    if (!$info) {
        print STDERR "punk-queue: no cron named '$name'\n";
        return 1;
    }

    # fire now, schedule untouched - the CLI twin of the UI's run button
    if ($verb eq 'run') {
        my $id = $q->enqueue($info->{task}, $info->{args},
                             queue    => $info->{queue},
                             priority => $info->{priority},
                             attempts => $info->{attempts});
        print "enqueued job $id\n";
        return 0;
    }

    $q->enable_cron($name, $verb eq 'enable' ? 1 : 0);
    print $verb eq 'enable' ? "enabled\n" : "disabled\n";
    return 0;
}

# ---- schema -----------------------------------------------------------------

sub migrate {
    my (@argv) = @_;
    my %opt;
    _getopt(\@argv,
        'dsn=s' => \$opt{dsn},
        'app=s' => \$opt{app},
        'check' => \$opt{check},
    ) or return 2;
    my $q = _queue(\%opt) or return 2;

    if ($opt{check}) {
        my ($have, $want) =
            ($q->schema_version, $q->backend->latest_version);
        print "schema $have, latest $want\n";
        return $have >= $want ? 0 : 1;
    }
    my $v = $q->migrate;
    print "schema at $v\n";
    return 0;
}

sub reset {
    my (@argv) = @_;
    my %opt;
    _getopt(\@argv,
        'dsn=s' => \$opt{dsn},
        'app=s' => \$opt{app},
        'yes'   => \$opt{yes},
    ) or return 2;
    if (!$opt{yes}) {
        print STDERR
            "punk-queue: reset deletes every job, worker, lock and cron; "
          . "pass --yes to mean it\n";
        return 2;
    }
    my $q = _queue(\%opt) or return 2;
    $q->reset;
    print "reset\n";
    return 0;
}

1;

__END__

=head1 NAME

Punk::Queue::Command - the subcommands behind punk-queue

=head1 SYNOPSIS

    punk-queue worker -q default,mail -j 4 --app MyApp
    punk-queue jobs --state failed --json --dsn dbi:SQLite:dbname=q.db

=head1 DESCRIPTION

Argument handling and dispatch for the C<punk-queue> command line tool.
Each subcommand is a function returning an exit code: 0 fine, 1 the thing
you asked about is wrong, 2 the command was used wrongly. The work happens
through the ordinary L<Punk::Queue> API, so everything here is testable
without spawning a process.

The governing rule: anything the admin UI can do, the CLI can do, and
every subcommand works from C<--dsn> alone. Inspection never requires
loading the application.

=head1 FUNCTIONS

=head2 main(@ARGV)

Dispatch. C<bin/punk-queue> calls this and exits with its return value.

=head2 worker / enqueue / job / jobs / workers / stats / migrate / reset

One function per subcommand, each documented in C<punk-queue help>.

=head2 commands

The subcommand names.

=head2 usage($fh)

Print the help text.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
