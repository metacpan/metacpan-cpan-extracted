package Punk::Command;

use 5.010;
use strict;
use warnings;
use Carp ();
use Cwd ();
use File::Spec ();
use File::Basename ();

our $VERSION = '0.02';

# The subcommands behind `punk`, other than `new` (which is Punk::Generate).
# Each returns an exit code - 0 fine, 1 something is wrong with the
# application or its environment, 2 the command was used wrongly - and prints
# its own report, so bin/punk stays a dispatcher.
#
# A compiled-at-boot framework is opaque from the outside: everything is
# resolved and frozen inside one coderef at to_app. These commands exist to
# open that up - what the router actually holds, what the spec actually maps
# to, what the configuration actually resolved to, and which C ABIs are
# actually in play.

our @COMMANDS = qw(routes api doctor config console dev);

# ---- public ------------------------------------------------------------------

sub commands { @COMMANDS }

# ---- punk routes -------------------------------------------------------------

# The compiled routing table. Targets come back from the coderef through B,
# not from the declaration, so what is printed is what the route actually
# resolved to - which is the question you have when a route misbehaves.
sub routes {
    my (%opt) = @_;
    my $app = _load_app($opt{dir}) or return 1;

    my @rows;
    my $recs = eval { $app->{registrar}{router}->records } || [];
    for my $rec (@$recs) {
        push @rows, {
            method => $rec->{method} // '?',
            path   => $rec->{path}   // '?',
            target => _code_name($rec->{code}),
            guards => scalar @{ $rec->{guards} || [] },
            kind   => 'route',
        };
    }

    # API operations live in their mount, not the router: the spec is the
    # routing table for everything under the mount's prefix.
    for my $m (@{ $app->{registrar}{api_mounts} || [] }) {
        my $prefix = $m->{prefix} // '';
        my $api    = $m->{api} or next;
        my $ops    = eval { $api->operations } || [];
        my $by_id  = ref $m->{ops} eq 'HASH' ? $m->{ops} : {};
        for my $op (sort { $a->{path} cmp $b->{path}
                        || $a->{method} cmp $b->{method} } @$ops) {
            my $rec  = $by_id->{ $op->{operationId} };
            my $code = ref $rec eq 'HASH' ? $rec->{code} : undef;
            push @rows, {
                method => uc $op->{method},
                path   => $prefix . $op->{path},
                target => (ref $code eq 'CODE'
                            ? _code_name($code) : $op->{operationId}),
                guards => (ref $rec eq 'HASH'
                            ? scalar @{ $rec->{guards} || [] } : 0),
                kind   => 'api',
            };
        }
    }

    for my $w (@{ $app->{registrar}{ws_routes} || [] }) {
        push @rows, {
            method => 'WS',
            path   => $w->{path} // '?',
            target => (ref $w->{target} ? _code_name($w->{target})
                                        : ($w->{target} // '?')),
            guards => scalar @{ $w->{guards} || [] },
            kind   => 'ws',
        };
    }

    for my $m (@{ $app->{registrar}{mounts} || [] }) {
        push @rows, {
            method => 'ANY',
            path   => ($m->{prefix} // '') . '/*',
            target => $m->{dir}    ? "static $m->{dir}"
                    : $m->{md_dir} ? "markdown $m->{md_dir}"
                    :                'mounted psgi app',
            guards => 0,
            kind   => $m->{md_dir} ? 'markdown' : 'mount',
        };
    }

    unless (@rows) {
        print "no routes\n";
        return 0;
    }

    @rows = sort { $a->{path} cmp $b->{path} || $a->{method} cmp $b->{method} }
            @rows if $opt{sort};

    my $w_m = _widest('method', \@rows, 6);
    my $w_p = _widest('path',   \@rows, 4);
    printf "%-*s  %-*s  %s\n", $w_m, 'METHOD', $w_p, 'PATH', 'TARGET';
    for my $r (@rows) {
        printf "%-*s  %-*s  %s%s\n", $w_m, $r->{method}, $w_p, $r->{path},
            $r->{target},
            $r->{guards} ? "  [$r->{guards} guard"
                         . ($r->{guards} > 1 ? 's' : '') . ']' : '';
    }
    printf "\n%d route%s\n", scalar @rows, @rows == 1 ? '' : 's';
    return 0;
}

# ---- punk doctor -------------------------------------------------------------

# Punk reaches four other distributions through C ABI tables resolved at
# runtime, each gated on the version it was compiled against. When those drift
# the symptom is a croak on a request path, a long way from the cause; this
# reports the whole picture at once.
sub doctor {
    my (%opt) = @_;
    my $bad = 0;

    print "punk doctor\n\n";

    require Punk;
    _line('Punk', $Punk::VERSION, 'ok');
    _line('perl', sprintf('%vd', $^V), 'ok');

    print "\nprerequisites\n";
    for my $mod (qw(Open::API Template::Stencil File::Raw::JSON
                    JSON::Schema::Fast YAML::XS Hyperman)) {
        my $v = _module_version($mod);
        $bad++ unless defined $v;
        _line($mod, $v // '-', defined $v ? 'ok' : 'MISSING');
    }

    print "\noptional\n";
    for my $mod (qw(DBI Future Open::API::UI Plack)) {
        my $v = _module_version($mod);
        _line($mod, $v // '-', defined $v ? 'ok' : 'not installed');
    }
    {   # a database backend is only useful with a driver behind it
        my @drv = eval { require DBI; DBI->available_drivers } ;
        _line('DBD drivers', (@drv ? join(' ', sort @drv) : '-'),
              @drv ? 'ok' : 'none') if @drv || !$@;
    }

    # The part that cannot be read off a version number: whether each table
    # resolved, and at which version.
    print "\nC ABIs\n";
    for my $abi (_abi_report()) {
        $bad++ if $abi->{state} ne 'ok';
        _line($abi->{name}, $abi->{detail}, $abi->{state});
    }

    if (my $app = _load_app($opt{dir}, quiet => 1)) {
        print "\napplication\n";
        _line('class', $app->{class}, 'ok');
        _line('root',  $app->{root},  'ok');
        my $n = eval { scalar @{ $app->{registrar}{router}->records } } || 0;
        _line('routes', $n, $n ? 'ok' : 'none');
        if (my $cfg = $app->{registrar}{config}) {
            _line('config', join(' ', @{ $cfg->files }), 'ok');
            my $s = eval { $cfg->secret_paths } || [];
            _line('secrets', (@$s ? scalar(@$s) . ' resolved' : 'none'), 'ok');
        }
    }

    print "\n", $bad ? "$bad problem" . ($bad > 1 ? 's' : '') . " found\n"
                     : "no problems found\n";
    return $bad ? 1 : 0;
}

# ---- punk config check -------------------------------------------------------

# Resolving configuration is fatal by design - a missing secret should stop a
# deployment, not produce an empty password. That makes it a thing worth
# testing before the deployment: this walks every layer for every secret
# reference and reports all of them, rather than dying on the first.
sub config_check {
    my (%opt) = @_;
    my $root = $opt{root} || _find_root($opt{dir}) or do {
        print STDERR "punk config: no application found "
            . "(looked for app.psgi upwards from "
            . ($opt{dir} || Cwd::getcwd()) . ")\n";
        return 2;
    };
    my $file = $opt{file} || File::Spec->catfile($root, 'config', 'punk.yml');
    my $env  = $opt{env} || $ENV{PUNK_ENV} || 'development';

    unless (-f $file) {
        print STDERR "punk config: no such file: $file\n";
        return 2;
    }

    printf "config  %s\nenv     %s\n\n", $file, $env;

    my @layers = _layer_files($file, $env);
    my @present = grep { -f $_->[1] } @layers;
    print "layers\n";
    for my $l (@layers) {
        _line($l->[0], $l->[1], -f $l->[1] ? 'ok' : 'absent');
    }

    unless (@present) {
        print STDERR "\nno layer files exist\n";
        return 1;
    }

    # Every secret reference in every layer, resolved independently so one
    # failure does not hide the rest.
    my @refs;
    for my $l (@present) {
        my $doc = eval { _yaml_file($l->[1]) };
        if ($@) {
            print "\n", _fmt('', $l->[1], 'UNPARSEABLE'), "  $@";
            return 1;
        }
        _walk_secrets($doc, '', sub { push @refs, { %{ $_[0] }, layer => $l->[1] } });
    }

    my $bad = 0;
    if (@refs) {
        print "\nsecrets\n";
        for my $r (@refs) {
            my ($ok, $detail) = _try_resolver($r->{kind}, $r->{value});
            $bad++ unless $ok;
            _line($r->{path}, "$r->{kind}: $detail", $ok ? 'ok' : 'FAILED');
        }
    }
    else {
        print "\nno secret references\n";
    }

    # Then the authoritative pass, which also applies the guardrail.
    print "\nload\n";
    require Punk::Config;
    my $cfg = eval {
        local $ENV{PUNK_ENV} = $env;
        Punk::Config->load(file => $file, env => $env,
                           ($opt{secrets} ? (secrets => $opt{secrets}) : ()));
    };
    if (!$cfg) {
        my $err = $@ || 'failed';
        $err =~ s/ at \S+ line \d+\.?\s*\z//;
        _line('Punk::Config->load', $err, 'FAILED');
        return 1;
    }
    _line('Punk::Config->load', 'ok', 'ok');

    if ($opt{dump}) {
        print "\nresolved (secrets redacted)\n";
        require Data::Dumper;
        my $d = Data::Dumper->new([ $cfg->config ]);
        $d->Sortkeys(1)->Indent(1)->Terse(1);
        print $d->Dump;
    }

    print "\n", $bad ? "$bad secret" . ($bad > 1 ? 's' : '')
                     . " could not be resolved\n" : "configuration is sound\n";
    return $bad ? 1 : 0;
}

# ---- punk api sync -----------------------------------------------------------

# A spec-first application whose spec has moved on. Adds a stub for every
# operation the document declares and the controllers do not implement, and
# never touches one that is already there - so this is the command that makes
# `punk new --api` a workflow rather than a one-shot.
sub api_sync {
    my (%opt) = @_;
    my $root = $opt{root} || _find_root($opt{dir}) or do {
        print STDERR "punk api: no application found\n";
        return 2;
    };
    my $class = _class_of($root) or do {
        print STDERR "punk api: cannot work out the application class in $root\n";
        return 2;
    };
    my $spec = $opt{spec} || File::Spec->catfile($root, 'openapi.json');
    unless (-f $spec) {
        print STDERR "punk api: no such spec: $spec\n";
        return 2;
    }

    require Punk::Generate;
    my $plan = eval { Punk::Generate->api_plan($spec) } or do {
        my $err = $@; $err =~ s/ at \S+ line \d+\.?\s*\z//;
        print STDERR "punk api: $err\n";
        return 1;
    };

    (my $path = $class) =~ s{::}{/}g;
    my $ctrl_dir = File::Spec->catdir($root, 'lib', $path, 'Controller', 'API');
    # the checker class holds security checkers, not operations - counting its
    # subs would make every checker look like an operation the spec dropped
    my $auth = $plan->{auth_class};
    my %implemented = _implemented_ops($ctrl_dir,
        ($auth ? (skip => qr/\A\Q$auth\E\.pm\z/) : ()));

    my (@added, @created, @orphans);
    my %declared;

    for my $group (@{ $plan->{groups} }) {
        my @new = grep { !$implemented{ $_->{id} } } @{ $group->{ops} };
        $declared{ $_->{id} } = 1 for @{ $group->{ops} };
        next unless @new;

        # Where a new operation's siblings already live wins over where a
        # fresh generation would have put it. Adding a tag to a spec changes
        # how untagged operations group, and a sync should not scatter an
        # operation away from the others on its own path because of that.
        my $file = File::Spec->catfile($ctrl_dir, "$group->{group}.pm");
        # Only for operations that fell through to Default - a tag the author
        # wrote is a placement decision, and it outranks any guess made here.
        if (!-f $file && !length($group->{group_label} // '')) {
            my %by_home;
            for my $op (@new) {
                my ($seg) = grep { length } split m{/}, $op->{path};
                my $home  = Punk::Generate->ident($seg // '');
                my $f     = length $home
                          ? File::Spec->catfile($ctrl_dir, "$home.pm") : '';
                push @{ $by_home{ (length $f && -f $f) ? $f : $file } }, $op;
            }
            if (keys %by_home > 1 || !exists $by_home{$file}) {
                for my $f (sort keys %by_home) {
                    my $ops = $by_home{$f};
                    my $base = File::Basename::basename($f);
                    if (-f $f) {
                        _insert_stubs($f, $ops, $opt{dry_run});
                    }
                    else {
                        Punk::Generate->write_skel('controller_api.tmpl', $f,
                            { name => $class, path => $path, api => 1,
                              %$group, ops => $ops }) unless $opt{dry_run};
                        my $stem = $base;
                        $stem =~ s/\.pm\z//;   # s///r is 5.14
                        push @created, [ $stem, scalar @$ops ];
                    }
                    push @added, map { [ $_->{id}, $base ] } @$ops;
                }
                next;
            }
        }
        if (-f $file) {
            _insert_stubs($file, \@new, $opt{dry_run});
            push @added, map { [ $_->{id}, "$group->{group}.pm" ] } @new;
        }
        else {
            unless ($opt{dry_run}) {
                Punk::Generate->write_skel('controller_api.tmpl', $file,
                    { name => $class, path => $path, api => 1,
                      %$group, ops => \@new });
            }
            push @created, [ $group->{group}, scalar @new ];
            push @added, map { [ $_->{id}, "$group->{group}.pm" ] } @new;
        }
    }

    # Checkers for schemes the spec has started requiring since.
    my $auth_file;
    if (@{ $plan->{schemes} }) {
        $auth_file = File::Spec->catfile($ctrl_dir, "$plan->{auth_class}.pm");
        unless (-f $auth_file) {
            unless ($opt{dry_run}) {
                Punk::Generate->write_skel('controller_auth.tmpl', $auth_file,
                    { name => $class, path => $path, api => 1,
                      auth_class => $plan->{auth_class},
                      schemes => $plan->{schemes} });
            }
            push @created, [ $plan->{auth_class},
                             scalar @{ $plan->{schemes} } ];
        }
    }

    @orphans = sort grep { !$declared{$_} } keys %implemented;

    my $pre = $opt{dry_run} ? 'would add' : 'added';
    if (@added) {
        printf "%s %d stub%s\n", $pre, scalar @added, @added == 1 ? '' : 's';
        printf "  %-28s %s\n", $_->[0], $_->[1] for @added;
    }
    else {
        print "every operation in the spec is implemented\n";
    }
    if (@created) {
        printf "\n%s %d file%s\n", ($opt{dry_run} ? 'would create' : 'created'),
            scalar @created, @created == 1 ? '' : 's';
        printf "  %s.pm (%d)\n", @$_ for @created;
    }
    if (@orphans) {
        # Reported, never removed: a sub the spec no longer declares may still
        # be wanted, and deleting someone's code is not this command's job.
        printf "\n%d method%s with no operation in the spec (left alone)\n",
            scalar @orphans, @orphans == 1 ? '' : 's';
        print "  $_\n" for @orphans;
    }
    if ($auth_file && -f $auth_file && @{ $plan->{schemes} }) {
        my %have = _implemented_ops($ctrl_dir,
            only => qr/\A\Q$plan->{auth_class}\E\.pm\z/);
        my @miss = grep { !$have{ $_->{method} } } @{ $plan->{schemes} };
        printf "\n%d security checker%s missing from %s.pm: %s\n",
            scalar @miss, @miss == 1 ? '' : 's', $plan->{auth_class},
            join(', ', map { $_->{method} } @miss) if @miss;
    }
    return 0;
}

# ---- punk console ------------------------------------------------------------

sub console {
    my (%opt) = @_;
    my $app = _load_app($opt{dir}) or return 1;

    my $class = $app->{class};
    print "punk console - $class\n"
        . "  \$app   the Punk::App registrar\n"
        . "  \$psgi  the compiled PSGI coderef\n"
        . "  \$c     a throwaway context (\$c->model, \$c->render, ...)\n"
        . "  ctrl-d to leave\n\n";

    # Term::ReadLine::Stub reads nothing from a pipe, so it is for terminals
    # only; falling back to STDIN keeps the console scriptable.
    my $tty  = -t STDIN;
    my $term = $tty ? eval { require Term::ReadLine;
                             Term::ReadLine->new('punk') } : undef;

    # Named so the eval below can see them by name rather than by closure.
    our $app_  = $app->{registrar};
    our $psgi_ = $app->{psgi};
    our $ctx_  = _console_context($app);

    while (1) {
        my $line = $term ? $term->readline('punk> ') : do {
            print 'punk> ' if $tty;
            my $l = <STDIN>;
            $l;
        };
        last unless defined $line;
        chomp $line;
        next unless $line =~ /\S/;
        my @out = eval _console_wrap($line);
        if ($@) { print "!! $@"; next }
        next unless @out;
        require Data::Dumper;
        my $d = Data::Dumper->new(\@out);
        $d->Sortkeys(1)->Indent(1)->Terse(1);
        print $d->Dump;
    }
    print "\n";
    return 0;
}

# ---- punk dev ----------------------------------------------------------------

# The application compiles at boot, which is exactly why a dev server has to
# restart rather than reload: there is no live structure to patch. The server
# runs in a child, the parent watches for changes and replaces it.
sub dev {
    my (%opt) = @_;
    my $root = $opt{root} || _find_root($opt{dir}) or do {
        print STDERR "punk dev: no application found\n";
        return 2;
    };
    my $psgi = File::Spec->catfile($root, 'app.psgi');
    my $port = $opt{port} || 5000;
    my $host = $opt{host} || '127.0.0.1';

    unless (eval { require Hyperman; 1 }) {
        print STDERR "punk dev: Hyperman is not installed\n";
        return 1;
    }

    my @watch = grep { -d $_ } map { File::Spec->catdir($root, $_) }
                qw(lib config root/templates);
    printf "punk dev  http://%s:%d\n", $host, $port;
    printf "watching  %s\n\n", join(' ', map { _rel($root, $_) } @watch)
        if @watch && !$opt{no_reload};

    my $child;
    my $stop = 0;
    local $SIG{INT} = local $SIG{TERM} = sub {
        $stop = 1;
        kill 'TERM', $child if $child;
    };

    require POSIX;
    my %seen = $opt{no_reload} ? () : _mtimes(@watch);

    while (!$stop) {
        $child = fork();
        defined $child or die "punk dev: cannot fork: $!\n";
        unless ($child) {
            chdir $root or die "punk dev: cannot chdir to $root: $!\n";
            # app.psgi reads $0 to find lib/ and its own root, exactly as a
            # server loading the file would
            local $0 = $psgi;
            my $app = do $psgi;
            die($@ || $! || "punk dev: $psgi did not return an app\n")
                unless ref $app eq 'CODE';
            Hyperman->run(app => $app, host => $host, port => $port,
                          workers => 1);
            exit 0;
        }

        if ($opt{no_reload}) {
            waitpid $child, 0;
            last;
        }

        # Watch until something changes or the child gives up.
        my $exited = 0;
        while (!$stop) {
            select undef, undef, undef, 0.5;
            if (waitpid($child, POSIX::WNOHANG()) == $child) {
                $exited = 1;
                last;
            }
            my %now = _mtimes(@watch);
            next if _same(\%seen, \%now);
            my ($what) = grep { ($seen{$_} // 0) != ($now{$_} // 0) }
                         sort keys %now;
            printf "\n-- %s changed, restarting --\n", _rel($root, $what // '');
            %seen = %now;
            kill 'TERM', $child;
            waitpid $child, 0;
            last;
        }
        $child = 0 if $exited;
        next unless $exited && !$stop;

        # It died on its own - a compile error, most likely. Respinning
        # immediately would just spin; hold until the source changes, which
        # is when there is any reason to try again.
        print "\n-- the application exited; waiting for a change --\n";
        while (!$stop) {
            select undef, undef, undef, 0.5;
            my %now = _mtimes(@watch);
            next if _same(\%seen, \%now);
            my ($what) = grep { ($seen{$_} // 0) != ($now{$_} // 0) }
                         sort keys %now;
            printf "-- %s changed, restarting --\n", _rel($root, $what // '');
            %seen = %now;
            last;
        }
    }
    if ($child) {
        kill 'TERM', $child;
        waitpid $child, 0;
    }
    print "\n";
    return 0;
}

# ---- finding and loading an application --------------------------------------

# app.psgi is the marker: it is what a server is pointed at, so it is what
# identifies the root. Walk up from where the command was run.
sub _find_root {
    my ($dir) = @_;
    my $here = Cwd::abs_path($dir || Cwd::getcwd()) or return undef;
    for (1 .. 40) {
        return $here if -f File::Spec->catfile($here, 'app.psgi');
        my $up = Cwd::abs_path(File::Spec->catdir($here, File::Spec->updir));
        last if !$up || $up eq $here;
        $here = $up;
    }
    return undef;
}

# The application class, from the psgi's own `Class->to_app`.
sub _class_of {
    my ($root) = @_;
    my $psgi = File::Spec->catfile($root, 'app.psgi');
    open my $fh, '<', $psgi or return undef;
    local $/;
    my $src = <$fh>;
    close $fh;
    return $1 if $src =~ /([A-Za-z_][\w:]*)\s*->\s*to_app\b/;
    return $1 if $src =~ /^\s*use\s+([A-Za-z_][\w:]*)\s*;/m;
    return undef;
}

sub _load_app {
    my ($dir, %o) = @_;
    my $root = _find_root($dir);
    unless ($root) {
        print STDERR "punk: no application found (looked for app.psgi "
            . "upwards from " . ($dir || Cwd::getcwd()) . ")\n" unless $o{quiet};
        return undef;
    }
    my $class = _class_of($root);
    unless ($class) {
        print STDERR "punk: cannot work out the application class in $root\n"
            unless $o{quiet};
        return undef;
    }

    my $psgi_file = File::Spec->catfile($root, 'app.psgi');
    my $cwd = Cwd::getcwd();
    my $psgi = do {
        local $0 = $psgi_file;    # app.psgi finds lib/ and its root through it
        do $psgi_file;
    };
    chdir $cwd;
    unless (ref $psgi eq 'CODE') {
        my $err = $@ || $! || 'it returned no coderef';
        print STDERR "punk: $psgi_file did not load: $err\n" unless $o{quiet};
        return undef;
    }
    my $registrar = $class->can('punk_app') ? $class->punk_app : undef;
    unless ($registrar) {
        print STDERR "punk: $class is not a Punk application\n" unless $o{quiet};
        return undef;
    }
    return { root => $root, class => $class, psgi => $psgi,
             registrar => $registrar };
}

# ---- reporting helpers -------------------------------------------------------

sub _fmt {
    my ($name, $detail, $state) = @_;
    my $mark = $state eq 'ok' ? ' ' : $state =~ /^(?:absent|none|not installed)$/
             ? '-' : '!';
    return sprintf "%s %-26s %s%s", $mark, $name,
        (defined $detail ? $detail : ''),
        ($state eq 'ok' || $state =~ /^(?:absent|none|not installed)$/
            ? '' : "  <- $state");
}

sub _line { print _fmt(@_), "\n" }

sub _widest {
    my ($key, $rows, $min) = @_;
    my $w = $min;
    for (@$rows) { my $l = length($_->{$key} // ''); $w = $l if $l > $w }
    return $w;
}

sub _rel {
    my ($root, $path) = @_;
    return '' unless defined $path && length $path;
    my $r = File::Spec->abs2rel($path, $root);
    return $r =~ /^\.\./ ? $path : $r;
}

# The name behind a coderef: a target string resolves to a real named sub, so
# this reports where the request will actually land. Anonymous handlers get
# their file and line, which is the equivalent answer for them.
sub _code_name {
    my ($code) = @_;
    return '?' unless ref $code eq 'CODE';
    require B;
    my $cv = B::svref_2object($code);
    my $gv = eval { $cv->GV } or return 'sub {...}';
    my $name  = eval { $gv->NAME }  // '';
    my $stash = eval { $gv->STASH->NAME } // '';
    if ($name eq '__ANON__' || !length $name) {
        my $file = eval { $cv->FILE } // '';
        my $line = eval { $gv->LINE } // 0;
        $file = File::Basename::basename($file) if length $file;
        # a magic-CV closure (the static app, a docs route) reports the C file
        # it was created in, which tells a reader nothing useful
        return 'native handler' if $file =~ /\.h\z/;
        return length $file ? "sub {...} at $file:$line" : 'sub {...}';
    }
    return length $stash ? "${stash}::${name}" : $name;
}

sub _module_version {
    my ($mod) = @_;
    (my $file = $mod) =~ s{::}{/}g;
    return undef unless eval { require "$file.pm"; 1 };
    no strict 'refs';
    my $v = ${"${mod}::VERSION"};
    return defined $v ? "$v" : 'installed';
}

# Which ABI tables resolved, and at what version. Compiled-against comes from
# Punk itself; provided comes from asking the provider.
sub _abi_report {
    my @out;

    push @out, {
        name   => 'Open::API (oa_abi)',
        detail => do {
            my $want = eval { Punk::_oa_abi_version() };
            my $ok   = eval { Punk::_oa_available() };
            defined $want ? "v$want" . ($ok ? ', resolved' : '') : 'unknown';
        },
        state  => (eval { Punk::_oa_available() } ? 'ok' : 'NOT RESOLVED'),
    };

    push @out, do {
        my $ok = eval { require Punk::View::Stencil;
                        Punk::View::Stencil::_abi_ok() };
        { name => 'Template::Stencil (st_abi)',
          detail => $ok ? 'resolved' : 'not resolved',
          state  => $ok ? 'ok' : 'NOT RESOLVED' };
    };

    push @out, do {
        my $v = eval { require Hyperman; Hyperman::_abi_version() };
        my $d = eval { Hyperman->can('detach') } ? ', detach' : '';
        { name   => 'Hyperman (hm_abi)',
          detail => defined $v ? "v$v$d" : 'not available',
          state  => (defined $v && $v >= 2) ? 'ok'
                  : defined $v ? 'TOO OLD (websockets need v2)' : 'MISSING' };
    };

    push @out, do {
        my $p = eval { require File::Raw::JSON; File::Raw::JSON::_abi_ptr() };
        { name => 'File::Raw::JSON (frj_abi)',
          detail => $p ? 'resolved' : 'not resolved',
          state  => $p ? 'ok' : 'NOT RESOLVED' };
    };

    # The markdown mount's two. Both are optional in the sense that an app
    # without a markdown keyword never touches them, so a missing one is
    # reported rather than treated as a fault.
    push @out, do {
        my $ok = eval { Punk::_mds_available() };
        my $v  = eval { Punk::_mds_abi_version() };
        { name   => 'Markdown::Simple (mds_abi)',
          detail => $ok ? "v$v, resolved"
                  : defined $v ? "v$v wanted, not resolved" : 'not available',
          state  => $ok ? 'ok' : 'not resolved (only needed by `markdown`)' };
    };

    push @out, do {
        my $ok = eval { Punk::_sg_available() };
        my $v  = eval { Punk::_sg_abi_version() };
        { name   => 'Search::Trigram (sg_abi)',
          detail => $ok ? "v$v, resolved"
                  : defined $v ? "v$v wanted, not resolved" : 'not available',
          state  => $ok ? 'ok'
                        : 'not resolved (only needed by `markdown` search)' };
    };

    return @out;
}

# ---- config helpers ----------------------------------------------------------

# The same three layers punk_config.h builds: the file, the environment's, and
# the gitignored local one.
sub _layer_files {
    my ($file, $env) = @_;
    my ($stem, $ext) = $file =~ /\A(.*?)(\.[^.\/]*)?\z/;
    $ext = '' unless defined $ext;
    return ( [ 'base',  "$stem$ext" ],
             [ $env,    "$stem.$env$ext" ],
             [ 'local', "$stem.local$ext" ] );
}

sub _yaml_file {
    my ($file) = @_;
    require YAML::XS;
    open my $fh, '<', $file or die "cannot read $file: $!\n";
    local $/;
    my $body = <$fh>;
    close $fh;
    my $doc = YAML::XS::Load($body);
    return ref $doc eq 'HASH' ? $doc : {};
}

# Every single-key { $env: ... } / { $file: ... } / { $exec: [...] } in the
# document, with the dotted path it sits at.
sub _walk_secrets {
    my ($node, $path, $cb) = @_;
    if (ref $node eq 'HASH') {
        my @k = keys %$node;
        if (@k == 1 && $k[0] =~ /\A\$(env|file|exec|literal)\z/) {
            $cb->({ path => ($path || '(root)'), kind => $k[0],
                    value => $node->{ $k[0] } });
            return;
        }
        _walk_secrets($node->{$_}, ($path ? "$path.$_" : $_), $cb)
            for sort keys %$node;
    }
    elsif (ref $node eq 'ARRAY') {
        _walk_secrets($node->[$_], "$path\[$_]", $cb) for 0 .. $#$node;
    }
    return;
}

sub _try_resolver {
    my ($kind, $value) = @_;
    if ($kind eq '$literal') {
        return (1, 'inline value');
    }
    if ($kind eq '$env') {
        my $name = ref $value ? '(not a name)' : ($value // '');
        return (0, "$name is not set") unless defined $ENV{$name};
        return (1, "$name is set");
    }
    if ($kind eq '$file') {
        my $f = ref $value ? '(not a path)' : ($value // '');
        return (0, "$f does not exist")  unless -e $f;
        return (0, "$f is not readable") unless -r $f;
        return (1, $f);
    }
    if ($kind eq '$exec') {
        my @cmd = ref $value eq 'ARRAY' ? @$value : ($value // '');
        my $prog = $cmd[0] // '';
        return (0, 'no command given') unless length $prog;
        return (1, join ' ', @cmd) if $prog =~ m{/} && -x $prog;
        for my $d (split /:/, ($ENV{PATH} // '')) {
            return (1, join ' ', @cmd) if -x File::Spec->catfile($d, $prog);
        }
        return (0, "$prog is not on PATH");
    }
    return (0, 'unknown resolver');
}

# ---- api sync helpers --------------------------------------------------------

# Which operationIds already have a sub, by reading the controllers rather than
# loading them: a half-written controller should not stop the command that is
# meant to help you finish it.
sub _implemented_ops {
    my ($dir, %o) = @_;
    my %seen;
    return %seen unless -d $dir;
    opendir(my $dh, $dir) or return %seen;
    my @files = grep { /\.pm\z/ } readdir $dh;
    closedir $dh;
    for my $f (@files) {
        next if $o{only} && $f !~ $o{only};
        next if $o{skip} && $f =~ $o{skip};
        open my $fh, '<', File::Spec->catfile($dir, $f) or next;
        while (my $l = <$fh>) {
            last if $l =~ /\A__END__/;
            $seen{$1} = $f if $l =~ /\A\s*sub\s+([A-Za-z_]\w*)\s*\{/;
        }
        close $fh;
    }
    return %seen;
}

# Splice new stubs in before the closing 1; of an existing controller.
sub _insert_stubs {
    my ($file, $ops, $dry) = @_;
    return if $dry;
    open my $fh, '<', $file or Carp::croak("punk api: cannot read $file: $!");
    local $/;
    my $src = <$fh>;
    close $fh;

    require Punk::Generate;
    my $stubs = join '', map {
        Punk::Generate->render_skel('api_stub.tmpl', { op => $_ })
    } @$ops;

    if ($src =~ /\n1;\s*\n/) { $src =~ s/\n1;\s*\n/\n$stubs\n1;\n/ }
    else                     { $src .= "\n$stubs" }

    open my $out, '>', $file or Carp::croak("punk api: cannot write $file: $!");
    print $out $src;
    close $out;
    return;
}

# ---- console helpers ---------------------------------------------------------

sub _console_context {
    my ($app) = @_;
    return eval {
        require Punk::Context;
        my $class = $app->{class} . '::_Context';
        $class = 'Punk::Context' unless $class->can('req');
        $class->_build({ REQUEST_METHOD => 'GET', PATH_INFO => '/',
                         QUERY_STRING => '', 'psgi.url_scheme' => 'http',
                         HTTP_HOST => 'localhost', SERVER_NAME => 'localhost',
                         SERVER_PORT => 80 },
                       $app->{registrar}, {});
    };
}

sub _console_wrap {
    my ($line) = @_;
    return "package main; my \$app = \$Punk::Command::app_;"
         . " my \$psgi = \$Punk::Command::psgi_;"
         . " my \$c = \$Punk::Command::ctx_; $line";
}

# ---- dev helpers -------------------------------------------------------------

sub _mtimes {
    my (@dirs) = @_;
    my %m;
    require File::Find;
    File::Find::find({ no_chdir => 1, wanted => sub {
        return unless -f $File::Find::name;
        return if $File::Find::name =~ m{/\.};
        $m{$File::Find::name} = (stat _)[9];
    } }, @dirs) if @dirs;
    return %m;
}

sub _same {
    my ($a, $b) = @_;
    return 0 if keys %$a != keys %$b;
    for (keys %$a) { return 0 if !exists $b->{$_} || $a->{$_} != $b->{$_} }
    return 1;
}

1;

__END__

=head1 NAME

Punk::Command - the subcommands behind the punk tool

=head1 SYNOPSIS

    punk routes                 # the compiled routing table
    punk api sync               # stubs for operations added to the spec
    punk config check           # resolve configuration and every secret
    punk doctor                 # versions, C ABIs, application health
    punk console                # a REPL with the application compiled
    punk dev                    # Hyperman with restart-on-change

=head1 DESCRIPTION

Punk resolves and freezes everything at C<to_app>, which makes a running
application fast and opaque in equal measure. These commands open it
up - what the router holds, what the specification maps to, what the
configuration resolved to, and which C ABIs are in play.

Each finds the application by walking up from the current directory
looking for F<app.psgi>, and takes the class from that file's
C<< Class->to_app >>.

=head1 COMMANDS

=head2 routes

Prints method, path, target and guard count for every route, including
API operations (from their mount, since the specification is the routing
table there), websocket routes and mounted applications. Targets are
recovered from the compiled coderef, so what you see is what the route
resolved to rather than what was declared.

=head2 api_sync

Adds a stub for every operation the specification declares that the
controllers do not implement, and leaves everything else alone. Methods
with no matching operation are reported, never removed. C<dry_run>
reports without writing.

=head2 config_check

Resolves C<config/punk.yml> for an environment, reporting every
C<$env>, C<$file> and C<$exec> reference independently - so one missing
secret does not hide the others - then loads it properly to apply the
guardrail. Exits non-zero when anything failed, which makes it usable as
a deployment gate.

=head2 doctor

Versions, C ABI resolution and, if run inside an application, its route
and configuration counts.

=head2 console

A REPL with C<$app> (the registrar), C<$psgi> and C<$c> (a throwaway
context) in scope.

=head2 dev

Runs the application under L<Hyperman> and restarts it when anything
under F<lib/>, F<config/> or F<root/templates/> changes. A
compiled-at-boot application cannot hot-reload - there is no live
structure to patch - so restarting is the honest implementation.

=head1 SEE ALSO

L<Punk>, L<Punk::Generate>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
