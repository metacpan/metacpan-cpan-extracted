#!/usr/bin/env perl

# Demonstrates multiline input: pressing return on a line that doesn't
# look "complete" (ends in a semicolon, or is blank, or starts with
# "exit") inserts a newline and keeps editing instead of accepting the
# line, similar to how many REPLs behave.

use strict;
use warnings;
use Term::EditLine qw( CC_NEWLINE CC_REFRESH );

my $el = Term::EditLine->new('myprompt');
$el->set_prompt('myprompt> ');
$el->add_fun('accept', 'accept', sub {
    $el->insertstr("\n");
    my ($line) = $el->line;
    if ($line =~ /^\s*$|;$|^\s*exit\b/) {
        return CC_NEWLINE;
    }
    else {
        return CC_REFRESH;
    }
});
$el->parse('bind', '-e');
$el->parse('bind', "\e[A", 'ed-search-prev-history');
$el->parse('bind', "\e[B", 'ed-search-next-history');
$el->parse('bind', "\r", 'accept');
$el->parse('bind', "\n", 'accept');
$el->history_load("$ENV{HOME}/.myprompt_history");

while (1) {
    $_ = $el->gets();
    print "\n";
    last if !defined $_ || /^\s*exit\b/;
    next if !/\S/;
    s/\s*;\s*$/;/;
    $el->history_enter($_);
    print "OK! $_\n";
}

$el->history_save("$ENV{HOME}/.myprompt_history");
