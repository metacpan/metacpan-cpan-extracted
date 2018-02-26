use Modern::Perl;
use FindBin;
use lib ("$FindBin::Bin/../lib");

use Term::CLI;

my $term = setup_term();

$term->read_history or warn "cannot read history: ".$term->error."\n";

while (defined(my $cmd_line = $term->readline)) {
    $term->execute($cmd_line);
}
print "\n";
execute_exit('exit', 0);

sub execute_exit {
    my ($cmd, @args) = @_;
    my $excode = $args[0] // 0;
    say "-- exit: $excode";
    exit $excode;
}

sub setup_term {
    my @commands;

    my $term = Term::CLI->new(
        name => 'bssh',
        prompt => '> ',
        skip => qr/^\s*(?:#.*)?$/,
        history_lines => 100,
    );

    push @commands, Term::CLI::Command->new(
        name => 'cp',
        arguments => [
            Term::CLI::Argument::Filename->new( name => 'src' ),
            Term::CLI::Argument::Filename->new( name => 'dst' )
        ],
        callback => sub {
            my ($cmd, %args) = @_;
            return %args if $args{status} < 0;
            my @args = @{$args{arguments}};
            say "-- ".$cmd->name.": copying $args[0] to $args[1]";
            say "(would run: cp @args)";
            return %args;
        }
    );

    push @commands, Term::CLI::Command->new(
        name => 'ls',
        arguments => [
            Term::CLI::Argument::Filename->new( name => 'arg',
                min_occur => 0, max_occur => 0
            ),
        ],
        callback => sub {
            my ($cmd, %args) = @_;
            return %args if $args{status} < 0;
            my @args = @{$args{arguments}};
            say "-- ".$cmd->name.": listing files";
            system('ls', @args);
            return %args;
        }
    );

    push @commands, Term::CLI::Command->new(
        name => 'echo',
        arguments => [
            Term::CLI::Argument::String->new( name => 'arg',
                min_occur => 0, max_occur => 0
            ),
        ],
        callback => sub {
            my ($cmd, %args) = @_;
            return %args if $args{status} < 0;
            say "@{$args{arguments}}";
            return %args;
        }
    );

    push @commands, Term::CLI::Command->new(
        name => 'exit',
        arguments => [
            Term::CLI::Argument::Number::Int->new( name => 'code',
                min_occur => 0,
                min => 0, inclusive => 1
            ),
        ],
        callback => sub {
            my ($cmd, %args) = @_;
            return %args if $args{status} < 0;
            execute_exit($cmd->name, @{$args{arguments}});
            return %args;
        }
    );

    push @commands, Term::CLI::Command->new(
        name => 'sleep',
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
            sleep($time);
            say "-- done sleeping";
            return %args;
        }
    );

    push @commands, Term::CLI::Command->new(
        name => 'make',
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

    push @commands, Term::CLI::Command::Help->new();

    $term->add_command(@commands);
    return $term;
}
