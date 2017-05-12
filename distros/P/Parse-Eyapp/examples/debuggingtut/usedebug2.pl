#!/usr/bin/perl -w
use strict;
use Debug2;

my $prompt = 'Try first "D;S" and then "D; D;  S" '.
             '(press <CR><CTRL-D> to finish): ';
Debug2->main($prompt);
