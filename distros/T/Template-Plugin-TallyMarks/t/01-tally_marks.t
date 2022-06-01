#!/usr/bin/perl
use warnings;
use strict;

use Template;
use Test::More;


(my $tt = 'Template'->new)->process(\'[% USE TallyMarks %]');

my %test = ( 0  => q(),
             1  => '|',
             2  => '||',
             4  => '||||',
             5  => '<s>||||</s>',
             6  => '<s>||||</s>&nbsp;|',
             10 => '<s>||||</s>&nbsp;<s>||||</s>',
             12 => '<s>||||</s>&nbsp;<s>||||</s>&nbsp;||',
            );

my $template = '[% n | tally_marks %]';

for my $n (sort { $a <=> $b } keys %test) {
    $tt->process(\$template, { n => $n }, \ my $result);

    is $result, $test{$n}, "tally_marks $n";
}

done_testing(scalar keys %test);
