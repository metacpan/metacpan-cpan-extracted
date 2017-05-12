#! /usr/bin/perl

use strict;
use warnings;
use 5.010;
use Regexp::Grammars;

my $grammar = qr{

    <delimited_text>

    <token: delimited_text>
        qq? <delim> <text=(.*?)> </delim>
    |   <matchpos> qq? <delim>
        <error: (?{"Unterminated string starting at index $MATCH{matchpos}"})>

    <token: delim>  [[:punct:]]++

}x;

use IO::Prompter;

while (my $input = prompt) {
    if ($input =~ $grammar) {
        use Data::Show;
        show %/;
    }
    else {
        say 'Failed: ';
        say for @!;
    }
}
