#!/usr/bin/env perl

# See https://robots.thoughtbot.com/tab-completion-in-gnu-readline

use 5.014_001;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Data::Dumper;
use Term::CLI;
use Term::CLI::Command;
use Term::CLI::Argument::Filename;
use Term::CLI::Argument::Number::Float;
use Term::CLI::Argument::Enum;
use Term::CLI::Argument::String;
use Term::CLI::L10N;

my $test_1_cmd = Term::CLI::Command->new(
    name => 'test_1',
    summary => 'test 0..2 enum argument',
    description => 'Test enum argument appearing 0..2 times.',
    arguments => [
        Term::CLI::Argument::Enum->new(name => 'arg',
            value_list => [qw( one two three four )],
            min_occur => 0,
            max_occur => 2
        ),
    ]
);

my $test_2_cmd = Term::CLI::Command->new(
    name => 'test_2',
    summary => 'test 1 or more enum argument',
    description => "Test the 'one or more' enum argument construct.",
    arguments => [
        Term::CLI::Argument::Enum->new(name => 'arg',
            value_list => [qw( one two three four )],
            min_occur => 1,
            max_occur => 0
        ),
    ],
);

my $copy_cmd = Term::CLI::Command->new(
    name => 'cp',
    summary => "copy file",
    description => "Copy file I<src> to I<dst>.",
    options => ['verbose|v', 'debug|d', 'interactive|i', 'force|f'],
    arguments => [
        Term::CLI::Argument::Filename->new(name => 'src'),
        Term::CLI::Argument::Filename->new(name => 'dst'),
    ],
);

my $move_cmd = Term::CLI::Command->new(
    name => 'mv',
    summary => "move file",
    description => "Move file/directory I<src> to I<dst>.",
    options => ['verbose|v', 'debug|d', 'interactive|i', 'force|f'],
    arguments => [
        Term::CLI::Argument::Filename->new(name => 'src'),
        Term::CLI::Argument::Filename->new(name => 'dst'),
    ],
);

my $info_cmd = Term::CLI::Command->new(
    name => 'info',
    summary => "show file information",
    description => "Show information about I<file>.",
    options => ['verbose|v', 'version|V', 'dry-run|D', 'debug|d'],
    arguments => [
        Term::CLI::Argument::Filename->new(name => 'file')
    ],
);

my $file_cmd = Term::CLI::Command->new(
    name => 'file',
    summary => 'file operations',
    description => "Various file operations.",
    options => ['verbose|v', 'version|V', 'dry-run|D', 'debug|d'],
    commands =>  [
        $copy_cmd, $move_cmd, $info_cmd
    ],
);

my $sleep_cmd = Term::CLI::Command->new(
    name => 'sleep',
    summary => "rest your weary head",
    description => "Sleep for I<time> seconds.",
    options => ['verbose|v', 'debug|d'],
    arguments => [
        Term::CLI::Argument::Number::Float->new(
            name => 'time', min => 0, inclusive => 0
        ),
    ],
);

my $make_cmd = Term::CLI::Command->new(
    name => 'make',
    summary => "make stuff",
    description => "Make I<thing> at time I<when>.",
    options => ['verbose|v', 'debug|d'],
    arguments => [
        Term::CLI::Argument::Enum->new(
            name => 'thing', value_list => [qw( money love )]
        ),
        Term::CLI::Argument::Enum->new(
            name => 'when', value_list => [qw( always now later never )]
        ),
    ],
);


my $set_cmd = Term::CLI::Command->new(
    name => 'set',
    summary => 'set CLI parameters',
    description => 'Set various CLI parameters.',
    commands => [
        Term::CLI::Command->new(
            name => 'delimiter',
            summary => 'set word delimiter',
            description => 'Set the word delimiter to I<delimiter>.',
            arguments => [
                Term::CLI::Argument::String->new(name => 'delimiter')
            ],
            callback => sub {
                my ($self, %args) = @_;
                return %args if $args{status} < 0;
                my $args = $args{arguments};
                my $delimiters = $args->[0];
                my $path = $args{command_path};
                $path->[0]->word_delimiters($delimiters);
                return %args;
            }
        ),
        Term::CLI::Command->new(
            name => 'quote',
            summary => 'set argument quote character',
            description => 'Set the quote character for arguments to I<quote>',
            arguments => [
                Term::CLI::Argument::String->new(name => 'quote')
            ],
            callback => sub {
                my ($self, %args) = @_;
                return %args if $args{status} < 0;
                my $args = $args{arguments};
                my $quote_chars = $args->[0];
                my $path = $args{command_path};
                $path->[0]->quote_characters($quote_chars);
                return %args;
            }
        ),
        Term::CLI::Command->new(
            name => 'verbose',
            summary => 'set verbose flag',
            description => 'Set the verbose flag for the program.',
            arguments => [
                Term::CLI::Argument::Bool->new(name => 'bool',
                    true_values  => [qw( 1 true on yes ok )],
                    false_values => [qw( 1 false off no never )],
                )

            ],
            callback => sub {
                my ($self, %args) = @_;
                return %args if $args{status} < 0;
                my $args = $args{arguments};
                my $bool = $args->[0];
                say "Setting verbose to $bool";
                return %args;
            }
        ),
    ],
);


my @commands = (
    $file_cmd, $sleep_cmd, $make_cmd, $set_cmd,
    $test_1_cmd, $test_2_cmd,
    Term::CLI::Command::Help->new(),
);

my $cli = Term::CLI->new(
    prompt => $FindBin::Script.'> ',
    commands => \@commands,
    callback => sub {
        my $self = shift;
        my %args = @_;

        my $command_path = $args{command_path};
        #say "path:", map { " ".$_->name } @$command_path;

        if ($args{status} < 0) {
            say "** ", loc("ERROR"), ": $args{error}";
            say "(status: $args{status})";
            $self->prompt("ERR[$args{status}]> ");
            return %args;
        }
        elsif ($args{status} == 0) {
            $self->prompt('OK> ');
        }
        else {
            $self->prompt("ERR[$args{status}]> ");
        }

        #say "options: ";
        #while (my ($k, $v) = each %{$args{options}}) {
            #say "   --$k => $v";
        ##}
        #say "arguments:", map {" '$_'"} @{$args{arguments}};
        return %args;
    }
);

#say "TEST: " . $cli->_commands . " <=> " . \@commands;
#
#for my $cmd ($cli->commands) {
#    say $cmd->name." parent ".$cmd->parent->name;
#}

while (my $input = $cli->readline(skip => qr/^\s*(?:#.*)?$/)) {
    $cli->execute($input);
}
