package Punk::Command;

use 5.010;
use strict;
use warnings;
use Carp ();
use Cwd ();
use File::Spec ();
use File::Basename ();
use Getopt::Long ();
use Punk ();

our $VERSION = '0.49';

# The whole punk command line. bin/punk is two lines - `exit
# Punk::Command->main(@ARGV)` - and everything else is here: a registry of
# command specs, one dispatcher that owns option parsing and help generation,
# and the command bodies. Exit codes: 0 fine, 1 something is wrong with the
# application or its environment, 2 the command was used wrongly (misuse
# prints the generated usage to STDERR).
#
# A compiled-at-boot framework is opaque from the outside: everything is
# resolved and frozen inside one coderef at to_app. These commands exist to
# open that up - what the router actually holds, what the spec actually maps
# to, what the configuration actually resolved to, and which C ABIs are
# actually in play.

# ---- the registry ------------------------------------------------------------
#
# A command is a spec registered by name. Help is GENERATED from the spec, so
# `punk help X`, `punk X --help` and every misuse path read one source and
# cannot drift - the invariant the old %USAGE heredocs tried to hold by hand.
#
#     Punk::Command->register(greet => {
#         abstract => 'one line for the command list',
#         display  => 'greet <what>',   # the list row, when the name alone misleads
#         usage    => '[options]',      # after "usage: punk serve "
#         desc     => 'a paragraph for the help page',
#         options  => [ { spec => 'port=i', arg => 'N',
#                         doc => 'listen port', default => 5000 } ],
#         commands => { sync => \%subspec },   # nested verbs (punk api sync)
#         code     => sub { my ($opt, @args) = @_; ...; return 0 },
#         hidden   => 0,
#         hints    => [ [ qr/pattern/, 'the next move worth spelling out' ] ],
#     }, $owner);
#
# Two owners claiming one name croak naming both (the install_kw rule).
# Registration order is display order. A command body signals misuse with
# `die { usage_error => $msg }` (message + usage + exit 2); any other die
# becomes `punk <cmd>: msg` + exit 1, with the spec's hints appended when
# their pattern matches.
#
# An unknown command X gets one shot at `require Punk::Command::<ucfirst X>`,
# whose load-time job is to call register - the seam a plugin dist uses to add
# `punk queue ...`. No namespace scanning, no cost on the common path.

our ($OUT, $ERR);       # the test seam: filehandles replacing STDOUT/STDERR

our (%SPECS, @ORDER, %OWNER);
our @DOCTOR;
my  %DOCTOR_OWNER;

sub register {
    my ($class, $name, $spec, $owner) = @_;
    $owner //= caller;
    Carp::croak('Punk::Command: register needs a name and a spec hashref')
        unless defined $name && length $name && ref $spec eq 'HASH';
    if (my $prev = $OWNER{$name}) {
        Carp::croak("Punk::Command: command '$name' is registered by both "
                  . "$prev and $owner");
    }
    $OWNER{$name} = $owner;
    push @ORDER, $name;
    $spec->{name} //= $name;   # so a diagnostic can name the command it is about
    $SPECS{$name} = $spec;
    return $class;
}

# A doctor row: label plus a probe returning (ok, detail). Core rows register
# here too, so a plugin's rows land in the same report.
sub register_doctor {
    my ($class, $label, $probe, $owner) = @_;
    $owner //= caller;
    if (my $prev = $DOCTOR_OWNER{$label}) {
        Carp::croak("Punk::Command: doctor row '$label' is registered by "
                  . "both $prev and $owner");
    }
    $DOCTOR_OWNER{$label} = $owner;
    push @DOCTOR, [ $label, $probe ];
    return $class;
}

# every command takes these; a spec's own option with the same key wins
my @SHARED_OPTIONS = (
    { spec => 'dir=s', arg => 'PATH',
      doc  => 'the application (default: found by walking up for app.psgi)' },
);

sub _opt_key {
    my ($spec) = @_;
    my ($name) = $spec =~ /^([^=|!+\@]+)/;
    $name =~ tr/-/_/;
    return $name;
}

# ---- the dispatcher ----------------------------------------------------------

sub main {
    my ($class, @argv) = @_;
    local *STDOUT = $OUT if $OUT;
    local *STDERR = $ERR if $ERR;

    if (!@argv || $argv[0] eq '-h' || $argv[0] eq '--help') {
        _usage_all(\*STDOUT);
        return 0;
    }
    if ($argv[0] eq '-v' || $argv[0] eq '--version') {
        print "punk $Punk::VERSION\n";
        return 0;
    }

    my $name = shift @argv;
    return _cmd_help(@argv) if $name eq 'help';

    my $spec = $SPECS{$name} // _probe($name);
    unless ($spec) {
        print STDERR "punk: unknown command '$name'\n\n";
        _usage_all(\*STDERR);
        return 2;
    }

    # descend nested verbs (punk api sync, punk queue jobs ...)
    my $path = $name;
    while ($spec->{commands}) {
        my $tok = (@argv && $argv[0] !~ /^-/) ? $argv[0] : undef;
        if (defined $tok && $spec->{commands}{$tok}) {
            shift @argv;
            $spec = $spec->{commands}{$tok};
            $path .= " $tok";
            next;
        }
        last if $spec->{code};
        if (defined $tok) {
            my @verbs = sort keys %{ $spec->{commands} };
            print STDERR @verbs == 1
                ? "punk $path: expected '$verbs[0]'\n\n"
                : "punk $path: unknown subcommand '$tok' (expected one of: "
                  . join(', ', @verbs) . ")\n\n";
        }
        _usage_cmd($path, $spec, \*STDERR);
        return 2;
    }

    # a raw spec owns its own argv - options, help, everything - which is
    # what an adapter over another CLI wants (punk queue X == punk-queue X)
    if ($spec->{raw}) {
        my $code = eval { $spec->{code}->({}, @argv) };
        if (my $err = $@) { return _fail($path, $err, $spec->{hints}) }
        return defined $code ? int $code : 0;
    }

    # A command may bring options it cannot know at registration time: `new`
    # asks the kit named in argv for its own. Resolved before Getopt so the
    # kit's options parse and show up in help like any other, rather than
    # being scraped out of a leftover argv by the command body.
    my (@extra, @options);
    {
        # Both halves under one eval: resolving them can croak (a kit that
        # will not load), and so can merging them (an option the command
        # already declares). Either is a die that has to become one line and
        # an exit code, not a raw croak out of main.
        my $ok = eval {
            @extra = $spec->{extra_options}
                ? $spec->{extra_options}->(@argv) : ();
            @options = _options_for($spec, \@extra);
            1;
        };
        return _fail($path, $@, $spec->{hints}) unless $ok;
    }

    my (%opt, @gspec);
    for my $o (@options) {
        my $k = _opt_key($o->{spec});
        if ($o->{spec} =~ /\@$/) {
            $opt{$k} = [ @{ $o->{default} || [] } ];
            push @gspec, $o->{spec} => $opt{$k};
        }
        else {
            $opt{$k} = $o->{default} if exists $o->{default};
            push @gspec, $o->{spec} => \$opt{$k};
        }
    }
    {
        my $saved = Getopt::Long::Configure(
            qw(no_auto_abbrev no_ignore_case bundling));
        my $ok = do {
            local $SIG{__WARN__} = sub {
                my ($w) = @_;
                $w =~ s/\s+\z//;
                print STDERR "punk $path: $w\n";
            };
            eval { Getopt::Long::GetOptionsFromArray(\@argv, @gspec) };
        };
        my $err = $@;
        Getopt::Long::Configure($saved);
        if ($err) { print STDERR "punk $path: $err"; return 2 }
        unless ($ok) {
            print STDERR "\n";
            _usage_cmd($path, $spec, \*STDERR, \@extra);
            return 2;
        }
    }
    if ($opt{help}) {
        _usage_cmd($path, $spec, \*STDOUT, \@extra);
        return 0;
    }
    delete $opt{help};

    my $code = eval { $spec->{code}->(\%opt, @argv) };
    if (my $err = $@) {
        if (ref $err eq 'HASH' && defined $err->{usage_error}) {
            print STDERR "punk $path: $err->{usage_error}\n\n";
            _usage_cmd($path, $spec, \*STDERR, \@extra);
            return 2;
        }
        return _fail($path, $err, $spec->{hints});
    }
    return defined $code ? int $code : 0;
}

# the plugin seam: Punk::Command::<Ucfirst> registers at load
sub _probe {
    my ($name) = @_;
    return unless $name =~ /^[a-z][a-z0-9_-]*$/;
    (my $mod = ucfirst $name) =~ s/[-_](\w)/\U$1/g;
    return unless eval { require "Punk/Command/$mod.pm"; 1 };
    return $SPECS{$name};
}

sub _cmd_help {
    my ($topic, @rest) = @_;
    if (defined $topic && length $topic) {
        my $spec = $SPECS{$topic} // _probe($topic);
        unless ($spec) {
            print STDERR "punk help: no such command '$topic'\n\n";
            _usage_all(\*STDERR);
            return 2;
        }
        my $path = $topic;
        while (@rest && $spec->{commands} && $spec->{commands}{$rest[0]}) {
            my $t = shift @rest;
            $spec = $spec->{commands}{$t};
            $path .= " $t";
        }
        _usage_cmd($path, $spec, \*STDOUT);
        return 0;
    }
    _usage_all(\*STDOUT);
    return 0;
}

# croaks arrive with an "at FILE line N." tail that means nothing to someone
# running a command; one actionable line is the whole message
sub _fail {
    my ($path, $err, $hints) = @_;
    $err = "$err";
    $err =~ s/ at \S+ line \d+\.?\s*\z//;
    $err =~ s/\s+\z//;
    $err =~ s/\A(?:Punk::Generate|Punk::Kit::[\w:]+): //;
    print STDERR "punk $path: $err\n";
    for my $h (@{ $hints || [] }) {
        print STDERR "  $h->[1]\n" if $err =~ $h->[0];
    }
    return 1;
}

# ---- generated help ----------------------------------------------------------

sub _options_for {
    my ($spec, $extra) = @_;
    my @own = @{ $spec->{options} || [] };
    my %own_key = map { _opt_key($_->{spec}) => 1 } @own;

    # An option a command brought at run time cannot quietly replace one it
    # declared: which of the two Getopt bound would decide what the command
    # does, and that is not a thing to leave to ordering.
    my @extra;
    for my $o (@{ $extra || [] }) {
        my $k = _opt_key($o->{spec});
        Carp::croak("Punk::Command: option '--$k' is defined by both "
                  . "'" . ($spec->{name} // '?') . "' and "
                  . ($o->{owner} // 'a kit'))
            if $own_key{$k} || $k eq 'help';
        push @extra, $o;
    }
    my %extra_key = map { _opt_key($_->{spec}) => 1 } @extra;

    return (
        (grep { !$own_key{ _opt_key($_->{spec}) }
                && !$extra_key{ _opt_key($_->{spec}) } } @SHARED_OPTIONS),
        @own,
        @extra,
        { spec => 'help|h', doc => 'this' },
    );
}

sub _usage_all {
    my ($fh) = @_;
    print {$fh} "punk - the Punk command line\n\n"
              . "usage: punk <command> [options]\n\ncommands:\n";
    my @rows;
    for my $name (@ORDER) {
        my $spec = $SPECS{$name};
        next if $spec->{hidden};
        push @rows, [ $spec->{display} // $name, $spec->{abstract} // '' ];
    }
    push @rows, [ 'help [command]', "this, or a command's own options" ];
    my $w = 0;
    length $_->[0] > $w and $w = length $_->[0] for @rows;
    printf {$fh} "  %-*s  %s\n", $w, @{$_}[0, 1] for @rows;
    print {$fh} "\n  punk --version\n";
    return;
}

sub _usage_cmd {
    my ($path, $spec, $fh, $extra) = @_;
    if ($spec->{raw}) {
        # the adapted CLI owns its own help
        print {$fh} 'usage: punk ' . $path . ' '
                  . ($spec->{usage} // '<command> [options]') . "\n";
        print {$fh} "\n$spec->{desc}\n" if $spec->{desc};
        print {$fh} "\nsee `punk $path help` for its commands\n";
        return;
    }
    if ($spec->{commands} && !$spec->{code}
        && 1 == keys %{ $spec->{commands} }) {
        # one mandatory verb reads better spelled out: "usage: punk api sync"
        my ($verb) = keys %{ $spec->{commands} };
        return _usage_cmd("$path $verb", $spec->{commands}{$verb}, $fh);
    }
    print {$fh} "usage: punk $path " . ($spec->{usage} // '[options]') . "\n";
    print {$fh} "\n$spec->{desc}\n" if $spec->{desc};
    if ($spec->{commands}) {
        my @names = sort keys %{ $spec->{commands} };
        my $w = 0;
        length $_ > $w and $w = length $_ for @names;
        print {$fh} "\ncommands:\n";
        printf {$fh} "  %-*s  %s\n", $w, $_,
            $spec->{commands}{$_}{abstract} // '' for @names;
    }
    # Options a kit brought get their own heading, so it is clear which of
    # them go away when --kit does.
    my @extra = @{ $extra || [] };
    my %is_extra = map { _opt_key($_->{spec}) => 1 } @extra;
    my @options = _options_for($spec, \@extra);
    my (@rows, @extra_rows);
    for my $o (@options) {
        next if $o->{hidden};
        my ($long) = $o->{spec} =~ /^([^=|!+\@]+)/;
        (my $shown = $long) =~ tr/_/-/;
        my $left = "--$shown" . (defined $o->{arg} && length $o->{arg}
                                 ? " $o->{arg}" : '');
        my $doc = $o->{doc} // '';
        $doc .= " (default: $o->{default})"
            if defined $o->{default} && !ref $o->{default}
            && length $o->{default};
        push @{ $is_extra{ _opt_key($o->{spec}) } ? \@extra_rows : \@rows },
             [ $left, $doc ];
    }
    my $w = 0;
    length $_->[0] > $w and $w = length $_->[0] for @rows, @extra_rows;
    print {$fh} "\noptions:\n";
    printf {$fh} "  %-*s  %s\n", $w, @{$_}[0, 1] for @rows;
    if (@extra_rows) {
        my $title = $extra[0]{section} // 'more options';
        print {$fh} "\n$title:\n";
        printf {$fh} "  %-*s  %s\n", $w, @{$_}[0, 1] for @extra_rows;
    }
    if ($spec->{examples}) {
        print {$fh} "\nexamples:\n";
        print {$fh} "  $_\n" for @{ $spec->{examples} };
    }
    return;
}

# ---- legacy public surface ---------------------------------------------------

our @COMMANDS = qw(routes api doctor config console dev);

sub commands { grep { !$SPECS{$_}{hidden} } @ORDER }

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
            name   => $rec->{name},
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
                # an operationId IS the name: it is what url_for takes, and
                # it shares the one namespace with the route names
                name   => $op->{operationId},
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

    if (defined $opt{method}) {
        my $want = uc $opt{method};
        @rows = grep { $_->{method} eq $want } @rows;
    }
    if (defined $opt{kind}) {
        @rows = grep { $_->{kind} eq $opt{kind} } @rows;
    }
    # exact, not a glob: a name is an identifier, and the question `--name`
    # answers is "which route is this, that my template names?"
    if (defined $opt{name}) {
        @rows = grep { defined $_->{name} && $_->{name} eq $opt{name} } @rows;
    }
    if (defined $opt{path}) {
        my $re = _glob_re($opt{path});
        @rows = grep { $_->{path} =~ $re } @rows;
    }
    unless (@rows) {
        print "no matching routes\n";
        return 0;
    }

    @rows = sort { $a->{path} cmp $b->{path} || $a->{method} cmp $b->{method} }
            @rows if $opt{sort};

    if ($opt{json}) {
        require File::Raw::JSON;
        print File::Raw::JSON::file_json_encode(\@rows), "\n";
        return 0;
    }

    my $w_m = _widest('method', \@rows, 6);
    my $w_p = _widest('path',   \@rows, 4);
    # the NAME column appears only when a route has one, so a table from an
    # application that names nothing prints exactly as it did before
    my $named = grep { defined $_->{name} } @rows;
    my $w_n = $named ? _widest('name', \@rows, 4) : 0;
    printf "%-*s  %-*s  %s%s\n", $w_m, 'METHOD', $w_p, 'PATH',
        ($named ? sprintf('%-*s  ', $w_n, 'NAME') : ''), 'TARGET';
    for my $r (@rows) {
        printf "%-*s  %-*s  %s%s%s\n", $w_m, $r->{method}, $w_p, $r->{path},
            ($named ? sprintf('%-*s  ', $w_n, $r->{name} // '') : ''),
            $r->{target},
            $r->{guards} ? "  [$r->{guards} guard"
                         . ($r->{guards} > 1 ? 's' : '') . ']' : '';
    }
    printf "\n%d route%s\n", scalar @rows, @rows == 1 ? '' : 's';
    return 0;
}

# a path glob for --path: * is one segment's worth, ** crosses slashes
sub _glob_re {
    my ($glob) = @_;
    my $re = join '',
        map { $_ eq '**' ? '.*' : $_ eq '*' ? '[^/]*' : quotemeta $_ }
        grep { length }
        split /(\*\*|\*)/, $glob;
    return qr/^$re$/;
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
    for my $mod (qw(Open::API Template::Stencil File::Raw::JSON File::Raw::XML
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

    # Load every Punk::Command::* on @INC first.
    #
    # A plugin's command module registers at load, and nothing loads it until
    # somebody types its name - which is right for `punk dev`, where the cost
    # of scanning would be paid on every invocation, and wrong here. `doctor`
    # is the command whose whole job is "what have I got installed", and a
    # row that only appears when you were already running that plugin's
    # command is a row nobody will ever see when they need it.
    #
    # A module that dies on load is skipped rather than fatal: doctor is what
    # somebody runs when something is already broken.
    _load_command_plugins();

    # rows other distributions registered (register_doctor) - a probe returns
    # (ok, detail); a die is a failed row, not a failed doctor
    if (@DOCTOR) {
        print "\nplugins\n";
        for my $row (@DOCTOR) {
            my ($label, $probe) = @$row;
            my ($ok, $detail) = eval { $probe->() };
            if ($@) {
                my $e = $@; $e =~ s/ at \S+ line \d+\.?\s*\z//; $e =~ s/\s+\z//;
                ($ok, $detail) = (0, $e);
            }
            $bad++ unless $ok;
            _line($label, $detail // '-', $ok ? 'ok' : 'FAILED');
        }
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
    my $env  = $opt{env} || $ENV{PUNK_ENV} || 'production';

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

    # Named so the evals below can see them by name rather than by closure.
    our $app_  = $app->{registrar};
    our $psgi_ = $app->{psgi};
    our $ctx_  = _console_context($app);

    # --eval: one expression, its dump, and out - the scripting form.
    if (defined $opt{eval}) {
        my @out = eval _console_wrap($opt{eval});
        if ($@) { print STDERR "!! $@"; return 1 }
        print _console_dump(@out) if @out;
        return 0;
    }

    my $class = $app->{class};
    print "punk console - $class\n"
        . "  \$app   the Punk::App registrar\n"
        . "  \$psgi  the compiled PSGI coderef\n"
        . "  \$c     a throwaway context (\$c->model, \$c->render, ...)\n"
        . "  q, exit or ctrl-d to leave\n\n";

    # Term::ReadLine::Stub reads nothing from a pipe, so it is for terminals
    # only; falling back to STDIN keeps the console scriptable.
    my $tty  = -t STDIN;
    my $term = $tty ? eval { require Term::ReadLine;
                             Term::ReadLine->new('punk') } : undef;

    # History survives sessions when the reader supports it - only on a
    # terminal, so piped input never rewrites the file.
    my $hist = $ENV{PUNK_HISTFILE}
        // File::Spec->catfile($ENV{HOME} || '.', '.punk_history');
    if ($term && $term->can('ReadHistory')) {
        $term->ReadHistory($hist) if -f $hist;
    }

    while (1) {
        my $line = $term ? $term->readline('punk> ') : do {
            print 'punk> ' if $tty;
            my $l = <STDIN>;
            $l;
        };
        last unless defined $line;
        chomp $line;
        next unless $line =~ /\S/;
        last if $line =~ /^\s*(?:q|quit|exit)\s*$/;
        my @out = eval _console_wrap($line);
        if ($@) { print "!! $@"; next }
        next unless @out;
        print _console_dump(@out);
    }
    if ($term && $term->can('WriteHistory')) {
        eval { $term->WriteHistory($hist) };
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
    my $workers = $opt{workers} || 1;

    unless (eval { require Hyperman; 1 }) {
        print STDERR "punk dev: Hyperman is not installed\n";
        return 1;
    }

    my @watch_rel = @{ $opt{watch} || [] };
    @watch_rel = qw(lib config root/templates) unless @watch_rel;
    my @watch = grep { -d $_ }
                map { File::Spec->file_name_is_absolute($_)
                      ? $_ : File::Spec->catdir($root, $_) } @watch_rel;
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
            # punk dev IS the development opt-in: the environment defaults
            # to production everywhere else. --env overrides even an
            # inherited setting - saying it on the command line is explicit.
            $ENV{PUNK_ENV} = $opt{env} if defined $opt{env};
            $ENV{PUNK_ENV} //= 'development';
            # app.psgi reads $0 to find lib/ and its own root, exactly as a
            # server loading the file would
            local $0 = $psgi;
            my $app = do $psgi;
            die($@ || $! || "punk dev: $psgi did not return an app\n")
                unless ref $app eq 'CODE';
            Hyperman->run(app => $app, host => $host, port => $port,
                          workers => $workers);
            exit 0;
        }

        if ($opt{no_reload}) {
            waitpid $child, 0;
            last;
        }

        # One watch loop for both waits: until a change while the child runs,
        # and - after it exits on its own (a compile error, most likely) -
        # until a change gives any reason to try again. Respinning
        # immediately would just spin.
        while (!$stop) {
            select undef, undef, undef, 0.5;
            if ($child && waitpid($child, POSIX::WNOHANG()) == $child) {
                $child = 0;
                print "\n-- the application exited; waiting for a change --\n";
            }
            my %now = _mtimes(@watch);
            next if _same(\%seen, \%now);
            my ($what) = grep { ($seen{$_} // 0) != ($now{$_} // 0) }
                         sort keys %now;
            printf "\n-- %s changed, restarting --\n", _rel($root, $what // '');
            %seen = %now;
            if ($child) {
                kill 'TERM', $child;
                waitpid $child, 0;
                $child = 0;
            }
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

# ---- punk serve --------------------------------------------------------------

# The other command that needs no application. `dev` serves an application and
# refuses without one; this serves a directory of files and never looks for
# one - the whole server is Punk::Static->app, which carries no framework
# state at all.
#
# There is no watch-and-restart loop here, unlike `dev`: a file is read on the
# request that asks for it, so there is nothing compiled to invalidate.
sub _cmd_serve {
    my ($opt, @args) = @_;
    my $dir = shift(@args);
    die { usage_error => "unexpected argument '$args[0]'" } if @args;
    $dir = $opt->{dir} unless defined $dir && length $dir;
    $dir = '.' unless defined $dir && length $dir;

    -d $dir or die "no such directory: $dir\n";

    unless (eval { require Hyperman; 1 }) {
        print STDERR "punk serve: Hyperman is not installed\n";
        return 1;
    }

    require Punk::Static;
    my $app = Punk::Static->app($dir,
        ($opt->{no_index} ? () : (index => $opt->{index})),
        ($opt->{list}     ? (list  => 1) : ()),
        (defined $opt->{max_age} ? (max_age => $opt->{max_age}) : ()),
    );

    my $port = $opt->{port} || 8000;
    my $host = $opt->{host} || '127.0.0.1';
    printf "punk serve  http://%s:%d\n", $host, $port;
    printf "serving     %s\n\n", Cwd::abs_path($dir) // $dir;

    # access_log takes an open handle and formats Combined Log Format in C,
    # buffered and flushed once per wakeup - a request log with no per-request
    # Perl frame, which is the only reason it is on by default.
    Hyperman->run(app => $app, host => $host, port => $port,
                  workers => ($opt->{workers} || 1),
                  ($opt->{quiet} ? () : (access_log => \*STDERR)));
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

# Load the application, with the reason out through $err rather than printed:
# the two callers below want it said in two different ways.
sub _load_app_info {
    my ($dir, $errref, %o) = @_;
    my $say = sub { $$errref = $_[0]; return undef };

    my $root = _find_root($dir);
    return $say->("no application found (looked for app.psgi upwards from "
                . ($dir || Cwd::getcwd()) . ")") unless $root;

    my $class = _class_of($root);
    return $say->("cannot work out the application class in $root")
        unless $class;

    my $psgi_file = File::Spec->catfile($root, 'app.psgi');
    my $cwd = Cwd::getcwd();
    my $psgi = do {
        local $0 = $psgi_file;    # app.psgi finds lib/ and its root through it
        do $psgi_file;
    };
    # app.psgi chdirs to the application root and everything relative in
    # punk.yml is written for that. A caller that will go on to open the
    # database wants to be left there; one that only reads the compiled
    # tables wants its own directory back.
    chdir($o{chdir} ? $root : $cwd);
    unless (ref $psgi eq 'CODE') {
        my $err = $@ || $! || 'it returned no coderef';
        chdir $cwd unless $o{chdir};
        return $say->("$psgi_file did not load: $err");
    }
    my $registrar = $class->can('punk_app') ? $class->punk_app : undef;
    return $say->("$class is not a Punk application") unless $registrar;

    return { root => $root, class => $class, psgi => $psgi,
             registrar => $registrar };
}

sub _load_app {
    my ($dir, %o) = @_;
    my $err;
    my $app = _load_app_info($dir, \$err, %o);
    print STDERR "punk: $err\n" if !$app && !$o{quiet};
    return $app;
}

# The public form, for a command in another distribution: same load, but the
# failure is a die, because a command body's die already becomes one prefixed
# line through _fail.
#
#     my $app = Punk::Command->load_app(dir => $opt->{dir}, chdir => 1);
#     my $users = $app->{registrar}->model_instance('User');
#
# `chdir => 1` leaves the process in the application root, which is what
# anything opening a relative dsn from punk.yml needs; without it the
# directory the caller started in is restored.
sub load_app {
    my ($class, %o) = @_;
    my $dir = delete $o{dir};
    my $err;
    my $app = _load_app_info($dir, \$err, %o);
    die "$err\n" unless $app;
    return $app;
}

# Every Punk/Command/*.pm an @INC entry holds, loaded once. Only that exact
# directory, only a plain .pm, and each in its own eval - this walks
# directories a user did not ask it to walk, so it does as little as it can.
sub _load_command_plugins {
    my %seen;
    for my $inc (@INC) {
        next if ref $inc;
        my $dir = File::Spec->catdir($inc, 'Punk', 'Command');
        next unless -d $dir;
        opendir(my $dh, $dir) or next;
        my @mods = grep { /\A[A-Za-z]\w*\.pm\z/ } readdir $dh;
        closedir $dh;
        for my $file (sort @mods) {
            next if $seen{$file}++;
            (my $mod = "Punk/Command/$file") =~ s{/}{/}g;
            next if $INC{$mod};
            eval { require $mod; 1 };
        }
    }
    return;
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

    push @out, do {
        my $p = eval { require File::Raw::XML; File::Raw::XML::_abi_ptr() };
        my $v = eval { File::Raw::XML::_abi_version() };
        { name   => 'File::Raw::XML (frx_abi)',
          detail => $p ? "v" . ($v // '?') . ", resolved" : 'not resolved',
          state  => $p ? 'ok' : 'NOT RESOLVED' };
    };

    # Frozen holds the i18n catalogues. Hard, unlike the markdown pair
    # below: an app with the I18n plugin cannot boot without it, so a
    # missing table is a fault rather than a note.
    push @out, do {
        my $ok   = eval { Punk::_fz_available() };
        my $want = eval { Punk::_fz_abi_version() };
        my $have = eval { require Frozen; Frozen::_abi_version() };
        { name   => 'Frozen (fz_abi)',
          detail => $ok ? "v$have, resolved"
                  : defined $have ? "v$have present, v$want wanted"
                  : 'not available',
          state  => $ok ? 'ok'
                  : defined $have ? 'TOO OLD (upgrade Frozen)' : 'MISSING' };
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

sub _console_dump {
    my (@out) = @_;
    require Data::Dumper;
    my $d = Data::Dumper->new(\@out);
    $d->Sortkeys(1)->Indent(1)->Terse(1);
    return $d->Dump;
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

# ---- punk new ----------------------------------------------------------------
# The one command that does not need an existing application. The work lives
# in Punk::Generate; this is argument shape and the next-steps note.

# The kit seam, the command seam's twin: `--kit diy` loads Punk::Kit::Diy and
# generates through it. Same name shape and same transform as _probe, so a
# distribution shipping both a kit and a subcommand spells them alike.
sub _kit_name_ok { return $_[0] =~ /\A[a-z][a-z0-9_-]*\z/ }

sub _kit_class {
    my ($kit) = @_;
    (my $mod = ucfirst $kit) =~ s/[-_](\w)/\U$1/g;
    my $class = "Punk::Kit::$mod";
    (my $file = "$class.pm") =~ s{::}{/}g;
    unless (eval { require $file; 1 }) {
        my $err = $@;
        # Two different problems with two different answers: one is a cpanm
        # away, the other is a bug in something already installed.
        die "kit '$kit' is not installed (no $class on \@INC)\n"
            if $err =~ /\ACan't locate \Q$file\E in \@INC/;
        $err =~ s/\s+\z//;
        die "kit '$kit' failed to load: $err\n";
    }
    die "$class is not a kit: a kit subclasses Punk::Generate and overrides "
      . "run\n" unless $class->isa('Punk::Generate');
    return $class;
}

# --kit's value, read out of argv before Getopt has run, so the kit's own
# options can be added to the ones being parsed. Takes both spellings and only
# the first: a second --kit is Getopt's to complain about, not this.
sub _kit_from_argv {
    my (@argv) = @_;
    for my $i (0 .. $#argv) {
        return $1 if $argv[$i] =~ /\A--kit=(.*)\z/s;
        return $argv[$i + 1] if $argv[$i] eq '--kit' && $i < $#argv;
    }
    return;
}

sub _cmd_new {
    my ($opt, @args) = @_;
    my $name = shift @args;
    die { usage_error => 'an application name is required' }
        unless defined $name && length $name;
    die { usage_error => "unexpected argument '$args[0]'" } if @args;
    # --sqitch's engine is checked before anything is written
    die { usage_error => "--sqitch needs an engine: sqlite, pg or mysql, not '$opt->{sqitch}'" }
        if defined $opt->{sqitch} && $opt->{sqitch} !~ /\A(?:sqlite|pg|mysql)\z/;
    die { usage_error => "--kit takes a name like 'diy' ([a-z][a-z0-9_-]*), "
                       . "not '$opt->{kit}'" }
        if defined $opt->{kit} && !_kit_name_ok($opt->{kit});

    require Punk::Generate;
    my $class = defined $opt->{kit} ? _kit_class($opt->{kit}) : 'Punk::Generate';

    # Every option goes to the constructor: Punk::Generate ignores the keys it
    # does not know, so a kit reads its own out of the same hash rather than
    # needing this to know what it takes.
    my $gen = $class->new(
        %$opt,
        name  => $name,
        (defined $opt->{dir} ? (dir => $opt->{dir}) : ()),
        (defined $opt->{api} ? (api => $opt->{api}) : ()),
        force => $opt->{force},
    );
    my @files = $gen->run;
    my $dir = $gen->dir;
    print "Created $name in $dir\n\n";
    print "  $_\n" for @files;

    # --sqitch ENGINE: a Sqitch project for the schema, through Punk-Sqitch.
    # The engine is asked for rather than read, because the generated
    # punk.yml ships its database block commented out. The application is
    # already written by now, so a missing Punk-Sqitch is reported with the
    # command to run once it is installed, not as a failed `new`.
    my $sq = 0;
    if (defined $opt->{sqitch}
        && -f File::Spec->catfile($dir, 'sqitch.plan')) {
        # A kit that manages its own schema has already written the project.
        # Sqitch's own init is a silent no-op on one, so running it here would
        # end a successful generation with a confusing message about a project
        # that is exactly as it should be.
        print "\npunk new: the kit wrote the Sqitch project; skipping init\n";
    }
    elsif (defined $opt->{sqitch}) {
        my $engine = $opt->{sqitch};
        if (eval { require Punk::Command::Sqitch; 1 }) {
            print "\n";
            $sq = Punk::Command::Sqitch::main('--dir', $dir, 'init', '--engine', $engine);
        }
        else {
            print STDERR "\npunk new: --sqitch needs Punk-Sqitch, which is not installed; "
                       . "once it is, run\n\n  punk sqitch init --engine $engine\n\n"
                       . "inside $dir\n";
            $sq = 1;
        }
    }
    # A kit knows what its application needs before it will serve - a schema
    # deployed, a secret set - so it gets to say so instead of this.
    if ($gen->can('next_steps')) {
        print $gen->next_steps;
    }
    else {
        print <<"NEXT";

  cd $dir
  plackup app.psgi

Then open http://localhost:5000/
NEXT
    }
    return $sq;
}

# ---- punk generate -----------------------------------------------------------
# Into an EXISTING application - `new` scaffolds once; these add to it. The
# class comes from app.psgi by the same scrape _load_app uses, but without
# executing anything - a broken controller cannot stop you generating the fix.

sub _cmd_generate {
    my ($kind, $opt, @args) = @_;
    my $name = shift @args;
    die { usage_error => "a $kind name is required" }
        unless defined $name && length $name;
    die { usage_error => "unexpected argument '$args[0]'" } if @args;
    die { usage_error => "'$name' is not a valid package name" }
        unless $name =~ /^[A-Z]\w*(?:::[A-Z]\w*)*$/;

    my $root = _find_root($opt->{dir})
        or die "no application found (run inside one, or pass --dir)\n";
    my $class = _class_of($root)
        or die "could not read the application class from app.psgi\n";

    my @segs = split /::/, $name;
    my ($tmpl, $rel, %vars);
    if ($kind eq 'controller') {
        my $ns = $opt->{api} ? 'API' : 'Web';
        $rel  = join('/', 'lib', (split /::/, $class),
                     'Controller', $ns, @segs) . '.pm';
        $tmpl = 'controller_gen.tmpl';
        %vars = (app => $class, ns => $ns, name => join('::', @segs),
                 route => lc(join '/', @segs), api => $opt->{api} ? 1 : 0);
    }
    else {
        $rel  = join('/', 'lib', (split /::/, $class), 'Model', @segs) . '.pm';
        $tmpl = 'model_gen.tmpl';
        %vars = (app => $class, name => join('::', @segs),
                 table => $opt->{table} // lc($segs[-1]) . 's');
    }
    my $abs = File::Spec->catfile($root, split m{/}, $rel);
    die "$rel already exists\n" if -e $abs && !$opt->{force};

    require Punk::Generate;
    Punk::Generate->write_skel($tmpl, $abs, \%vars);
    print "wrote $rel\n";
    return 0;
}

# ---- punk test ---------------------------------------------------------------

sub _cmd_test {
    my ($opt, @args) = @_;
    my $root = _find_root($opt->{dir}) or do {
        print STDERR "punk test: no application found\n";
        return 2;
    };
    require App::Prove;                       # ships with Test::Harness
    local $ENV{PUNK_ENV} = $opt->{env} if defined $opt->{env};
    my $cwd = Cwd::getcwd();
    chdir $root or die "cannot chdir to $root: $!\n";
    my $prove = App::Prove->new;
    $prove->process_args('-l', '-r', (@args ? @args : 't'));
    my $ok  = eval { $prove->run };
    my $err = $@;
    chdir $cwd;
    die $err if $err;
    return $ok ? 0 : 1;
}

# ---- punk secret -------------------------------------------------------------

sub _random_bytes {
    my ($n) = @_;
    open my $ur, '<:raw', '/dev/urandom'
        or die "cannot open /dev/urandom: $!\n";
    my $bytes;
    my $got = read($ur, $bytes, $n);
    close $ur;
    die "short read from /dev/urandom\n" unless ($got // 0) == $n;
    return $bytes;
}

sub _cmd_secret {
    my ($opt) = @_;
    my $n = $opt->{bytes};
    die { usage_error => 'bytes must be between 16 and 256' }
        if !$n || $n < 16 || $n > 256;
    my $raw = _random_bytes($n);
    if ($opt->{hex}) {
        print unpack('H*', $raw), "\n";
    }
    else {
        require MIME::Base64;
        my $t = MIME::Base64::encode_base64($raw, '');
        $t =~ tr{+/=}{-_}d;                   # url-safe, no padding
        print "$t\n";
    }
    return 0;
}

# ---- the core registrations --------------------------------------------------
# Registration order is the order `punk` lists them in.

__PACKAGE__->register(new => {
    abstract => 'generate a new application',
    display  => 'new <AppName>',
    usage    => '<AppName> [options]',
    desc     => 'Generate a running Punk application: routes, a controller, '
              . "Stencil views,\nconfig/punk.yml, a psgi entry point and a "
              . 'test.',
    options  => [
        { spec => 'dir=s', arg => 'PATH',
          doc  => 'where to write it (default: the name, :: replaced by -)' },
        { spec => 'api=s', arg => 'SPEC',
          doc  => 'an OpenAPI 3.1 document to mount under /api, generating '
                . 'one controller of operation stubs per tag' },
        { spec => 'force',
          doc  => 'write into a directory that is not empty' },
        { spec => 'sqitch=s', arg => 'ENGINE',
          doc  => 'also initialise a Sqitch project for the schema (sqlite, pg '
                . 'or mysql); needs Punk-Sqitch' },
        { spec => 'kit=s', arg => 'NAME',
          doc  => 'generate from an installed kit (Punk::Kit::<Name>) instead '
                . 'of the basic skeleton; `punk new --kit NAME --help` lists '
                . 'what it takes' },
    ],
    # The kit named in argv brings its own options, so they parse and appear
    # in help like any other rather than being scraped out of a leftover argv.
    extra_options => sub {
        my (@argv) = @_;
        my $kit = _kit_from_argv(@argv);
        return unless defined $kit && _kit_name_ok($kit);
        my $class = eval { _kit_class($kit) } or return;   # the body reports it
        return unless $class->can('options');
        return map { { %$_, owner => $class, section => "kit options ($kit)" } }
                   $class->options;
    },
    examples => [
        'punk new MyApp',
        'punk new MyApp --dir ~/code/myapp',
        'punk new MyApp --api ./openapi.json',
        'punk new MyApp --sqitch pg',
        'punk new MyApp --kit diy',
    ],
    hints => [ [ qr/is not empty/, 'use --force to write into it anyway' ],
               [ qr/kit '.*' is not installed/,
                 'kits ship in their own distributions; the diy kit is '
               . 'Punk-DIY' ] ],
    code  => \&_cmd_new,
});

__PACKAGE__->register(generate => {
    abstract => 'add a controller or model to an existing application',
    display  => 'generate <what>',
    commands => {
        controller => {
            abstract => 'a controller class',
            usage    => '<Name> [options]',
            desc     => 'Write lib/<App>/Controller/Web/<Name>.pm (or '
                      . "Controller/API with --api) into\nthe application, "
                      . 'ready to be named as a route target.',
            options  => [
                { spec => 'api',
                  doc  => 'under Controller::API, answering JSON' },
                { spec => 'force', doc => 'overwrite an existing file' },
            ],
            code => sub {
                my ($opt, @a) = @_;
                return _cmd_generate(controller => $opt, @a);
            },
        },
        model => {
            abstract => 'a Punk::Model class',
            usage    => '<Name> [options]',
            desc     => 'Write lib/<App>/Model/<Name>.pm with a table and a '
                      . "field stub - auto-discovered\nby a bare `model;`, or "
                      . "registered with model '<Name>'.",
            options  => [
                { spec => 'table=s', arg => 'NAME',
                  doc  => 'the table (default: the lowercased name, '
                        . 'pluralised)' },
                { spec => 'force', doc => 'overwrite an existing file' },
            ],
            code => sub {
                my ($opt, @a) = @_;
                return _cmd_generate(model => $opt, @a);
            },
        },
    },
});

__PACKAGE__->register(routes => {
    abstract => 'the compiled routing table',
    desc     => 'Print the compiled routing table: every route, API '
              . "operation, websocket\nroute and mounted application, with "
              . 'what it resolved to.',
    options  => [
        { spec => 'sort',
          doc  => 'order by path rather than by declaration' },
        { spec => 'method=s', arg => 'NAME',
          doc  => 'only this HTTP method (or WS / ANY)' },
        { spec => 'path=s', arg => 'GLOB',
          doc  => 'only paths matching the glob (* within a segment, '
                . '** across)' },
        { spec => 'kind=s', arg => 'KIND',
          doc  => 'only route, api, ws, markdown or mount rows' },
        { spec => 'name=s', arg => 'NAME',
          doc  => 'only the route with this name (exact)' },
        { spec => 'json',
          doc  => 'machine output: a JSON array of row objects' },
    ],
    code => sub { my ($opt) = @_; return routes(%$opt) },
});

__PACKAGE__->register(api => {
    abstract => 'add stubs for operations added to the spec',
    display  => 'api sync',
    commands => {
        sync => {
            abstract => 'add stubs for new operations',
            desc     => 'Add a stub for every operation openapi.json declares '
                      . "that the controllers\ndo not implement. Methods with "
                      . "no matching operation are reported, never\nremoved, "
                      . 'and an implemented operation is never touched.',
            options  => [
                { spec => 'spec=s', arg => 'PATH',
                  doc  => 'the document (default: openapi.json in the '
                        . 'application root)' },
                { spec => 'dry-run',
                  doc  => 'report what would change, write nothing' },
            ],
            code => sub { my ($opt) = @_; return api_sync(%$opt) },
        },
    },
});

__PACKAGE__->register(config => {
    abstract => 'resolve the configuration and every secret it references',
    display  => 'config check',
    commands => {
        check => {
            abstract => 'resolve the configuration',
            desc     => 'Resolve config/punk.yml and report every $env, '
                      . "\$file and \$exec reference\nindependently, so one "
                      . "missing secret does not hide the rest. Exits\n"
                      . 'non-zero when anything failed - usable as a '
                      . 'deployment gate.',
            options  => [
                { spec => 'file=s', arg => 'PATH',
                  doc  => 'the config file (default: config/punk.yml)' },
                { spec => 'env=s', arg => 'NAME',
                  doc  => 'the environment layer (default: $PUNK_ENV or '
                        . 'production)' },
                { spec => 'secrets=s', arg => 'MODE',
                  doc  => 'strict, warn or off, for the plaintext-secret '
                        . 'guardrail' },
                { spec => 'dump',
                  doc  => 'print the resolved structure, secrets redacted' },
            ],
            code => sub { my ($opt) = @_; return config_check(%$opt) },
        },
    },
});

__PACKAGE__->register(doctor => {
    abstract => 'versions, C ABIs and application health',
    desc     => 'Report versions, which C ABI tables resolved and at what '
              . "version, and -\nwhen run inside an application - its routes "
              . 'and configuration.',
    code     => sub { my ($opt) = @_; return doctor(%$opt) },
});

__PACKAGE__->register(console => {
    abstract => 'a REPL with the application compiled',
    desc     => 'A REPL with the application compiled: $app is the '
              . "registrar, \$psgi the\ncompiled coderef, \$c a throwaway "
              . 'context for $c->model and friends.',
    options  => [
        { spec => 'eval=s', arg => 'CODE',
          doc  => 'evaluate one expression, print its dump, exit' },
    ],
    code     => sub { my ($opt) = @_; return console(%$opt) },
});

__PACKAGE__->register(test => {
    abstract => 'run the application test suite',
    usage    => '[prove arguments]',
    desc     => 'Run prove -lr in the application root. Extra arguments go '
              . "to prove\nverbatim (a file, -v, -j4).",
    options  => [
        { spec => 'env=s', arg => 'NAME', doc => 'PUNK_ENV for the run' },
    ],
    code => \&_cmd_test,
});

__PACKAGE__->register(secret => {
    abstract => 'random key material for a session secret',
    desc     => 'Print one line of random key material - what punk.yml\'s '
              . "session secret\nwants behind its \$env reference. Nothing "
              . 'else goes to stdout, so it pipes.',
    options  => [
        { spec => 'bytes=i', arg => 'N', doc => 'how much entropy',
          default => 32 },
        { spec => 'hex', doc => 'hex instead of url-safe base64' },
    ],
    code => \&_cmd_secret,
});

__PACKAGE__->register(dev => {
    abstract => 'run under Hyperman, restarting when files change',
    desc     => 'Run the application under Hyperman, restarting it when '
              . "anything under\nlib/, config/ or root/templates/ changes.",
    options  => [
        { spec => 'port=i', arg => 'N',    doc => 'listen port',
          default => 5000 },
        { spec => 'host=s', arg => 'ADDR', doc => 'listen address',
          default => '127.0.0.1' },
        { spec => 'workers=i', arg => 'N', doc => 'worker processes',
          default => 1 },
        { spec => 'watch=s@', arg => 'DIR',
          doc  => 'watch this directory, repeatable (default: lib, config, '
                . 'root/templates)' },
        { spec => 'env=s', arg => 'NAME',
          doc  => 'PUNK_ENV for the server (default: development)' },
        { spec => 'no-reload', doc => 'do not watch for changes' },
    ],
    code => sub { my ($opt) = @_; return dev(%$opt) },
});

__PACKAGE__->register(serve => {
    abstract => 'serve a directory of files over HTTP',
    display  => 'serve [DIR]',
    usage    => '[DIR] [options]',
    desc     => "Serve a directory of files under Hyperman. There is no "
              . "application involved -\nno app.psgi, no configuration, "
              . "nothing to generate. A directory resolves to\nits "
              . 'index.html, and --list renders one for a directory that '
              . 'has none.',
    options  => [
        # displaces the shared --dir, which is about finding an application
        { spec => 'dir=s', arg => 'PATH',
          doc  => 'the directory to serve, if not given as an argument',
          default => '.' },
        { spec => 'port=i', arg => 'N',    doc => 'listen port',
          default => 8000 },
        { spec => 'host=s', arg => 'ADDR', doc => 'listen address',
          default => '127.0.0.1' },
        { spec => 'workers=i', arg => 'N', doc => 'worker processes',
          default => 1 },
        { spec => 'index=s', arg => 'NAME',
          doc  => 'the file a directory resolves to', default => 'index.html' },
        { spec => 'no-index',
          doc  => 'leave a directory as a 404 instead' },
        { spec => 'list',
          doc  => 'render a listing for a directory with no index file' },
        { spec => 'max-age=i', arg => 'N',
          doc  => 'Cache-Control freshness in seconds (default: revalidate '
                . 'every time)' },
        { spec => 'quiet', doc => 'no access log' },
    ],
    examples => [
        'punk serve',
        'punk serve ./public --port 3000',
        'punk serve --host 0.0.0.0 --list',
    ],
    hints => [ [ qr/Hyperman is not installed/,
                 'cpanm Hyperman' ] ],
    code => \&_cmd_serve,
});

__PACKAGE__->register(version => {
    abstract => 'print the version',
    hidden   => 1,                     # the list already shows punk --version
    code     => sub { print "punk $Punk::VERSION\n"; return 0 },
});

1;

__END__

=head1 NAME

Punk::Command - the punk command line: registry, dispatcher and commands

=head1 SYNOPSIS

    punk new MyApp              # generate a new application
    punk routes                 # the compiled routing table
    punk api sync               # stubs for operations added to the spec
    punk config check           # resolve configuration and every secret
    punk doctor                 # versions, C ABIs, application health
    punk console                # a REPL with the application compiled
    punk dev                    # Hyperman with restart-on-change
    punk serve ./public         # a directory of files, no application

=head1 DESCRIPTION

Punk resolves and freezes everything at C<to_app>, which makes a running
application fast and opaque in equal measure. These commands open it
up - what the router holds, what the specification maps to, what the
configuration resolved to, and which C ABIs are in play.

Except for C<new> and C<serve>, each finds the application by walking up
from the current directory looking for F<app.psgi>, and takes the class
from that file's C<< Class->to_app >>.

F<bin/punk> is two lines over C<< Punk::Command->main(@ARGV) >>. Commands
are specs in a registry; option parsing, generated help and the exit-code
contract (0 success, 1 application or environment failure, 2 misuse) live
in the dispatcher, so C<punk help X>, C<punk X --help> and every misuse
path read one declaration and cannot drift.

=head1 THE REGISTRY

    Punk::Command->register(greet => {
        abstract => 'one line for the command list',
        usage    => '[options]',
        desc     => 'a paragraph for the help page',
        options  => [ { spec => 'port=i', arg => 'N',
                        doc => 'listen port', default => 5000 } ],
        commands => { sync => \%subspec },     # nested verbs
        code     => sub { my ($opt, @args) = @_; ...; return 0 },
    }, __PACKAGE__);

Two owners claiming one name croak naming both. Registration order is
display order. A command body signals misuse with
C<< die { usage_error => $msg } >> (message, usage, exit 2); any other
die becomes C<punk E<lt>cmdE<gt>: msg> and exit 1.

An unknown command C<X> gets one attempt at
C<require Punk::Command::E<lt>ucfirst XE<gt>>, whose load-time job is to
call C<register> - that is how a plugin distribution adds
C<punk queue ...> when it is installed, with no scanning and no cost on
the common path.

C<register_doctor($label =E<gt> \&probe)> adds a row to the C<doctor>
report the same way.

=head2 Options resolved at run time

    extra_options => sub {
        my (@argv) = @_;
        return ( { spec => 'shout', doc => '...', owner => $class,
                   section => 'kit options (diy)' } );
    },

A command that cannot know all its options at registration - C<new>, whose
C<--kit> names a generator with options of its own - declares them through
a callback, run over the raw argv before Getopt. What it returns parses and
appears in help like the command's own, under the heading its C<section>
gives, which is what keeps generated help matching what is actually
accepted. An option that collides with one the command declared croaks
naming both.

=head1 LOADING THE APPLICATION

    my $app = Punk::Command->load_app(dir => $opt->{dir}, chdir => 1);
    my $users = $app->{registrar}->model_instance('User');

For a command in another distribution that needs the application itself and
not just its files. Loads it through its own F<app.psgi> - C<to_app> and
all, so the compiled tables are there - and returns C<root>, C<class>,
C<psgi> and C<registrar>. Dies with one line on failure, which a command
body's die already turns into a prefixed message and exit 1.

F<app.psgi> changes directory to the application root, and everything
relative in F<punk.yml> is written for that. C<chdir =E<gt> 1> leaves the
process there, which is what anything going on to open a relative C<dsn>
needs; without it the caller's directory is restored.

=head1 TESTING

    local $Punk::Command::OUT = $out_fh;    # replaces STDOUT
    local $Punk::Command::ERR = $err_fh;    # replaces STDERR
    my $code = Punk::Command->main(@argv);

C<main> returns the exit code and honours the two filehandle globals, so
a test gets code, stdout and stderr with no process spawn.

=head1 COMMANDS

=head2 new

Generates a running application; see L<Punk::Generate>. With
C<--sqitch ENGINE> it also initialises a Sqitch project for the schema
through L<Punk::Command::Sqitch> (the Punk-Sqitch distribution), so the
first model's table can be C<punk sqitch add users --model User>; the
engine is asked for because the generated F<punk.yml> ships its
C<database> block commented out.

C<--kit NAME> generates through C<Punk::Kit::E<lt>NameE<gt>> instead of the
basic skeleton, the same probe by name the command seam above uses. A kit
declares its own options, so C<punk new --kit NAME --help> lists them under
the command's own; L<Punk::Generate/KITS> is how one is written. A kit that
writes its own F<sqitch.plan> makes C<--sqitch> a no-op rather than having
Sqitch refuse a project that is already correct.

=head2 generate controller / generate model

Adds a controller or a L<Punk::Model> class to an existing application -
C<new> scaffolds once, these add to it. The application class is read from
F<app.psgi> without executing anything, so a broken controller cannot stop
you generating the fix. An existing file is refused without C<--force>.

=head2 test

Runs C<prove -lr> in the application root; extra arguments go to prove
verbatim. C<--env> sets C<PUNK_ENV> for the run.

=head2 secret

One line of random key material (url-safe base64, or C<--hex>) - the bytes
F<punk.yml>'s session secret wants behind its C<$env> reference. Nothing
else is printed, so it pipes.

=head2 version

What C<punk --version> prints: C<$Punk::VERSION>, the only version there
is.

=head2 routes

Prints method, path, target and guard count for every route, including
API operations (from their mount, since the specification is the routing
table there), websocket routes and mounted applications. Targets are
recovered from the compiled coderef, so what you see is what the route
resolved to rather than what was declared.

=head2 api sync

Adds a stub for every operation the specification declares that the
controllers do not implement, and leaves everything else alone. Methods
with no matching operation are reported, never removed. C<--dry-run>
reports without writing.

=head2 config check

Resolves C<config/punk.yml> for an environment, reporting every
C<$env>, C<$file> and C<$exec> reference independently - so one missing
secret does not hide the others - then loads it properly to apply the
guardrail. Exits non-zero when anything failed, which makes it usable as
a deployment gate.

=head2 doctor

Versions, C ABI resolution and, if run inside an application, its route
and configuration counts. Plugin rows join via L</THE REGISTRY>'s
C<register_doctor>.

=head2 console

A REPL with C<$app> (the registrar), C<$psgi> and C<$c> (a throwaway
context) in scope.

=head2 dev

Runs the application under L<Hyperman> and restarts it when anything
under F<lib/>, F<config/> or F<root/templates/> changes. A
compiled-at-boot application cannot hot-reload - there is no live
structure to patch - so restarting is the honest implementation.

=head2 serve

    punk serve
    punk serve ./public --port 3000
    punk serve --host 0.0.0.0 --list

Serves a directory of files under L<Hyperman>, on C<127.0.0.1:8000> by
default. C<dev>'s twin, and its opposite: this is the one command besides
C<new> that never looks for an application. The whole server is
C<< Punk::Static->app >>, so what it serves and how is
L<Punk::Static> - content types, C<ETag>, C<If-Modified-Since>, ranges,
precompressed C<.gz> siblings and the traversal guard, all of it.

A directory resolves to its F<index.html> (C<--index NAME> for another
name, C<--no-index> for the plain 404), and C<--list> renders a listing
for a directory that has none. Hyperman's C access log goes to stderr
unless C<--quiet>.

There is no watch-and-restart loop, unlike C<dev>: a file is read on the
request that asks for it, so there is nothing compiled to invalidate.

=head1 SEE ALSO

L<Punk>, L<Punk::Generate>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
