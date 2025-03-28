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

my $filenames = ['lib/Data/Sah/Coerce/perl/To_obj/From_str/net_ipv4.pm','lib/Sah/Schema/net/hostname.pm','lib/Sah/Schema/net/ipv4.pm','lib/Sah/Schema/net/port.pm','lib/Sah/SchemaR/net/hostname.pm','lib/Sah/SchemaR/net/ipv4.pm','lib/Sah/SchemaR/net/port.pm','lib/Sah/Schemas/Net.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
