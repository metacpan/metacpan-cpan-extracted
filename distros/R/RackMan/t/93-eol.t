#!perl
use strict;
use Test::More;

plan skip_all => "author tests" unless $ENV{AUTHOR_TESTING};

plan skip_all => "Test::EOL required for testing line endings"
    unless eval "use Test::EOL; 1";

# run the selected tests
all_perl_files_ok();
