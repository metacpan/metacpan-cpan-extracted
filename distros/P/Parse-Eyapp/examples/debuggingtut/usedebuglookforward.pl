#!/usr/bin/perl -w
use strict;
use DebugLookForward;

my $prompt = 'Try first "D;S" and then "D; D;  S" '.
             '(press <CR><CTRL-D> to finish): ';
push @ARGV, '-noslurp';
DebugLookForward->main($prompt);
