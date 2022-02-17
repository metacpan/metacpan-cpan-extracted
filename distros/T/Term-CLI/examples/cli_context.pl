#! /usr/bin/env perl
#
# Demo script by djerius to demonstrate the use of "CLI context", a la Cisco
# routers.
#
use 5.014;
use warnings;
use FindBin;

use lib "$FindBin::Bin/../lib";

use Term::CLI;
use Term::CLI::L10N 'loc';
use Scalar::Util qw( refaddr );

my $cli = Term::CLI->new(
    name     => 'test',
    prompt   => 'test> ',
    skip     => qr/^\s*$/,
    commands => [ Term::CLI::Command::Help->new, Loop() ],
);

while ( defined( my $input = $cli->readline(prompt => 'test> ') ) ) {
    my %args = eval { $cli->execute( $input ); };
    say STDERR loc("ERROR"), "#0: ", $args{error} if $args{status} < 0;
    say $@ if $@ ne '';
}

sub Loop {

    Term::CLI::Command->new(
        name     => 'loop',
        commands => [
            Term::CLI::Command::Help->new(),
            subcommand( 'copy', 'move', 'exit' ),
        ],
        require_sub_command => 0,
        summary  => 'Sub-command mode test',
        callback => sub {
            my ( $self, %args ) = @_;

            # no-op if there actually was a subcommand.
            # Compare $self to the last command in $args{command_path}.
            # $args{command_path}[-1] === $self if $self is the leaf node.
            return %args
              if $args{status} < 0
                    || refaddr( $self ) != refaddr( $args{command_path}[-1] );

            while ( my $input = $self->readline( prompt => $self->name . '> ' ) ) {
                my %args = eval {
                    $self->execute_line( $input );
                };
                say STDERR $@ if $@ ne '';
                # handle our own errors.
                say STDERR loc("ERROR"), "#1: ", $args{error} if $args{status} < 0;
                last if $args{command_path}[-1]{name} eq 'exit';
            }
            return %args;
        },
    );
}

# create some no-op subcommands
sub subcommand {

    map {
        my $name = $_;
        Term::CLI::Command->new(
            name     => $name,
            summary  => "\F$name something",
            callback => sub {
                my ( $self, %args ) = @_;
                say "\F$name...";
                return %args;
            } )
    } @_;
}
