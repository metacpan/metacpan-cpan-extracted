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

my $filenames = ['lib/Data/Sah/Coerce/perl/To_float/From_str/suffix_datasize.pm','lib/Data/Sah/Coerce/perl/To_float/From_str/suffix_dataspeed.pm','lib/Data/Size/Suffix/Datasize.pm','lib/Data/Size/Suffix/Dataspeed.pm','lib/Sah/Schema/bandwidth.pm','lib/Sah/Schema/dataquota.pm','lib/Sah/Schema/datasize.pm','lib/Sah/Schema/dataspeed.pm','lib/Sah/Schema/filesize.pm','lib/Sah/SchemaBundle/DataSizeSpeed.pm','lib/Sah/SchemaR/bandwidth.pm','lib/Sah/SchemaR/dataquota.pm','lib/Sah/SchemaR/datasize.pm','lib/Sah/SchemaR/dataspeed.pm','lib/Sah/SchemaR/filesize.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
