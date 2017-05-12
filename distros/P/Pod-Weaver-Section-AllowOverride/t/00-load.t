#! /usr/bin/perl
#---------------------------------------------------------------------

use Test::More tests => 1;

BEGIN {
    use_ok('Pod::Weaver::Section::AllowOverride');
}

diag("Testing Pod::Weaver::Section::AllowOverride $Pod::Weaver::Section::AllowOverride::VERSION");
