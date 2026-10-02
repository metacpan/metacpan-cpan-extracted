#!/usr/bin/env perl

# Generate the methods of Redis commands in lib/Redis/Namespace.pm
# from the command references of Redis and Valkey.
#
# usage:
#   perl author/generate_commands.pl [--redis path/to/commands.json] [--valkey path/to/valkey] [--valkey-version VERSION]
#
# --redis: the command reference of Redis.
#   If it is omitted, it is downloaded from $REDIS_COMMANDS_URL.
# --valkey: the source code of Valkey. The command reference is in src/commands.
#   If it is omitted, the latest release of Valkey is cloned from $VALKEY_REPOSITORY.
# --valkey-version: the version of Valkey. It is used only for the comment of the generated code.
#
# This script requires curl and git commands.
# The generated code replaces the region between the "BEGIN GENERATED COMMANDS"
# and "END GENERATED COMMANDS" markers in lib/Redis/Namespace.pm.
# The positions of keys are calculated from the key_specs of each command.
# See https://redis.io/docs/latest/develop/reference/key-specs/ for details of key_specs.

use strict;
use warnings;
use FindBin;
use JSON::PP;
use Getopt::Long;
use File::Temp qw(tempdir);

our $REDIS_COMMANDS_URL = 'https://raw.githubusercontent.com/redis/docs/refs/heads/main/data/commands.json';
our $VALKEY_REPOSITORY = 'https://github.com/valkey-io/valkey';
our $TARGET = "$FindBin::Bin/../lib/Redis/Namespace.pm";

# These commands may break other namespaces and/or change the state of redis-server.
# They are disabled in strict mode.
# A command name disables all of its sub-commands,
# and a "command sub-command" name disables only the sub-command.
our %UNSAFE_COMMANDS = map { $_ => 1 } (
    qw(
        cluster
        config
        failover
        flushall
        flushdb
        readonly
        readwrite
        replconf
        replicaof
        slaveof
        shutdown
        trimslots
    ),
    'acl deluser',
    'acl load',
    'acl save',
    'acl setuser',
    'function delete',
    'function flush',
    'function restore',
);

# The commands that have different key_specs between Redis and Valkey.
# The definitions of Redis are used for them.
our %KNOWN_DIFFERENCES = map { $_ => 1 } (
    'EXEC', # Valkey says "unknown", but EXEC takes no keys.
);

# These commands are implemented in Redis::Namespace by hand.
our %SKIP_COMMANDS = map { $_ => 1 } qw(
    subscribe
    unsubscribe
    psubscribe
    punsubscribe
);

# The code snippets for the commands that key_specs can't describe.
# "before" modifies @args, the arguments of the command.
# "after" modifies @result, the response of the command.
# If "before" is omitted, it is generated from key_specs.
my $REMOVE_NAMESPACE_FROM_FIRST = <<'CODE';
if (@result) {
    ($result[0]) = $self->rem_namespace($result[0]);
}
CODE

my $REMOVE_NAMESPACE_FROM_STREAMS = <<'CODE';
@result = map {
    ref $_ eq 'ARRAY' ? [ $self->rem_namespace($_->[0]), @{$_}[1 .. $#$_] ] : $_
} @result;
CODE

my $SORT = <<'CODE';
my @res;
if (@args) {
    push @res, $self->add_namespace(shift @args);
}
while (@args) {
    my $option = lc shift @args;
    if ($option eq 'limit') {
        my $start = shift @args;
        my $count = shift @args;
        push @res, $option, $start, $count;
    } elsif ($option eq 'by' || $option eq 'store') {
        my $key = shift @args;
        push @res, $option, $self->add_namespace($key);
    } elsif ($option eq 'get') {
        my $key = shift @args;
        ($key) = $self->add_namespace($key) unless $key eq '#';
        push @res, $option, $key;
    } else {
        push @res, $option;
    }
}
@args = @res;
CODE

our %OVERRIDES = (
    # MIGRATE host port key|"" destination-db timeout
    #   [COPY] [REPLACE] [AUTH password] [AUTH2 username password] [KEYS key [key ...]]
    # key_specs searches "KEYS" backward from the end,
    # but it can match with passwords or key names.
    migrate => {
        before => <<'CODE',
if (@args > 2) {
    # add_namespace keeps the empty string for the KEYS option as is.
    ($args[2]) = $self->add_namespace($args[2]);
}
for (my $i = 5; $i < @args; $i++) {
    my $option = lc($args[$i] // '');
    if ($option eq 'auth') {
        $i += 1;
    } elsif ($option eq 'auth2') {
        $i += 2;
    } elsif ($option eq 'keys') {
        @args[$i + 1 .. $#args] = $self->add_namespace(@args[$i + 1 .. $#args]);
        last;
    }
}
CODE
    },

    # the commands that take patterns
    keys => {
        before => <<'CODE',
if (defined $args[0]) {
    $args[0] = "$self->{namespace_escaped}:$args[0]";
}
CODE
        after => <<'CODE',
@result = $self->rem_namespace(@result);
CODE
    },
    scan => {
        before => <<'CODE',
my @res;

# first arg is iteration key
if (@args) {
    push @res, shift @args;
}

# parse options
my $has_pattern = 0;
while (@args) {
    my $option = lc shift @args;
    if ($option eq 'match') {
        my $pattern = shift @args;
        push @res, $option, "$self->{namespace_escaped}:$pattern";
        $has_pattern = 1;
    } elsif ($option eq 'count' || $option eq 'type') {
        push @res, $option, shift @args;
    } else {
        push @res, $option;
    }
}

# add pattern option
unless ($has_pattern) {
    push @res, 'match', "$self->{namespace_escaped}:*";
}
@args = @res;
CODE
        after => <<'CODE',
if (@result) {
    @result = ($result[0], [ $self->rem_namespace(@{ $result[1] || [] }) ]);
}
CODE
    },
    sort    => { before => $SORT },
    sort_ro => { before => $SORT },

    # the commands that take channels
    publish => {
        before => <<'CODE',
if (@args) {
    ($args[0]) = $self->add_namespace($args[0]);
}
CODE
    },

    # the commands that take shard channels.
    # key_specs of them have the NOT_KEY flag.
    spublish => {
        before => <<'CODE',
if (@args) {
    ($args[0]) = $self->add_namespace($args[0]);
}
CODE
    },
    ssubscribe => {
        before => <<'CODE',
@args = $self->add_namespace(@args);
CODE
    },
    sunsubscribe => {
        before => <<'CODE',
@args = $self->add_namespace(@args);
CODE
    },

    # the pattern is for command names, not for keys
    'command list' => { before => '' },

    # DEBUG OBJECT is not described in the command reference
    'debug object' => {
        before => <<'CODE',
if (@args) {
    ($args[0]) = $self->add_namespace($args[0]);
}
CODE
    },

    # the commands that return the key names
    blpop      => { after => $REMOVE_NAMESPACE_FROM_FIRST },
    brpop      => { after => $REMOVE_NAMESPACE_FROM_FIRST },
    bzpopmax   => { after => $REMOVE_NAMESPACE_FROM_FIRST },
    bzpopmin   => { after => $REMOVE_NAMESPACE_FROM_FIRST },
    blmpop     => { after => $REMOVE_NAMESPACE_FROM_FIRST },
    bzmpop     => { after => $REMOVE_NAMESPACE_FROM_FIRST },
    lmpop      => { after => $REMOVE_NAMESPACE_FROM_FIRST },
    zmpop      => { after => $REMOVE_NAMESPACE_FROM_FIRST },
    xread      => { after => $REMOVE_NAMESPACE_FROM_STREAMS },
    xreadgroup => { after => $REMOVE_NAMESPACE_FROM_STREAMS },
);

sub main {
    my %opts;
    GetOptions(\%opts, 'redis=s', 'valkey=s', 'valkey-version=s')
        or die "usage: $0 [--redis path/to/commands.json] [--valkey path/to/valkey] [--valkey-version VERSION]\n";

    my $redis = load_redis($opts{redis});
    my ($valkey, $valkey_version) = load_valkey($opts{valkey}, $opts{'valkey-version'});
    my $commands = merge_commands($redis, $valkey);

    # collect the definitions of commands
    my %defs;
    for my $name (sort keys %$commands) {
        # skip the commands of modules. e.g. JSON.GET, FT.SEARCH
        next if $name =~ /\./;

        my ($cmd, $sub, @rest) = split / /, lc $name;
        die "unexpected command name: $name\n" if @rest;
        next if $SKIP_COMMANDS{$cmd};

        # skip the commands that can't be method names. e.g. RESTORE-ASKING
        # Redis.pm treats underscores in method names as spaces,
        # so the commands that contains underscores can't be called either. e.g. BITFIELD_RO
        next unless $cmd =~ /\A[a-z0-9]+\z/;

        # the names are embedded into the generated code.
        die "unexpected sub-command name: $name\n" if defined $sub && $sub !~ /\A[a-z0-9_-]+\z/;

        my $def = build_definition($name, $commands->{$name}, defined $sub ? 1 : 0)
            or next;
        if (defined $sub) {
            $defs{$cmd}{subcommands}{$sub} = $def;
        } else {
            $defs{$cmd}{command} = $def;
        }
    }

    # the sub-commands that are not described in the command reference
    for my $name (sort keys %OVERRIDES) {
        my ($cmd, $sub) = split / /, $name;
        next unless defined $sub;
        $defs{$cmd}{subcommands}{$sub} //= build_definition(uc $name, {}, 1);
    }

    my $code = render_header($valkey_version);
    for my $cmd (sort keys %defs) {
        my $def = $defs{$cmd};
        if ($def->{subcommands}) {
            $code .= render_container($cmd, $def->{subcommands});
            for my $sub (sort keys %{$def->{subcommands}}) {
                next unless $sub =~ /\A[a-z0-9]+\z/;
                $code .= render_command("${cmd}_$sub", $def->{subcommands}{$sub}, $cmd, $sub);
            }
        } else {
            $code .= render_command($cmd, $def->{command}, $cmd);
        }
    }
    $code .= render_footer();

    my $source = read_file($TARGET);
    $source =~ s/^# BEGIN GENERATED COMMANDS\n.*?^# END GENERATED COMMANDS\n/$code/sm
        or die "markers are not found in $TARGET\n";
    write_file($TARGET, $source);
}

# load_redis loads the command reference of Redis.
sub load_redis {
    my $path = shift;
    unless (defined $path) {
        my $dir = tempdir(CLEANUP => 1);
        $path = "$dir/commands.json";
        run('curl', '-sSfL', '-o', $path, $REDIS_COMMANDS_URL);
    }
    return JSON::PP->new->utf8->decode(read_file($path));
}

# load_valkey loads the command reference of Valkey,
# and converts it into the same format as Redis.
sub load_valkey {
    my ($dir, $version) = @_;
    unless (defined $dir) {
        $version //= latest_valkey_version();
        $dir = tempdir(CLEANUP => 1);
        run('git', '-c', 'advice.detachedHead=false', 'clone', '--quiet', '--depth', '1',
            '--branch', $version, '--filter=blob:none', '--sparse', $VALKEY_REPOSITORY, $dir);
        run('git', '-C', $dir, 'sparse-checkout', 'set', 'src/commands');
    }
    $version //= 'unknown';
    die "unexpected version of Valkey: $version\n" unless $version =~ /\A[0-9A-Za-z.-]+\z/;

    my %commands;
    # don't use glob here, it splits the pattern at whitespaces.
    my $commands_dir = "$dir/src/commands";
    opendir my $dh, $commands_dir or die "failed to open $commands_dir: $!\n";
    my @files = sort grep { /\.json\z/ } readdir $dh;
    closedir $dh;

    for my $file (@files) {
        my $json = JSON::PP->new->utf8->decode(read_file("$commands_dir/$file"));
        for my $name (keys %$json) {
            my $info = $json->{$name};

            # skip the commands only for Sentinel
            next if grep { $_ eq 'ONLY_SENTINEL' } @{$info->{command_flags} || []};

            my $fullname = $info->{container} ? "$info->{container} $name" : $name;
            $commands{uc $fullname} = {
                key_specs => [ map { convert_valkey_key_spec($fullname, $_) } @{$info->{key_specs} || []} ],
                arguments => $info->{arguments} || [],
            };
        }
    }
    die "no commands are found in $commands_dir\n" unless %commands;
    return \%commands, $version;
}

# latest_valkey_version returns the latest release of Valkey.
sub latest_valkey_version {
    my @versions =
        sort { version_cmp($a, $b) }
        grep { /\A[0-9]+\.[0-9]+\.[0-9]+\z/ }
        map { m{\trefs/tags/(.*)\z} ? $1 : () }
        split /\n/, run('git', 'ls-remote', '--tags', '--refs', $VALKEY_REPOSITORY);
    die "no releases of Valkey are found\n" unless @versions;
    return $versions[-1];
}

sub version_cmp {
    my @a = split /\./, shift;
    my @b = split /\./, shift;
    return $a[0] <=> $b[0] || $a[1] <=> $b[1] || $a[2] <=> $b[2];
}

# convert_valkey_key_spec converts a key_spec of Valkey into the format of Redis.
# e.g. {"index": {"pos": 1}} => {"type": "index", "spec": {"index": 1}}
sub convert_valkey_key_spec {
    my ($name, $spec) = @_;
    my @begin = %{$spec->{begin_search} || {}};
    my @find = %{$spec->{find_keys} || {}};
    die "unexpected key_specs in $name\n" unless @begin == 2 && @find == 2;

    my ($begin_type, $begin_spec) = @begin;
    my %begin = (type => $begin_type, spec => {});
    if ($begin_type eq 'index') {
        $begin{spec} = { index => $begin_spec->{pos} };
    } elsif ($begin_type eq 'keyword') {
        $begin{spec} = { keyword => $begin_spec->{keyword}, startfrom => $begin_spec->{startfrom} };
    }

    my ($find_type, $find_spec) = @find;
    my %find = (type => $find_type, spec => {});
    if ($find_type eq 'range') {
        $find{spec} = { lastkey => $find_spec->{lastkey}, keystep => $find_spec->{step}, limit => $find_spec->{limit} };
    } elsif ($find_type eq 'keynum') {
        $find{spec} = { keynumidx => $find_spec->{keynumidx}, firstkey => $find_spec->{firstkey}, keystep => $find_spec->{step} };
    }

    my %result = (begin_search => \%begin, find_keys => \%find);
    $result{not_key} = JSON::PP::true if grep { $_ eq 'NOT_KEY' } @{$spec->{flags} || []};
    return \%result;
}

# merge_commands merges the command references of Redis and Valkey.
sub merge_commands {
    my ($redis, $valkey) = @_;
    my %commands = %$redis;
    for my $name (sort keys %$valkey) {
        unless ($redis->{$name}) {
            $commands{$name} = $valkey->{$name};
            next;
        }
        my $r = key_specs_signature($redis->{$name});
        my $v = key_specs_signature($valkey->{$name});
        next if $r eq $v || $KNOWN_DIFFERENCES{$name};
        die "key_specs of $name are different between Redis and Valkey:\n  Redis:  $r\n  Valkey: $v\n";
    }
    return \%commands;
}

# key_specs_signature returns a string that represents the positions of keys.
sub key_specs_signature {
    my $info = shift;
    my $json = JSON::PP->new->canonical;
    return $json->encode([ map {
        my $spec = $_;
        {
            begin_search => $spec->{begin_search},
            find_keys    => $spec->{find_keys},
            not_key      => $spec->{not_key} ? 1 : 0,
        };
    } @{$info->{key_specs} || []} ]);
}

# build_definition returns the code snippets of the command.
sub build_definition {
    my ($name, $info, $offset) = @_;
    my $override = $OVERRIDES{lc $name} || {};

    my $before = $override->{before};
    unless (defined $before) {
        $before = key_specs_code($name, $info, $offset);
        return unless defined $before;
    }

    return {
        name   => $name,
        before => $before,
        after  => $override->{after} // '',
    };
}

# key_specs_code generates the code that adds the namespace to the keys
# from key_specs of the command.
sub key_specs_code {
    my ($name, $info, $offset) = @_;

    # NOT_KEY means that the argument is not a key. e.g. the cursor of CLUSTERSCAN
    my @specs = grep { !$_->{not_key} } @{$info->{key_specs} || []};

    unless (@specs) {
        # the commands that take patterns or channels without key_specs
        # are not namespaced correctly by the automatic generation.
        my @suspicious = grep {
            $_->{type} eq 'key' || $_->{type} eq 'pattern' || $_->{name} =~ /channel/
        } flatten_arguments($info->{arguments} || []);
        if (@suspicious) {
            warn "skip $name: it has key-like arguments, but no key_specs\n";
            return;
        }
        return '';
    }

    # simple case: the command takes only one key.
    if (@specs == 1 && $specs[0]{begin_search}{type} eq 'index'
        && $specs[0]{find_keys}{type} eq 'range' && int_field($name, $specs[0]{find_keys}{spec}{lastkey}) == 0) {
        my $i = index_field($name, $specs[0]{begin_search}{spec}{index}, $offset);
        return <<"CODE";
if (\@args > $i) {
    (\$args[$i]) = \$self->add_namespace(\$args[$i]);
}
CODE
    }

    # simple case: the keys are not overlapped.
    if (@specs == 1) {
        my $code = key_spec_code($name, $specs[0], $offset, sub {
            my $i = shift;
            return "(\$args[$i]) = \$self->add_namespace(\$args[$i]);\n";
        });
        return unless defined $code;
        return $code;
    }

    # general case: collect the positions of the keys, and then add the namespace.
    my $code = "my \@positions;\n";
    for my $spec (@specs) {
        my $c = key_spec_code($name, $spec, $offset, sub {
            my $i = shift;
            return "push \@positions, $i;\n";
        });
        return unless defined $c;
        $code .= $c =~ /^my /m ? "{\n" . indent($c) . "}\n" : $c;
    }
    $code .= <<'CODE';
my %seen;
for my $i (grep { !$seen{$_}++ } @positions) {
    ($args[$i]) = $self->add_namespace($args[$i]);
}
CODE
    return $code;
}

# key_spec_code generates the code for a key_spec.
# It follows the implementation of getKeysUsingKeySpecs in Redis.
# The indexes in key_specs count the command name (and the sub-command name),
# but the indexes of @args don't.
sub key_spec_code {
    my ($name, $spec, $offset, $emit) = @_;
    my $begin = $spec->{begin_search};
    my $find = $spec->{find_keys};

    my $code = '';
    my $first;
    my $close = '';
    if ($begin->{type} eq 'index') {
        $first = index_field($name, $begin->{spec}{index}, $offset);
    } elsif ($begin->{type} eq 'keyword') {
        my $keyword = lc($begin->{spec}{keyword} // '');
        die "unexpected keyword in $name: $keyword\n" unless $keyword =~ /\A[a-z0-9_-]+\z/;
        my $startfrom = int_field($name, $begin->{spec}{startfrom});
        my $loop;
        if ($startfrom >= 0) {
            my $start = $startfrom - 1 - $offset;
            $loop = "for (my \$i = $start; \$i < \@args; \$i++)";
        } else {
            $loop = "for (my \$i = \@args - @{[-$startfrom]}; \$i >= 0; \$i--)";
        }
        $code .= <<"CODE";
my \$first;
$loop {
    if (lc(\$args[\$i] // '') eq '$keyword') {
        \$first = \$i + 1;
        last;
    }
}
if (defined \$first) {
CODE
        $first = '$first';
        $close = "}\n";
    } else {
        warn "skip $name: unknown begin_search type: $begin->{type}\n";
        return;
    }

    my $body;
    if ($find->{type} eq 'range') {
        my $lastkey = int_field($name, $find->{spec}{lastkey});
        my $keystep = step_field($name, $find->{spec}{keystep});
        my $limit = int_field($name, $find->{spec}{limit});
        my $last;
        if ($lastkey >= 0) {
            $last = add($first, $lastkey);
        } elsif ($limit <= 1) {
            $last = '';
        } else {
            my $count = 'int((@args - ' . $first . ') / ' . $limit . ')';
            $last = add($first, $count) . ' - ' . (-$lastkey);
        }
        if ($lastkey == 0) {
            $body = "if (\@args > $first) {\n" . indent($emit->($first)) . "}\n";
        } else {
            my $step = $keystep == 1 ? '$i++' : "\$i += $keystep";
            my $cond = $last eq ''
                ? ($lastkey == -1 ? '$i < @args' : "\$i < \@args - @{[-$lastkey - 1]}")
                : "\$i <= $last && \$i < \@args";
            $body = "for (my \$i = $first; $cond; $step) {\n"
                . indent($emit->('$i')) . "}\n";
        }
    } elsif ($find->{type} eq 'keynum') {
        my $keynumidx = add($first, int_field($name, $find->{spec}{keynumidx}));
        my $firstkey = add($first, int_field($name, $find->{spec}{firstkey}));
        my $keystep = step_field($name, $find->{spec}{keystep});
        my $step = $keystep == 1 ? '$i++' : "\$i += $keystep";
        my $numkeys = $keystep == 1 ? '$numkeys' : "\$numkeys * $keystep";
        $body = <<"CODE" . indent(indent($emit->('$i'))) . "    }\n}\n";
my \$numkeys = \$args[$keynumidx];
if (defined \$numkeys && \$numkeys =~ /\\A[0-9]+\\z/) {
    for (my \$i = $firstkey; \$i < $firstkey + $numkeys && \$i < \@args; $step) {
CODE
    } else {
        warn "skip $name: unknown find_keys type: $find->{type}\n";
        return;
    }

    if ($close) {
        return $code . indent($body) . $close;
    }
    return $code . $body;
}

sub render_header {
    my $valkey_version = shift;
    return <<"CODE";
# BEGIN GENERATED COMMANDS
# This section is generated by author/generate_commands.pl from
# - $REDIS_COMMANDS_URL
# - $VALKEY_REPOSITORY/tree/$valkey_version/src/commands
# DO NOT EDIT.

## no critic (Subroutines::ProhibitBuiltinHomonyms)
CODE
}

sub render_footer {
    return <<'CODE';

## use critic
# END GENERATED COMMANDS
CODE
}

# render_unsafe_check renders the code that rejects unsafe commands in strict mode.
sub render_unsafe_check {
    my @names = @_;
    for my $name (@names) {
        return "croak \"unsafe command '$name'\" if \$self->{strict};\n" if $UNSAFE_COMMANDS{$name};
    }
    return '';
}

sub render_command {
    my ($method, $def, $cmd, $sub) = @_;
    my $code = "\n# $def->{name}\n";
    $code .= "sub $method {\n";
    $code .= "    my (\$self, \@args) = \@_;\n";
    $code .= indent(render_unsafe_check($cmd, defined $sub ? "$cmd $sub" : ()));
    $code .= indent(render_body($def, "\$self->{redis}->$method("));
    $code .= "}\n";
    return $code;
}

sub render_container {
    my ($cmd, $subcommands) = @_;
    my $upper = uc $cmd;
    my $code = "\n# $upper\n";
    $code .= "sub $cmd {\n";
    $code .= "    my (\$self, \@args) = \@_;\n";
    $code .= indent(render_unsafe_check($cmd));
    $code .= "    return \$self->{redis}->$cmd(\@args) if !\@args || ref \$args[0];\n";
    $code .= "\n";
    $code .= "    my \$subcommand = lc \$args[0];\n";

    # group the sub-commands by their bodies
    my %groups;
    my @order;
    for my $sub (sort keys %$subcommands) {
        my $def = $subcommands->{$sub};
        my $body;
        if ($def->{before} eq '' && $def->{after} eq '') {
            $body = "return \$self->{redis}->$cmd(\@args);\n";
        } else {
            $body = "my \$name = shift \@args;\n"
                . render_body($def, "\$self->{redis}->$cmd(\$name, ");
        }
        $body = render_unsafe_check("$cmd $sub") . $body;
        push @order, $body unless $groups{$body};
        push @{$groups{$body}}, $sub;
    }

    for my $body (@order) {
        my @subs = @{$groups{$body}};
        $code .= "\n";
        $code .= "    # " . join(', ', map { "$upper \U$_" } @subs) . "\n" if @subs <= 3;
        if (@subs == 1) {
            $code .= "    if (\$subcommand eq '$subs[0]') {\n";
        } else {
            $code .= "    if (\n";
            $code .= join " ||\n", map { "        \$subcommand eq '$_'" } @subs;
            $code .= "\n    ) {\n";
        }
        $code .= indent(indent($body));
        $code .= "    }\n";
    }

    $code .= <<"CODE";

    croak "unknown command '$cmd \$args[0]'" if \$self->{strict};
    carp "unknown command '$cmd \$args[0]'. passing arguments to the redis server as is.";
    return \$self->{redis}->$cmd(\@args);
}
CODE
    return $code;
}

# render_body renders the body of the command.
# $call is the code to call the command of Redis.pm without the arguments. e.g. "$self->{redis}->get("
sub render_body {
    my ($def, $call) = @_;
    my $before = $def->{before};
    my $after = $def->{after};

    if ($before eq '' && $after eq '') {
        return "return $call\@args);\n";
    }

    my $code = "my \$cb = \@args && ref \$args[-1] eq 'CODE' ? pop \@args : undef;\n";
    $code .= "\n$before" if $before ne '';

    if ($after eq '') {
        $code .= "\n";
        $code .= "push \@args, \$cb if \$cb;\n";
        $code .= "return $call\@args);\n";
        return $code;
    }

    $code .= "\n";
    $code .= "my \$after = sub {\n";
    $code .= "    my \@result = \@_;\n";
    $code .= indent($after);
    $code .= "    return \@result;\n";
    $code .= "};\n";
    $code .= "if (\$cb) {\n";
    $code .= "    return $call\@args, sub {\n";
    $code .= "        my (\$result, \$error) = \@_;\n";
    $code .= "        \$result = [ \$after->(\@\$result) ] if ref \$result eq 'ARRAY';\n";
    $code .= "        \$cb->(\$result, \$error);\n";
    $code .= "    });\n";
    $code .= "}\n";
    $code .= "return \$after->($call\@args)) if wantarray;\n";
    $code .= "my \$result = $call\@args);\n";
    $code .= "return ref \$result eq 'ARRAY' ? [ \$after->(\@\$result) ] : \$result;\n";
    return $code;
}

# The values of key_specs are embedded into the generated code.
# Validate them to avoid generating broken or malicious code.
sub int_field {
    my ($name, $value) = @_;
    die "unexpected integer in $name: " . ($value // 'undef') . "\n"
        unless defined $value && $value =~ /\A-?[0-9]+\z/;
    return $value;
}

# the index of @args from the index in key_specs
sub index_field {
    my ($name, $value, $offset) = @_;
    my $index = int_field($name, $value) - 1 - $offset;
    die "unexpected index in $name: $value\n" if $index < 0;
    return $index;
}

# the step of loops. it must be positive to avoid infinite loops.
sub step_field {
    my ($name, $value) = @_;
    my $step = int_field($name, $value);
    die "unexpected step in $name: $value\n" if $step < 1;
    return $step;
}

sub flatten_arguments {
    my $args = shift;
    return map { ($_, flatten_arguments($_->{arguments} || [])) } @$args;
}

# add returns the code of "$a + $b". it is folded if possible.
sub add {
    my ($a, $b) = @_;
    return $a + $b if $a =~ /\A-?[0-9]+\z/ && $b =~ /\A-?[0-9]+\z/;
    return $a if $b eq '0';
    return "$a + $b";
}

sub indent {
    my $code = shift;
    $code =~ s/^(?=.)/    /mg;
    return $code;
}

# run runs the command, and returns its output.
sub run {
    my @command = @_;
    open my $fh, '-|', @command or die "failed to run @command: $!\n";
    local $/;
    my $output = <$fh> // '';
    close $fh or die "failed to run @command: exit status $?\n";
    return $output;
}

sub read_file {
    my $path = shift;
    open my $fh, '<:raw', $path or die "failed to open $path: $!\n";
    local $/;
    return scalar <$fh>;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>:raw', $path or die "failed to open $path: $!\n";
    print $fh $content;
    close $fh;
}

main(@ARGV);
