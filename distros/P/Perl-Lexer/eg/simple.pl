#!/usr/bin/env perl
use strict;
use warnings;
use Perl::Lexer;

my $version;
my $p = Getopt::Long::Parser->new(
    config => [qw(posix_default no_ignore_case auto_help)]
);
$p->getoptions(
    'e=s'       => \my $eval,
);

my $lexer = Perl::Lexer->new();
my @tokens = do {
    @{$lexer->scan_fh(*STDIN)};
};
for (@tokens) {
    print $_->inspect, "\n";
}
