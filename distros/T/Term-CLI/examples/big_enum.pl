#!/usr/bin/env perl
#
# Demonstrate the efficiency of enum matching on
# large enum lists.
#

use 5.014_001;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Term::CLI;

my $term = setup_term();

while (defined(my $cmd_line = $term->readline)) {
    $term->execute($cmd_line);
}
print "\n";

sub setup_term {
    my @commands;

    my $wordfile = "$FindBin::Bin/wordlist-en.txt";
    open my $fh, '<', $wordfile or die "$wordfile: $!\n";
    chomp( my @words = (<$fh>) );
    my %words = map { $_ => 1 } @words;

    $fh->close;

    my $term = Term::CLI->new(
        name => 'words',
        prompt => '> ',
        skip => qr/^\s*(?:#.*)?$/,
        history_lines => 100,
    );

    push @commands, Term::CLI::Command->new(
        name => 'info',
        callback => sub {
            my ($cmd, %args) = @_;
            return %args if $args{status} < 0;
            say "word count: ", int(@words);
            return %args;
        }
    );

    push @commands, Term::CLI::Command->new(
        name => 'echo',
        arguments => [
            Term::CLI::Argument::Enum->new(
                name => 'word',
                value_list => \@words,
                max_occur  => 0,
            ),
        ],
        callback => sub {
            my ($cmd, %args) = @_;
            return %args if $args{status} < 0;
            say "@{$args{arguments}}";
            return %args;
        }
    );

    push @commands, Term::CLI::Command::Help->new();

    $term->add_command(@commands);
    return $term;
}
