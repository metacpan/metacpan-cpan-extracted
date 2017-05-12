use strict;
use warnings;
use Test::More;

plan( skip_all => 'Set TEST_AUTHOR to a true value to run.' )
  unless $ENV{TEST_AUTHOR};

eval {
    require Test::Kwalitee;
    # Skip the use_strict test. I always do and it missed use Moose.
    Test::Kwalitee->import( tests => [qw( -use_strict )] );
    unlink 'Debian_CPANTS.txt' if -e 'Debian_CPANTS.txt';
};
plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;

unlink 'Debian_CPANTS.txt' if -e 'Debian_CPANTS.txt';
