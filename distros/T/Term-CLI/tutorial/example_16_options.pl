#!/usr/bin/env perl

use 5.014;
use warnings;

use FindBin;
use lib ("$FindBin::Bin/../lib");
use Data::Dumper;

use Term::CLI;

$SIG{INT} = 'IGNORE';

my $term = Term::CLI->new(
    name    => 'bssh',               # A basically simple shell.
    skip    => qr/^\s*(?:#.*)?$/,    # Skip comments and empty lines.
    prompt  => 'bssh> ',             # A more descriptive prompt.
    cleanup => sub {
        my ($term) = @_;
        $term->write_history()
            or warn "cannot write history: " . $term->error . "\n";
    },
);

my @commands;

push @commands, Term::CLI::Command->new(
    name        => 'exit',
    summary     => 'exit B<bssh>',
    description => "Exit B<bssh> with code I<excode>,\n"
        . "or C<0> if no exit code is given.",
    callback => sub {
        my ( $cmd, %args ) = @_;
        return %args if $args{status} < 0;
        execute_exit( $cmd, @{ $args{arguments} } );
        return %args;
    },
    arguments => [
        Term::CLI::Argument::Number::Int->new(    # Integer
            name      => 'excode',
            min       => 0,          # non-negative
            inclusive => 1,          # "0" is allowed
            min_occur => 0,          # occurrence is optional
            max_occur => 1,          # no more than once
        ),
    ],
);

sub execute_exit {
    my ( $cmd, $excode ) = @_;
    $excode //= 0;
    say "-- exit: $excode";
    exit $excode;
}

push @commands, Term::CLI::Command::Help->new();

push @commands, Term::CLI::Command->new(
    name        => 'echo',
    summary     => 'print arguments to F<stdout>',
    description => "The C<echo> command prints its arguments\n"
        . "to F<stdout>, separated by spaces, and\n"
        . "terminated by a newline.\n",
    arguments =>
        [ Term::CLI::Argument::String->new( name => 'arg', occur => 0 ), ],
    callback => sub {
        my ( $cmd, %args ) = @_;
        return %args if $args{status} < 0;
        say "@{$args{arguments}}";
        return %args;
    }
);

push @commands, Term::CLI::Command->new(
    name        => 'make',
    summary     => 'make I<target> at time I<when>',
    description => "Make I<target> at time I<when>.\n"
        . "Possible values for I<target> are:\n"
        . "C<love>, C<money>.\n"
        . "Possible values for I<when> are:\n"
        . "C<now>, C<never>, C<later>, or C<forever>.",
    arguments => [
        Term::CLI::Argument::Enum->new(
            name       => 'target',
            value_list => [qw( love money )],
        ),
        Term::CLI::Argument::Enum->new(
            name       => 'when',
            value_list => [qw( now later never forever )],
        ),
    ],
    callback => sub {
        my ( $cmd, %args ) = @_;
        return %args if $args{status} < 0;
        my @args = @{ $args{arguments} };
        say "making $args[0] $args[1]";
        return %args;
    }
);

push @commands, Term::CLI::Command->new(
    name        => 'ls',
    summary     => 'list file(s)',
    description => "List file(s) given by the arguments.\n"
        . "If no arguments are given, the command\n"
        . "will list the current directory.",
    arguments =>
        [ Term::CLI::Argument::Filename->new( name => 'arg', occur => 0 ), ],
    callback => sub {
        my ( $cmd, %args ) = @_;
        return %args if $args{status} < 0;
        my @args = @{ $args{arguments} };
        system( 'ls', @args );
        $args{status} = $?;
        return %args;
    }
);

push @commands, Term::CLI::Command->new(
    name        => 'cp',
    summary     => 'copy files',
    description => "Copy files. The last argument in the\n"
        . "list is the destination.\n",
    arguments => [
        Term::CLI::Argument::Filename->new(
            name      => 'path',
            min_occur => 2,
            max_occur => 0
        ),
    ],
    callback => sub {
        my ( $cmd, %args ) = @_;
        return %args if $args{status} < 0;
        my @src = @{ $args{arguments} };
        my $dst = pop @src;

        say "command:     " . $cmd->name;
        say "source:      " . join( ', ', @src );
        say "destination: " . $dst;

        return %args;
    }
);

push @commands, Term::CLI::Command->new(
    name        => 'sleep',
    summary     => 'sleep for I<time> seconds',
    description => "Sleep for I<time> seconds.\n"
        . "Report the actual time spent sleeping.\n"
        . "This number can be smaller than I<time>\n"
        . "in case of an interruption (e.g. INT signal).",
    arguments => [
        Term::CLI::Argument::Number::Int->new(
            name      => 'time',
            min       => 1,
            inclusive => 1
        ),
    ],
    callback => sub {
        my ( $cmd, %args ) = @_;
        return %args if $args{status} < 0;

        my $time = $args{arguments}->[0];

        say "-- sleep: $time";

        # Make sure we can interrupt the sleep() call.
        my $slept = do {
            local ( $::SIG{INT} ) = local ( $::SIG{QUIT} ) = sub {
                say STDERR "(interrupted by $_[0])";
            };
            sleep($time);
        };

        say "-- woke up after $slept sec", $slept == 1 ? '' : 's';
        return %args;
    }
);

push @commands, Term::CLI::Command->new(
    name        => 'show',
    options     => ['verbose|v'],
    summary     => 'show system properties',
    description => "Show some system-related information,\n"
        . "such as the system clock or load average.",
    commands => [
        Term::CLI::Command->new(
            name        => 'clock',
            options     => ['timezone|tz|t=s'],
            summary     => 'show system time',
            description => 'Show system time and date.',
            callback    => \&do_show_clock,
        ),
        Term::CLI::Command->new(
            name        => 'load',
            summary     => 'show system load',
            description => 'Show system load averages.',
            callback    => sub {
                my ( $self, %args ) = @_;
                return %args if $args{status} < 0;
                system('uptime');
                $args{status} = $?;
                return %args;
            },
        ),
        Term::CLI::Command->new(
            name        => 'terminal',
            summary     => 'show terminal information',
            description => 'Show terminal information.',
            callback    => sub {
                my ( $self, %args ) = @_;
                return %args if $args{status} < 0;
                my ( $rows, $cols ) = $self->root_node->term->get_screen_size;
                say "type $ENV{TERM}; rows $rows; columns $cols";
                $args{status} = 0;
                return %args;
            },
        ),
    ],
);

sub do_show_clock {
    my ( $self, %args ) = @_;
    return %args if $args{status} < 0;
    my $opt = $args{options};

    local ( $::ENV{TZ} );
    if ( $opt->{timezone} ) {
        $::ENV{TZ} = $opt->{timezone};
    }
    say scalar(localtime);
    return %args;
}

push @commands, Term::CLI::Command->new(
    name        => 'set',
    summary     => 'set CLI parameters',
    description => 'Set various CLI parameters.',
    commands    => [
        Term::CLI::Command->new(
            name        => 'delimiters',
            summary     => 'set word delimiter(s)',
            description => 'Set the word delimiter(s) to I<string>.',
            arguments   =>
                [ Term::CLI::Argument::String->new( name => 'string' ) ],
            callback => sub {
                my ( $self, %args ) = @_;
                return %args if $args{status} < 0;
                my $delimiters = $args{arguments}->[0];
                $self->root_node->word_delimiters($delimiters);
                say "Delimiters set to [$delimiters]";
                return %args;
            }
        ),
        Term::CLI::Command->new(
            name        => 'verbose',
            summary     => 'set verbose flag',
            description => 'Set the verbose flag for the program.',
            arguments   => [
                Term::CLI::Argument::Bool->new(
                    name         => 'bool',
                    true_values  => [qw( 1 true on yes ok )],
                    false_values => [qw( 1 false off no never )],
                )

            ],
            callback => sub {
                my ( $self, %args ) = @_;
                return %args if $args{status} < 0;
                my $bool = $args{arguments}->[0];
                say "Setting verbose to $bool";
                return %args;
            }
        ),
    ],
);

push @commands, Term::CLI::Command->new(
    name        => 'do',
    summary     => 'Do I<action> while I<activity>',
    description => "Do I<action> while I<activity>.\n"
        . "Possible values for I<action> are:\n"
        . "C<nothing>, C<something>.\n"
        . "Possible values for I<activity> are:\n"
        . "C<sleeping>, C<working>.",
    arguments => [
        Term::CLI::Argument::Enum->new(
            name       => 'action',
            value_list => [qw( something nothing )],
        ),
    ],
    commands => [
        Term::CLI::Command->new(
            name      => 'while',
            arguments => [
                Term::CLI::Argument::Enum->new(
                    name       => 'activity',
                    value_list => [qw( eating sleeping )],
                ),
            ],
        ),
    ],
    callback => sub {
        my ( $cmd, %args ) = @_;
        return %args if $args{status} < 0;
        my @args = @{ $args{arguments} };
        say "doing $args[0] while $args[1]";
        return %args;
    }
);

push @commands, Term::CLI::Command->new(
    name        => 'interface',
    summary     => 'Turn I<iface> up or down',
    description => "Turn the I<iface> interface up or down.",
    arguments   => [ Term::CLI::Argument::String->new( name => 'iface' ) ],
    commands    => [
        Term::CLI::Command->new(
            name        => 'up',
            summary     => 'Bring I<iface> up',
            description => 'Bring the I<iface> interface up.',
            callback    => sub {
                my ( $cmd, %args ) = @_;
                return %args if $args{status} < 0;
                my @args = @{ $args{arguments} };
                say "bringing up $args[0]";
                return %args;
            }
        ),
        Term::CLI::Command->new(
            name        => 'down',
            summary     => 'Shut down I<iface>',
            description => 'Shut down the I<iface> interface.',
            callback    => sub {
                my ( $cmd, %args ) = @_;
                return %args if $args{status} < 0;
                my @args = @{ $args{arguments} };
                say "shutting down $args[0]";
                return %args;
            }
        ),
    ],
);

push @commands, Term::CLI::Command->new(
    name        => 'debug',
    usage       => 'B<debug> I<cmd> ...',
    summary     => 'debug commands',
    description => "Print some debugging information regarding\n"
        . "the execution of I<cmd>.",
    commands => \@commands,
    callback => sub {
        my ( $cmd, %args ) = @_;
        my @args = @{ $args{arguments} };
        say "# --- DEBUG ---";
        my $d = Data::Dumper->new( [ \%args ], [qw(args)] );
        print $d->Maxdepth(2)->Indent(1)->Terse(1)->Dump;
        say "# --- DEBUG ---";
        return %args;
    }
);

$term->add_command(@commands);

$term->read_history();

say "\n[Welcome to BSSH]";
while ( defined( my $line = $term->readline ) ) {
    $term->execute($line);
}
print "\n";
execute_exit( $term, 0 );
