#!perl -w
use strict;
use Test::More;

plan skip_all => "author tests" unless $ENV{AUTHOR_TESTING};

plan skip_all => "Test::Kwalitee required for checking distribution"
    unless eval "use Test::Kwalitee 'kwalitee_ok'; 1";

kwalitee_ok();
done_testing();

unlink "Debian_CPANTS.txt";
