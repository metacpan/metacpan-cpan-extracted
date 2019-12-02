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

my $filenames = ['lib/Data/Sah/Coerce/perl/To_int/From_str/convert_en_or_id_dow_name_to_num.pm','lib/Data/Sah/Coerce/perl/To_int/From_str/convert_en_or_id_month_name_to_num.pm','lib/Data/Sah/Coerce/perl/To_int/From_str/convert_id_dow_name_to_num.pm','lib/Data/Sah/Coerce/perl/To_int/From_str/convert_id_month_name_to_num.pm','lib/Perinci/Sub/XCompletion/date_dow_num_en_or_id.pm','lib/Perinci/Sub/XCompletion/date_dow_num_id.pm','lib/Perinci/Sub/XCompletion/date_dow_nums_en_or_id.pm','lib/Perinci/Sub/XCompletion/date_dow_nums_id.pm','lib/Perinci/Sub/XCompletion/date_month_num_en_or_id.pm','lib/Perinci/Sub/XCompletion/date_month_num_id.pm','lib/Perinci/Sub/XCompletion/date_month_nums_en_or_id.pm','lib/Perinci/Sub/XCompletion/date_month_nums_id.pm','lib/Sah/Schema/date/dow_name/id.pm','lib/Sah/Schema/date/dow_num/en_or_id.pm','lib/Sah/Schema/date/dow_num/id.pm','lib/Sah/Schema/date/dow_nums/en_or_id.pm','lib/Sah/Schema/date/dow_nums/id.pm','lib/Sah/Schema/date/month/id.pm','lib/Sah/Schema/date/month_name/id.pm','lib/Sah/Schema/date/month_num/en_or_id.pm','lib/Sah/Schema/date/month_num/id.pm','lib/Sah/Schema/date/month_nums/en_or_id.pm','lib/Sah/Schema/date/month_nums/id.pm','lib/Sah/SchemaR/date/dow_name/id.pm','lib/Sah/SchemaR/date/dow_num/en_or_id.pm','lib/Sah/SchemaR/date/dow_num/id.pm','lib/Sah/SchemaR/date/dow_nums/en_or_id.pm','lib/Sah/SchemaR/date/dow_nums/id.pm','lib/Sah/SchemaR/date/month/id.pm','lib/Sah/SchemaR/date/month_name/id.pm','lib/Sah/SchemaR/date/month_num/en_or_id.pm','lib/Sah/SchemaR/date/month_num/id.pm','lib/Sah/SchemaR/date/month_nums/en_or_id.pm','lib/Sah/SchemaR/date/month_nums/id.pm','lib/Sah/Schemas/Date/ID.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
