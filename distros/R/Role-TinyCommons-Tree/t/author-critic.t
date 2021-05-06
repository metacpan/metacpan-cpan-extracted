#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Perl::Critic::Subset 3.001.005

use Test::Perl::Critic (-profile => "") x!! -e "";

my $filenames = ['lib/Code/Includable/Tree/FromObjArray.pm','lib/Code/Includable/Tree/FromStruct.pm','lib/Code/Includable/Tree/NodeMethods.pm','lib/Role/TinyCommons/Tree.pm','lib/Role/TinyCommons/Tree/FromObjArray.pm','lib/Role/TinyCommons/Tree/FromStruct.pm','lib/Role/TinyCommons/Tree/Node.pm','lib/Role/TinyCommons/Tree/NodeMethods.pm','lib/Test/Role/TinyCommons/Tree.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
