#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Perl::Critic::Subset 3.001.006

use Test::Perl::Critic (-profile => "") x!! -e "";

my $filenames = ['lib/Sah/Schema/identifier.pm','lib/Sah/Schema/identifier/lc.pm','lib/Sah/Schema/identifier/lc127.pm','lib/Sah/Schema/identifier/lc15.pm','lib/Sah/Schema/identifier/lc255.pm','lib/Sah/Schema/identifier/lc31.pm','lib/Sah/Schema/identifier/lc63.pm','lib/Sah/Schema/identifier/no_u.pm','lib/Sah/Schema/identifier/no_u_delim.pm','lib/Sah/Schema/identifier/uc.pm','lib/Sah/Schema/identifier/uc127.pm','lib/Sah/Schema/identifier/uc15.pm','lib/Sah/Schema/identifier/uc255.pm','lib/Sah/Schema/identifier/uc31.pm','lib/Sah/Schema/identifier/uc63.pm','lib/Sah/Schema/identifier127.pm','lib/Sah/Schema/identifier15.pm','lib/Sah/Schema/identifier255.pm','lib/Sah/Schema/identifier31.pm','lib/Sah/Schema/identifier63.pm','lib/Sah/SchemaBundle/Identifier.pm','lib/Sah/SchemaR/identifier.pm','lib/Sah/SchemaR/identifier/lc.pm','lib/Sah/SchemaR/identifier/lc127.pm','lib/Sah/SchemaR/identifier/lc15.pm','lib/Sah/SchemaR/identifier/lc255.pm','lib/Sah/SchemaR/identifier/lc31.pm','lib/Sah/SchemaR/identifier/lc63.pm','lib/Sah/SchemaR/identifier/no_u.pm','lib/Sah/SchemaR/identifier/no_u_delim.pm','lib/Sah/SchemaR/identifier/uc.pm','lib/Sah/SchemaR/identifier/uc127.pm','lib/Sah/SchemaR/identifier/uc15.pm','lib/Sah/SchemaR/identifier/uc255.pm','lib/Sah/SchemaR/identifier/uc31.pm','lib/Sah/SchemaR/identifier/uc63.pm','lib/Sah/SchemaR/identifier127.pm','lib/Sah/SchemaR/identifier15.pm','lib/Sah/SchemaR/identifier255.pm','lib/Sah/SchemaR/identifier31.pm','lib/Sah/SchemaR/identifier63.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
