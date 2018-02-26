#!/usr/bin/perl

use Modern::Perl;
use FindBin;
use lib ("$FindBin::Bin/../lib");

use Term::CLI;

$SIG{INT} = 'IGNORE';

my $term = Term::CLI->new(
    name     => 'bssh',             # A basically simple shell.
    skip     => qr/^\s*(?:#.*)?$/,  # Skip comments and empty lines.
    prompt   => 'bssh> ',           # A more descriptive prompt.
);

my @commands;

push @commands, Term::CLI::Command->new(
    name => 'exit',
    summary => 'exit B<bssh>',
    description => "Exit B<bssh> with code I<excode>,\n"
                  ."or C<0> if no exit code is given.",
    callback => sub {
        my ($cmd, %args) = @_;
        return %args if $args{status} < 0;
        execute_exit($cmd->name, @{$args{arguments}});
        return %args;
    },
    arguments => [
        Term::CLI::Argument::Number::Int->new(  # Integer
            name => 'excode',
            min => 0,             # non-negative
            inclusive => 1,       # "0" is allowed
            min_occur => 0,       # occurrence is optional
            max_occur => 1,       # no more than once
        ),
    ],
);

sub execute_exit {
    my ($cmd, $excode) = @_;
    $excode //= 0;
    say "-- $cmd: $excode";
    exit $excode;
}

push @commands, Term::CLI::Command::Help->new();

push @commands, Term::CLI::Command->new(
    name => 'echo',
    summary => 'print arguments to F<stdout>',
    description => "The C<echo> command prints its arguments\n"
                .  "to F<stdout>, separated by spaces, and\n"
                .  "terminated by a newline.\n",
    arguments => [
        Term::CLI::Argument::String->new( name => 'arg', occur => 0 ),
    ],
    callback => sub {
        my ($cmd, %args) = @_;
        return %args if $args{status} < 0;
        say "@{$args{arguments}}";
        return %args;
    }
);


push @commands, Term::CLI::Command->new(
    name => 'make',
    summary => 'make I<target> at time I<when>',
    description => "Make I<target> at time I<when>.\n"
                .  "Possible values for I<target> are:\n"
                .  "C<love>, C<money>.\n"
                .  "Possible values for I<when> are:\n"
                .  "C<now>, C<never>, C<later>, or C<forever>.",
    arguments => [
        Term::CLI::Argument::Enum->new( name => 'target',
            value_list => [qw( love money)],
        ),
        Term::CLI::Argument::Enum->new( name => 'when',
            value_list => [qw( now later never forever )],
        ),
    ],
    callback => sub {
        my ($cmd, %args) = @_;
        return %args if $args{status} < 0;
        my @args = @{$args{arguments}};
        say "making $args[0] $args[1]";
        return %args;
    }
);

push @commands, Term::CLI::Command->new(
    name => 'ls',
    summary => 'list file(s)',
    description => "List file(s) given by the arguments.\n"
                .  "If no arguments are given, the command\n"
                .  "will list the current directory.",
    arguments => [
        Term::CLI::Argument::Filename->new( name => 'arg', occur => 0 ),
    ],
    callback => sub {
        my ($cmd, %args) = @_;
        return %args if $args{status} < 0;
        my @args = @{$args{arguments}};
        system('ls', @args);
        $args{status} = $?;
        return %args;
    }
);

push @commands, Term::CLI::Command->new(
    name => 'cp',
    summary => 'copy files',
    description => "Copy files. The last argument in the\n"
                .  "list is the destination.\n",
    arguments => [
        Term::CLI::Argument::Filename->new( name => 'path',
            min_occur => 2,
            max_occur => 0
        ),
    ],
    callback => sub {
        my ($cmd, %args) = @_;
        return %args if $args{status} < 0;
        my @src = @{$args{arguments}};
        my $dst = pop @src;

        say "command:     ".$cmd->name;
        say "source:      ".join(', ', @src);
        say "destination: ".$dst;

        return %args;
    }
);

push @commands, Term::CLI::Command->new(
    name => 'sleep',
    summary => 'sleep for I<time> seconds',
    description => "Sleep for I<time> seconds.\n"
                .  "Report the actual time spent sleeping.\n"
                .  "This number can be smaller than I<time>\n"
                .  "in case of an interruption (e.g. INT signal).",
    arguments => [
        Term::CLI::Argument::Number::Int->new( name => 'time',
            min => 1, inclusive => 1
        ),
    ],
    callback => sub {
        my ($cmd, %args) = @_;
        return %args if $args{status} < 0;

        my $time = $args{arguments}->[0];

        say "-- sleep: $time";

        my %oldsig = %::SIG; # Save signals;

        # Make sure we can interrupt the sleep() call.
        $::SIG{INT} = $::SIG{QUIT} = sub {
            say STDERR "(interrupted by $_[0])";
        };

        my $slept = sleep($time);

        %::SIG = %oldsig; # Restore signal handlers.

        say "-- woke up after $slept sec", $slept == 1 ? '' : 's';
        return %args;
    }
);

push @commands, Term::CLI::Command->new(
    name => 'show',
    summary => 'show system properties',
    description => "Show some system-related information,\n"
                .  "such as the system clock or load average.",
    commands => [
        Term::CLI::Command->new( name => 'clock',
            summary => 'show system time',
            description => 'Show system time and date.',
            callback => sub {
                my ($self, %args) = @_;
                return %args if $args{status} < 0;
                say scalar(localtime);
                return %args;
            },
        ),
        Term::CLI::Command->new( name => 'load',
            summary => 'show system load',
            description => 'Show system load averages.',
            callback => sub {
                my ($self, %args) = @_;
                return %args if $args{status} < 0;
                system('uptime');
                $args{status} = $?;
                return %args;
            },
        ),
    ],
);


$term->add_command(@commands);

say "\n[Welcome to BSSH]";
while ( defined(my $line = $term->readline) ) {
    $term->execute($line);
}
print "\n";
execute_exit('exit', 0);
