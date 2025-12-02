#!/usr/bin/env perl
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use Print::Format qw(form);

print "=== Word-Break Feature Demonstration ===\n\n";

print "Test 1: WITH comma (word-break enabled) - @<40,\n";
print "Content: '01234567890123456789012345678901234567 new word'\n";
print "Result:\n";
print form(
    '@<40,',
    '01234567890123456789012345678901234567 new word'
);
print "\n";

print "Test 2: WITHOUT comma (character-based truncation) - @<40\n";
print "Content: '01234567890123456789012345678901234567 new word'\n";
print "Result:\n";
print form(
    '@<40',
    '01234567890123456789012345678901234567 new word'
);
print "\n";

print "Test 3: WITH comma on ^ field (mutable field with word-break) - ^<30,\n";
print "Content: 'This is the description of the bug report'\n";
print "Result:\n";
print form(
    '^<30,',
    'This is the description of the bug report'
);
print "\n";

print "=== All tests completed successfully! ===\n";
