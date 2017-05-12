#!perl -w
use strict;
use Test::More;


plan skip_all => "Test::Kwalitee required for checking distribution"
    unless eval "use Test::Kwalitee; 1";

eval { Test::Kwalitee->import(tests => [qw< -has_meta_yml >]) }
    or diag $@;

unlink "Debian_CPANTS.txt";
