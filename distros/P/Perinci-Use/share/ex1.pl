#!/usr/bin/perl

use 5.010;
use Perinci::Use "pl:/Perinci/Examples/" => "sum";

say sum(array => [1, 2, 3, 4])->[2];
