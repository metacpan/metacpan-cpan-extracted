#! /usr/bin/env perl
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
);

my @commands;

my @admin_commands = subcommand('shutdown', 'reboot', 'kill');
my $admin_enabled = 0;

push @commands, Term::CLI::Command::Help->new();

push @commands, Term::CLI::Command->new(
    name => 'super',
    arguments => [
        Term::CLI::Argument::Bool->new(
            name         => 'flag',
            true_values  => ['enable',   'on'],
            false_values => ['disable', 'off'],
        ),
    ],
    callback => sub {
        my ( $self, %args ) = @_;
        return %args if $args{status} < 0;
        my $cli = $self->root_node;

        if ($args{arguments}->[0]) {
            return %args if $admin_enabled;
            $cli->add_command( @admin_commands );
            $admin_enabled++;
            say "admin enabled"; 
            return %args;
        }
        return %args if !$admin_enabled;
        $cli->delete_command(@admin_commands);
        $admin_enabled = 0;
        say "admin disabled"; 
        return %args;
    },
);

push @commands, subcommand( 'echo', 'ping' );

$cli->add_command(@commands);

while ( defined( my $input = $cli->readline(prompt => 'test> ') ) ) {
    $cli->execute( $input );
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
