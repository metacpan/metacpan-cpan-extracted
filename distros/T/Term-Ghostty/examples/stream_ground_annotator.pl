#!/usr/bin/env perl
# Insert a marker into a VT stream at every chunk boundary, once blindly and
# once only where write_until_ground() says the parser is back in ground state.
use 5.010;
use strict;
use warnings;
use Term::Ghostty;

my @chunks = (
    "Compiling...\r\n",
    "Status: \e[1;",
    "32mBUILDING\e[0m (",
    "file 1/2: \xF0\x9F",
    "\x9A\x80 launch.c)\r\n",
    "\e]2;Bu",
    "ild sta",
    "tus\a Done\r\n",
);
my $mark = "\e[7m*\e[27m";

my $naive = Term::Ghostty->new(cols => 60, rows => 4);
my $safe  = Term::Ghostty->new(cols => 60, rows => 4);

binmode STDOUT, ':encoding(UTF-8)';

for my $i (0 .. $#chunks) {
    my $chunk = $chunks[$i];
    $naive->feed($mark . $chunk);

    my ($consumed, $ground) = $safe->write_until_ground($chunk);
    $safe->feed($mark) if $ground;
    $safe->feed(substr $chunk, $consumed);

    printf "chunk %d: %s\n", $i + 1,
        $ground ? "marker inserted after $consumed byte(s)" : 'still inside a sequence, no marker';
}

print "\nBlind insertion:\n", $naive->get_text, "\n";
print "\nGround-aware insertion:\n", $safe->get_text, "\n";
print "\nTitle: ", $safe->title, " (blind: ", $naive->title, ")\n";
