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
    name     => 'exit',
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

$term->add_command(@commands);

say "\n[Welcome to BSSH]";
while ( defined( my $line = $term->readline ) ) {
    $term->execute($line);
}
print "\n";
execute_exit( $term, 0 );
