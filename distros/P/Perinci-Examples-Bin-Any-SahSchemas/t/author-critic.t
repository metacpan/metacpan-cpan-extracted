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

my $filenames = ['lib/Perinci/Examples/Bin/Any/SahSchemas.pm','script/peri-eg-schema-bandwidth','script/peri-eg-schema-date','script/peri-eg-schema-dirname','script/peri-eg-schema-filename','script/peri-eg-schema-filesize','script/peri-eg-schema-pathname','script/peri-eg-schema-perl-distname','script/peri-eg-schema-perl-modname'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
