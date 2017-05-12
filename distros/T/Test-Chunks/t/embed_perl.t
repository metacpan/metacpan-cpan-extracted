# This feature allows you to put a Perl section at the top of your
# specification, between <<< and >>>. Not making this an official
# feature yet, until I decide whether I like it.

use Test::Chunks;

plan tests => 1 * chunks;

run_is x => 'y';

sub reverse { join '', reverse split '', shift }

__DATA__

<<< delimiters '+++', '***'; 
filters 'chomp';
>>>


+++ One
*** x reverse
123*
*** y
*321

+++ Two
*** x reverse
abc
*** y
cba
