#!perl
use 5.10.0;
use strict;
use warnings;
use Test::Most;

plan tests => 1;

BEGIN {
    use_ok('Music::VoiceGen') || print "Bail out!\n";
}

diag("Testing Music::VoiceGen $Music::VoiceGen::VERSION, Perl $], $^X");
