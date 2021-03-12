package
    Pinto::Remote::SelfContained::App; # hide from PAUSE

use v5.10;
use Moo;

use Getopt::Long::Descriptive qw(describe_options);
use List::Util qw(max pairgrep);
use Path::Tiny qw(path);
use Pinto::Remote::SelfContained;
use Pinto::Remote::SelfContained::Chrome;
use Pinto::Remote::SelfContained::Types qw(Uri);
use Pinto::Remote::SelfContained::Util qw(current_username);
use Types::Standard qw(ArrayRef Bool HashRef Int Maybe Str);

use namespace::clean;

our $VERSION = '1.000';

has root => (is => 'ro', isa => Uri, coerce => 1, required => 1);

has username => (is => 'ro', isa => Str, default => sub { current_username() });
has password => (is => 'ro', isa => Maybe[Str]);

has quiet => (is => 'ro', isa => Bool);
has verbose => (is => 'ro', isa => Int, default => 1);

has action_name => (is => 'ro', isa => Str, required => 1);
has args => (is => 'ro', isa => HashRef, default => sub { +{} });

my @ATTRS_FROM_OPTIONS = qw(root username password quiet verbose);

sub command_info {
    # The "args" is a string listing argument names, each optionally suffixed
    # by one of ?+* to indicate optional, required-slurpy, optional-slurpy.
    # Optional items must follow all required ones, with the exception that
    # 'foo? bar' is a permitted spec; this isn't verified.
    my %ret = (
        add => {
            summary => 'add local archives to the repository',
            usage_desc => '%c %o ARCHIVE',
            args => sub {
                my (undef, $usage) = splice @_, 0, 2;
                $usage->die({ pre_text => "Need exactly one archive\n\n" })
                    if @_ != 1;
                my $filename = $_[0];
                die "Archive filename $filename must be a tarball\n"
                    if $filename !~ /\.tar\.gz/;
                return archives => [{
                    name => 'archives',
                    filename => $filename,
                    type => 'application/x-tar',
                    encoding => 'gzip',
                }];
            },
            opt_spec => [
                [ 'author=s'                          => 'The ID of the archive author' ],
                [ 'cascade'                           => 'Always pick latest upstream package' ],
                [ 'diff-style=s'                      => 'Set style of diff reports' ],
                [ 'dry-run'                           => 'Do not commit any changes' ],
                [ 'message|m=s'                       => 'Message to describe the change' ],
                [ 'no-fail'                           => 'Do not fail when there is an error' ],
                [ 'no-index|x=s@'                     => 'Do not index matching packages' ],
                [ 'recurse!'                          => 'Recursively pull prereqs (negatable)' ],
                [ 'pin'                               => 'Pin packages to the stack' ],
                [ 'skip-missing-prerequisite|k=s@'    => 'Skip missing prereq (repeatable)' ],
                [ 'skip-all-missing-prerequisites|K'  => 'Skip all missing prereqs' ],
                [ 'stack|s=s'                         => 'Put packages into this stack' ],
                [ 'use-default-message|M'             => 'Use the generated message' ],
                [ 'with-development-prerequisites|wd' => 'Also pull prereqs for development' ],
            ],
        },
        clean => {
            summary => 'remove orphaned distribution archives',
            usage_desc => '%c %o',
            opt_spec => [],
        },
        commands => {
            pos => 10,
            summary => q[list the application's commands],
            usage_desc => '%c %o',
            opt_spec => [],
        },
        copy => {
            summary => 'create a new stack by copying another',
            usage_desc => '%c %o FROM-STACK TO-STACK',
            args => 'stack to_stack',
            opt_spec => [
                [ 'default'         => 'Make the new stack the default stack' ],
                [ 'description|d=s' => 'Brief description of the stack' ],
                [ 'lock'            => 'Lock the new stack to prevent changes' ],
            ],
        },
        default => {
            summary => 'mark the default stack',
            usage_desc => '%c %o (--none | STACK)',
            args => sub {
                my ($opts, $usage) = splice @_, 0, 2;
                $usage->die({ pre_text => "You must specify either a stack or --none\n\n" })
                    if !@_ && !$opts->{none};
                $usage->die({ pre_text => "You cannot specify both a stack and --none\n\n" })
                    if @_ && $opts->{none};
                $usage->die({ pre_text => "Too many arguments\n\n" })
                    if @_ > 1;
                return @_ ? (stack => $_[0]) : ();
            },
            opt_spec => [
                [ 'none' => 'Unmark the default stack' ],
            ],
        },
        delete => {
            summary => 'permanently remove an archive',
            usage_desc => '%c %o TARGET...',
            args => 'targets*',
            opt_spec => [
                [ 'force' => 'Delete even if packages are pinned' ],
            ],
        },
        diff => {
            summary => 'show difference between two stacks',
            usage_desc => '%c %o [LEFT] RIGHT',
            args => 'left? right',
            opt_spec => [
                [ 'diff-style=s' => 'Diff style (concise|detailed)' ],
                [ 'format=s'     => 'Format specification' ],
            ],
        },
        help => {
            pos => 20,
            summary => q[display a command's help screen],
            usage_desc => '%c %o [SUBCOMMAND]...',
            opt_spec => [],
        },
        install => {
            summary => 'install stuff from the repository',
            usage_desc => '%c %o TARGET...',
            args => sub {
                my ($opts) = splice @_, 0, 2;
                if (my $cpanm_options = $opts->{cpanm_options}) {
                    my %new;
                    for my $item (@$cpanm_options) {
                        my ($name, $value) = $item =~ /\A--?(.+?)(?:=(.*?))?\z/ms;
                        $new{$name} = $value;
                    }
                    $opts->{cpanm_options} = \%new;
                }
                $opts->{cpanm_options}{'local-lib'}           = $_ for grep defined, delete $opts->{local_lib};
                $opts->{cpanm_options}{'local-lib-contained'} = $_ for grep defined, delete $opts->{local_lib_contained};
                return targets => [@_];
            },
            opt_spec => [
                [ 'cascade'                 => 'Always pick latest upstream package' ],
                [ 'cpanm-exe|cpanm=s'       => 'Path to the cpanm executable' ],
                [ 'cpanm-options|o=s@'      => 'name=value pairs of cpanm options' ],
                [ 'diff-style=s'            => 'Set style of diff reports' ],
                [ 'local-lib|l=s'           => 'install into a local lib directory' ],
                [ 'local-lib-contained|L=s' => 'install into a contained local lib directory' ],
                [ 'message|m=s'             => 'Message to describe the change' ],
                [ 'do-pull'                 => 'pull missing prereqs onto the stack first' ],
                [ 'stack|s=s'               => 'Install modules from this stack' ],
                [ 'use-default-message|M'   => 'Use the generated message' ],
            ],
        },
        kill => {
            summary => 'permanently delete a stack',
            usage_desc => '%c %o STACK',
            args => 'stack',
            opt_spec => [
                [ 'force' => 'Kill even if stack is locked' ],
            ],
        },
        list => {
            summary => 'show the packages in a stack',
            usage_desc => '%c %o [STACK]',
            args => 'stack?',
            opt_spec => [
                [ 'all|a'             => 'List everything in the repository'],
                [ 'authors|A=s'       => 'Limit to matching author identities' ],
                [ 'distributions|D=s' => 'Limit to matching distribution names' ],
                [ 'packages|P=s'      => 'Limit to matching package names' ],
                [ 'pinned!'           => 'Limit to pinned packages (negatable)' ],
                [ 'format=s'          => 'Format specification' ],
                [ 'stack|s=s'         => 'List contents of this stack' ],
            ],
        },
        lock => {
            summary => 'mark a stack as read-only',
            usage_desc => '%c %o [STACK]',
            args => 'stack?',
            opt_spec => [
                [ 'stack|s=s' => 'Lock this stack' ],
            ],
        },
        log => {
            summary => 'show the revision logs of a stack',
            usage_desc => '%c %o [STACK]',
            args => 'stack?',
            opt_spec => [
                [ 'stack|s=s'    => 'Show history for this stack'  ],
                [ 'with-diffs|d' => 'Show a diff for each revision'],
                [ 'diff-style=s' => 'Diff style (concise|detailed)' ],
            ],
        },
        look => {
            summary => 'unpack and explore distributions with your shell',
            usage_desc => '%c %o TARGET...',
            args => 'targets+',
            opt_spec => [
                [ 'stack|s=s' => 'Resolve targets against this stack' ],
            ],
        },
        new => {
            summary => 'create a new empty stack',
            usage_desc => '%c %o STACK',
            args => 'stack',
            opt_spec => [
                [ 'default'                   => 'Make the new stack the default stack' ],
                [ 'description|d=s'           => 'Brief description of the stack' ],
                [ 'target-perl-version|tpv=s' => 'Target Perl version for this stack' ],
            ],
        },
        nop => {
            summary => 'do nothing',
            usage_desc => '%c %o',
            opt_spec => [
                [ 'sleep=i' => 'seconds to sleep before exiting' ],
            ],
        },
        pin => {
            summary => 'force a package to stay in a stack',
            usage_desc => '%c %o TARGET...',
            args => 'targets*',
            opt_spec => [
                [ 'diff-style=s'          => 'Set style of diff reports' ],
                [ 'dry-run'               => 'Do not commit any changes' ],
                [ 'message|m=s'           => 'Message to describe the change' ],
                [ 'stack|s=s'             => 'Pin targets to this stack' ],
                [ 'use-default-message|M' => 'Use the generated message' ],
            ],
        },
        props => {
            summary => 'show or set stack properties',
            usage_desc => '%c %o [STACK]',
            args => 'stack?',
            opt_spec => [
                [ 'format=s'             => 'Format specification' ],
                [ 'properties|prop|P=s%' => 'name=value pairs of properties' ],
            ],
        },
        pull => {
            summary => 'pull archives from upstream repositories',
            usage_desc => '%c %o TARGET...',
            args => 'targets*',
            opt_spec => [
                [ 'cascade'                           => 'Always pick latest upstream package' ],
                [ 'diff-style=s'                      => 'Set style of diff reports' ],
                [ 'dry-run'                           => 'Do not commit any changes' ],
                [ 'message|m=s'                       => 'Message to describe the change' ],
                [ 'no-fail'                           => 'Do not fail when there is an error' ],
                [ 'recurse!'                          => 'Recursively pull prereqs (negatable)' ],
                [ 'pin'                               => 'Pin the packages to the stack' ],
                [ 'skip-missing-prerequisite|k=s@'    => 'Skip missing prereq (repeatable)' ],
                [ 'skip-all-missing-prerequisites|K'  => 'Skip all missing prereqs' ],
                [ 'stack|s=s'                         => 'Put packages into this stack' ],
                [ 'use-default-message|M'             => 'Use the generated message' ],
                [ 'with-development-prerequisites|wd' => 'Also pull prereqs for development' ],
            ],
        },
        register => {
            summary => 'put existing packages on a stack',
            usage_desc => '%c %o TARGET...',
            args => 'targets*',
            opt_spec => [
                [ 'diff-style=s'          => 'Set style of diff reports' ],
                [ 'dry-run'               => 'Do not commit any changes' ],
                [ 'message|m=s'           => 'Message to describe the change' ],
                [ 'pin'                   => 'Pin packages to the stack' ],
                [ 'stack|s=s'             => 'Remove packages from this stack' ],
                [ 'use-default-message|M' => 'Use the generated message' ],
            ],
        },
        rename => {
            summary => 'change the name of a stack',
            usage_desc => '%c %o STACK TO-STACK',
            args => 'stack to_stack',
            opt_spec => [],
        },
        reset => {
            summary => 'reset stack to a prior revision',
            usage_desc => '%c %o [STACK] REVISION',
            args => 'stack? revision',
            opt_spec => [
                [ 'force'      => 'Reset even if revision is not ancestor' ],
                [ 'stack|s=s'  => 'Reset this stack' ],
            ],
        },
        revert => {
            summary => 'revert stack to a prior revision',
            usage_desc => '%c %o [STACK] REVISION',
            args => 'stack? revision',
            opt_spec => [
                [ 'dry-run'                   => 'Do not commit any changes' ],
                [ 'force'                     => 'Revert even if revision is not ancestor' ],
                [ 'message|m=s'               => 'Message to describe the change' ],
                [ 'stack|s=s'                 => 'Revert this stack' ],
                [ 'use-default-message|M'     => 'Use the generated message' ],
            ],
        },
        roots => {
            summary => 'show the roots of a stack',
            usage_desc => '%c %o [STACK]',
            args => 'stack?',
            opt_spec => [
                [ 'format=s'          => 'Format specification' ],
                [ 'stack|s=s'         => 'Show roots of this stack' ],
            ],
        },
        stacks => {
            summary => 'show available stacks',
            usage_desc => '%c %o',
            opt_spec => [
                [ 'format=s' => 'Format of the listing' ],
            ],
        },
        statistics => {
            summary => 'report statistics about the repository',
            usage_desc => '%c %o [STACK]',
            args => 'stack?',
            opt_spec => [],
        },
        unlock => {
            summary => 'mark a stack as writable',
            usage_desc => '%c %o [STACK]',
            args => 'stack?',
            opt_spec => [
                [ 'stack|s=s' => 'Unlock this stack' ],
            ],
        },
        unpin => {
            summary => 'free packages that have been pinned',
            usage_desc => '%c %o TARGET...',
            args => 'targets*',
            opt_spec => [
                [ 'diff-style=s'          => 'Set style of diff reports' ],
                [ 'dry-run'               => 'Do not commit any changes' ],
                [ 'message|m=s'           => 'Message to describe the change' ],
                [ 'stack|s=s'             => 'Unpin targets from this stack' ],
                [ 'use-default-message|M' => 'Use the generated message' ],
            ],
        },
        unregister => {
            summary => 'remove packages from a stack',
            usage_desc => '%c %o TARGET...',
            args => 'targets*',
            opt_spec => [
                [ 'diff-style=s'          => 'Set style of diff reports' ],
                [ 'dry-run'               => 'Do not commit any changes' ],
                [ 'force'                 => 'Remove packages even if pinned' ],
                [ 'message|m=s'           => 'Message to describe the change' ],
                [ 'stack|s=s'             => 'Remove packages from this stack' ],
                [ 'use-default-message|M' => 'Use the generated message' ],
            ],
        },
        update => {
            summary => 'update packages to latest versions',
            usage_desc => '%c %o TARGET...',
            args => 'targets*',
            opt_spec => [
                [ 'all'                               => 'Update all packages in the stack' ],
                [ 'cascade'                           => 'Always pick latest upstream package' ],
                [ 'diff-style=s'                      => 'Set style of diff reports' ],
                [ 'dry-run'                           => 'Do not commit any changes' ],
                [ 'force'                             => 'Force update, even if pinned' ],
                [ 'message|m=s'                       => 'Message to describe the change' ],
                [ 'no-fail'                           => 'Do not fail when there is an error' ],
                [ 'recurse!'                          => 'Recursively pull prereqs (negatable)' ],
                [ 'pin'                               => 'Pin the packages to the stack' ],
                [ 'roots'                             => 'Update all root packages in the stack' ],
                [ 'skip-missing-prerequisite|k=s@'    => 'Skip missing prereq (repeatable)' ],
                [ 'skip-all-missing-prerequisites|K'  => 'Skip all missing prereqs' ],
                [ 'stack|s=s'                         => 'Update packages in this stack' ],
                [ 'use-default-message|M'             => 'Use the generated message' ],
                [ 'with-development-prerequisites|wd' => 'Also pull prereqs for development' ],
            ],
        },
        verify => {
            summary => 'report archives that are missing',
            usage_desc => '%c %o',
            opt_spec => [],
        },
    );
    for my $cmd (keys %ret) {
        $ret{$cmd}{usage_desc} =~ s/^%c\K/ $cmd/;
        $ret{$cmd}{usage_desc} .= " - $ret{$cmd}{summary}";
    }
    return \%ret;
}

sub command_alias {
    +{
        cp => 'copy',
        del => 'delete',
        history => 'log',
        ls => 'list',
        mv => 'rename',
        remove => 'delete',
        rm => 'delete',
        stats => 'statistics',
        up => 'update',
    };
}

sub global_opt_spec {
    return (
        [ 'root|r=s'           => 'Path to your repository root directory (required)' ],
        [ 'color|colour!'      => '(Currently ignored)' ],
        [ 'password|p=s'       => 'Password for server authentication' ],
        [ 'quiet|q'            => 'Only report fatal errors' ],
        [ 'username|u=s'       => 'Username for server authentication' ],
        [ 'verbose|v+'         => 'More diagnostic output (repeatable)' ],
        [],
        [ 'help|?'             => 'Print usage message and exit', { shortcircuit => 1 }],
    );
}

sub help_summary {
    my ($class) = @_;

    my %command_info = %{ $class->command_info };
    my $len = max(map length, keys %command_info);
    my $fmt = "  %${len}s: %s";
    return join '',
        "Available commands:\n\n",
        map defined() ? sprintf("    %*s: %s\n", $len, $_, $command_info{$_}{summary}) : '', (
            (sort { $command_info{$a}{pos} <=> $command_info{$b}{pos} }
             grep defined $command_info{$_}{pos}, keys %command_info),
            undef,
            (grep !defined $command_info{$_}{pos}, sort keys %command_info),
        );
}

sub parse_from_argv {
    my ($class, $argv) = @_;

    my $orig_cmd = do {
        local @ARGV = @$argv;
        () = describe_options('', $class->global_opt_spec, { getopt_conf => ['gnu_getopt', 'pass_through'] });
        print($class->help_summary), exit
            if !@ARGV; # "pintor", "pintor --help", "pintor -r URL", "pintor --username fred", etc
        $ARGV[0];
    };

    my $cmd = $class->command_alias->{$orig_cmd} // $orig_cmd;
    my $command_info = $class->command_info;
    my $info = $command_info->{$cmd} // do {
        print $class->help_summary;
        exit 2;
    };

    my $usage_desc = $info->{usage_desc};
    my @opt_spec = (@{ $info->{opt_spec} }, [], $class->global_opt_spec);

    local @ARGV = @$argv;
    my ($opt, $usage) = describe_options($usage_desc, @opt_spec, { getopt_conf => ['gnu_getopt'] });

    die "BUG; cmd=$cmd but not next in argv"
        if !@ARGV || shift(@ARGV) ne $orig_cmd;

    if ($opt->help || $cmd eq 'help' && !@ARGV) {
        say $usage->text;
        exit 0;
    }
    elsif ($cmd eq 'commands') {
        print $class->help_summary;
        exit 0;
    }
    elsif ($cmd eq 'help') {
        my $exit_status = $class->run_help_command($usage, @ARGV);
        exit $exit_status;
    }
    elsif (my @missing = grep !defined $opt->{$_}, qw(root)) {
        my $missing = join ', ', map "--$_", @missing;
        $usage->die({ pre_text => "Required options not found: $missing\n\n" });
    }

    my %parsed = $class->parse_arguments($info, $opt, $usage, @ARGV);
    my %args = (%$opt, %parsed);
    my %attrs = (action_name => $cmd);
    for my $attr (@ATTRS_FROM_OPTIONS) {
        next if !exists $args{$attr};
        $attrs{$attr} = delete $args{$attr};
    }

    return %attrs, args => \%args;
}

sub run_help_command {
    my ($class, $parent_usage, @argv) = @_;

    my $command_info = $class->command_info;
    (my $usage_text = $parent_usage->text) =~ s/\n\K/\n    Global options:\n/;
    say $usage_text;

    my $exit_status = 0;
    my $command_alias = $class->command_alias;
    for my $arg (@argv) {
        my $cmd = $command_alias->{$arg} // $arg;
        my $info = $command_info->{$cmd} // do {
            warn "No command '$cmd' found\n\n";
            $exit_status = 2;
            next;
        };
        my (undef, $usage) = do {
            local @ARGV;
            describe_options($info->{usage_desc}, [], @{ $info->{opt_spec} }, {
                getopt_conf => ['gnu_getopt', 'pass_through'],
            });
        };
        say $usage->text;
    }
    return $exit_status;
}

sub parse_arguments {
    my ($class, $info, $opt, $usage, @remaining_argv) = @_;
    if (!$info->{args}) {
        $usage->die({ pre_text => "Too many arguments\n\n" })
            if @remaining_argv;
        return;
    }
    elsif (ref $info->{args}) {
        return $info->{args}->($opt, $usage, @remaining_argv);
    }
    elsif ($info->{args} =~ /^([a-z]+)\? ([a-z]+)\z/) {
        my ($optional, $required) = ($1, $2);
        $usage->die({ pre_text => "You must specify at least one argument\n\n" })
            if !@remaining_argv;
        $usage->die({ pre_text => "You must specify at most two arguments\n\n" })
            if @remaining_argv > 2;
        my %ret = ($required => pop @remaining_argv);
        $ret{$optional} = $remaining_argv[0] if @remaining_argv;
        $usage->die({ pre_text => "\u$_ specified as both option and argument\n\n" })
            for grep $opt->{$_}, sort keys %ret;
        return %ret;
    }
    else {
        my @items = split / /, $info->{args};
        my $slurpy = $items[-1] =~ /[*+]\z/ ? pop @items : undef;
        $usage->die({ pre_text => "Not enough arguments\n\n" })
            if @remaining_argv < grep !/\?\z/, @items;
        $usage->die({ pre_text => "Too many arguments\n\n" })
            if !defined $slurpy && @remaining_argv > @items;
        my %ret;
        for my $arg_name (@items) {
            $arg_name =~ s/(?<!\?)\z/?/ if exists $opt->{$arg_name};
            last if $arg_name =~ s/\?\z// && !@remaining_argv;
            $usage->die({ pre_text => "No $arg_name argument supplied\n\n" })
                if !@remaining_argv;
            $usage->die({ pre_text => "\u$arg_name supplied as both option and argument\n\n" })
                if exists $opt->{$arg_name};
            $ret{$arg_name} = shift @remaining_argv;
        }
        if (defined $slurpy) {
            $slurpy =~ s/\*\z//;
            $usage->die({ pre_text => "Need at least one $slurpy argument\n\n" })
                if $slurpy =~ s/\+\z// && !@remaining_argv;
            $usage->die({ pre_text => "$slurpy supplied as both option and argument\n\n" })
                if exists $opt->{$slurpy};
            $ret{$slurpy} = [@remaining_argv] if @remaining_argv;
        }
        return %ret;
    }
}

sub new_from_argv {
    my ($class, $argv, %attrs) = @_;
    return $class->new({ %attrs, $class->parse_from_argv($argv) });
}

sub run {
    my ($self) = @_;
    my $action_name = $self->action_name;
    my $remote = $self->make_remote_instance;
    my $result = $remote->run($action_name, $self->args);
    exit $result->exit_status;
}

sub make_remote_instance {
    my ($self) = @_;
    return Pinto::Remote::SelfContained->new(
        pairgrep { defined $b }
        root => $self->root,
        username => $self->username,
        password => $self->password,
        chrome => $self->make_chrome_instance,
    );
}

sub make_chrome_instance {
    my ($self) = @_;
    return Pinto::Remote::SelfContained::Chrome->new(
        verbose => $self->verbose,
        quiet => $self->quiet,
    );
}

1;
__END__

=head1 NAME

Pinto::Remote::SelfContained::App - app class for running Pinto commands

=head1 SYNOPSIS

    use Pinto::Remote::SelfContained::App;

    Pinto::Remote::SelfContained::App->new_from_argv(\@ARGV, %attrs)->run;
