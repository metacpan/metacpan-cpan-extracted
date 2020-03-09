#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Perl::Critic::Subset 3.001.003

use Test::Perl::Critic (-profile => "") x!! -e "";

my $filenames = ['lib/Perl/Examples.pm','lib/Perl/Examples/Module/One.pm','lib/Perl/Examples/POD/Escape.pm','lib/Perl/Examples/POD/HTML.pm','lib/Perl/Examples/POD/Link.pm','lib/Perl/Examples/POD/Link/AmbiguousSection.pm','lib/Perl/Examples/POD/Text.pm','script/perl-example-die','script/perl-example-endless-loop','script/perl-example-grow-indefinitely','script/perl-example-print-warnings'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
