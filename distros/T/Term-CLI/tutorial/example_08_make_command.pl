#!/usr/bin/env perl

use 5.014;
use warnings;

use FindBin;
use lib ("$FindBin::Bin/../lib");

use Term::CLI;

$SIG{INT} = 'IGNORE';

my $term = Term::CLI->new(
    name   => 'bssh',               # A basically simple shell.
    skip   => qr/^\s*(?:#.*)?$/,    # Skip comments and empty lines.
    prompt => 'bssh> ',             # A more descriptive prompt.
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

$term->add_command(@commands);

say "\n[Welcome to BSSH]";
while ( defined( my $line = $term->readline ) ) {
    $term->execute_line($line);
}
print "\n";
execute_exit( $term, 0 );
