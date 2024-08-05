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

my $filenames = ['lib/Sah/Schema/dns/record.pm','lib/Sah/Schema/dns/record/a.pm','lib/Sah/Schema/dns/record/cname.pm','lib/Sah/Schema/dns/record/mx.pm','lib/Sah/Schema/dns/record/ns.pm','lib/Sah/Schema/dns/record/soa.pm','lib/Sah/Schema/dns/record/srv.pm','lib/Sah/Schema/dns/record/sshfp.pm','lib/Sah/Schema/dns/record/txt.pm','lib/Sah/Schema/dns/record_field/name/allow_underscore.pm','lib/Sah/Schema/dns/record_field/name/disallow_underscore.pm','lib/Sah/Schema/dns/record_of_known_types.pm','lib/Sah/Schema/dns/records.pm','lib/Sah/Schema/dns/records_of_known_types.pm','lib/Sah/Schema/dns/zone.pm','lib/Sah/SchemaBundle/DNS.pm','lib/Sah/SchemaR/dns/record.pm','lib/Sah/SchemaR/dns/record/a.pm','lib/Sah/SchemaR/dns/record/cname.pm','lib/Sah/SchemaR/dns/record/mx.pm','lib/Sah/SchemaR/dns/record/ns.pm','lib/Sah/SchemaR/dns/record/soa.pm','lib/Sah/SchemaR/dns/record/srv.pm','lib/Sah/SchemaR/dns/record/sshfp.pm','lib/Sah/SchemaR/dns/record/txt.pm','lib/Sah/SchemaR/dns/record_field/name/allow_underscore.pm','lib/Sah/SchemaR/dns/record_field/name/disallow_underscore.pm','lib/Sah/SchemaR/dns/record_of_known_types.pm','lib/Sah/SchemaR/dns/records.pm','lib/Sah/SchemaR/dns/records_of_known_types.pm','lib/Sah/SchemaR/dns/zone.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
