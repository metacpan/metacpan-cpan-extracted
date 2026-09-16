#!/usr/bin/env perl
# Scrape a full-screen dialog: rows, parsed values, styles and cursor state.
use 5.010;
use strict;
use warnings;
use utf8;
use Term::Ghostty;

binmode STDOUT, ':encoding(UTF-8)';

my $term = Term::Ghostty->new(cols => 64, rows => 12);

chomp(my $dialog = <<"ANSI");
\e[1;1H\e[34m┌────────────────────── System Status ──────────────────────┐\e[0m
\e[2;1H\e[34m│\e[0m CPU Usage:  \e[32m[████████████░░░░░░░░] 60%\e[0m                    \e[34m│\e[0m
\e[3;1H\e[34m│\e[0m Memory:     \e[33m[████████████████░░░░] 80%\e[0m                    \e[34m│\e[0m
\e[4;1H\e[34m│\e[0m Disk /:     \e[32m[████░░░░░░░░░░░░░░░░] 20%\e[0m                    \e[34m│\e[0m
\e[5;1H\e[34m├───────────────────────────────────────────────────────────┤\e[0m
\e[6;1H\e[34m│\e[0m Active Task: \e[1;37mCompiling kernel modules\e[0m                     \e[34m│\e[0m
\e[7;1H\e[34m│\e[0m Elapsed:     00:04:12                                     \e[34m│\e[0m
\e[8;1H\e[34m├───────────────────────────────────────────────────────────┤\e[0m
\e[9;1H\e[34m│\e[0m Command: \e[7m[  reboot  ]\e[0m  \e[1m[  cancel  ]\e[0m                       \e[34m│\e[0m
\e[10;1H\e[34m└───────────────────────────────────────────────────────────┘\e[0m
\e[9;15H
ANSI

$term->feed($dialog);

my $text  = $term->get_text;
my @lines = split /\n/, $text;
print "1. Plain text screen:\n$text\n\n";

print "2. Rows 2 and 3:\n   $lines[1]\n   $lines[2]\n\n";

print "3. Parsed values:\n";
for my $row (@lines[1 .. 3]) {
    printf "   %-11s %s\n", "$1:", $2 if $row =~ /│ (\S[^:]*):\s+\[[^\]]*\]\s+(\d+%)/;
}
my ($task) = $text =~ /Active Task: (.+?)\s*│/;
printf "   %-11s %s\n\n", 'Task:', $task;

my ($selected) = $term->get_vt =~ /\e\[7m\[\s*(\w+)\s*\]/;
print "4. Highlighted button (reverse video in the VT output): $selected\n\n";

my ($cx, $cy) = $term->cursor_pos;
print "5. Cursor at column $cx, row $cy (0-indexed), visible: ",
    ($term->cursor_visible ? 'yes' : 'no'), "\n\n";

print "6. Screen with styles, as VT sequences:\n", $term->get_vt, "\n";
