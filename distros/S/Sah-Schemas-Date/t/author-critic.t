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

my $filenames = ['lib/Data/Sah/Coerce/perl/To_int/From_str/convert_en_dow_name_to_num.pm','lib/Data/Sah/Coerce/perl/To_int/From_str/convert_en_month_name_to_num.pm','lib/Data/Sah/Coerce/perl/To_int/From_str/tz_offset_strings.pm','lib/Perinci/Sub/XCompletion/date_dow_num.pm','lib/Perinci/Sub/XCompletion/date_dow_nums.pm','lib/Perinci/Sub/XCompletion/date_month_num.pm','lib/Perinci/Sub/XCompletion/date_month_nums.pm','lib/Sah/Schema/date/day.pm','lib/Sah/Schema/date/dow_name/en.pm','lib/Sah/Schema/date/dow_num.pm','lib/Sah/Schema/date/dow_nums.pm','lib/Sah/Schema/date/hour.pm','lib/Sah/Schema/date/minute.pm','lib/Sah/Schema/date/month/en.pm','lib/Sah/Schema/date/month_name/en.pm','lib/Sah/Schema/date/month_num.pm','lib/Sah/Schema/date/month_nums.pm','lib/Sah/Schema/date/second.pm','lib/Sah/Schema/date/tz_name.pm','lib/Sah/Schema/date/tz_offset.pm','lib/Sah/Schema/date/tz_offset_lax.pm','lib/Sah/Schema/date/year.pm','lib/Sah/Schema/datetime/default_end_of_last_month_local.pm','lib/Sah/Schema/datetime/default_end_of_last_month_utc.pm','lib/Sah/Schema/datetime/default_end_of_yesterday_local.pm','lib/Sah/Schema/datetime/default_end_of_yesterday_utc.pm','lib/Sah/Schema/datetime/default_start_of_this_month_local.pm','lib/Sah/Schema/datetime/default_start_of_this_month_utc.pm','lib/Sah/Schema/datetime/default_start_of_today_local.pm','lib/Sah/Schema/datetime/default_start_of_today_utc.pm','lib/Sah/SchemaR/date/day.pm','lib/Sah/SchemaR/date/dow_name/en.pm','lib/Sah/SchemaR/date/dow_num.pm','lib/Sah/SchemaR/date/dow_nums.pm','lib/Sah/SchemaR/date/hour.pm','lib/Sah/SchemaR/date/minute.pm','lib/Sah/SchemaR/date/month/en.pm','lib/Sah/SchemaR/date/month_name/en.pm','lib/Sah/SchemaR/date/month_num.pm','lib/Sah/SchemaR/date/month_nums.pm','lib/Sah/SchemaR/date/second.pm','lib/Sah/SchemaR/date/tz_name.pm','lib/Sah/SchemaR/date/tz_offset.pm','lib/Sah/SchemaR/date/tz_offset_lax.pm','lib/Sah/SchemaR/date/year.pm','lib/Sah/SchemaR/datetime/default_end_of_last_month_local.pm','lib/Sah/SchemaR/datetime/default_end_of_last_month_utc.pm','lib/Sah/SchemaR/datetime/default_end_of_yesterday_local.pm','lib/Sah/SchemaR/datetime/default_end_of_yesterday_utc.pm','lib/Sah/SchemaR/datetime/default_start_of_this_month_local.pm','lib/Sah/SchemaR/datetime/default_start_of_this_month_utc.pm','lib/Sah/SchemaR/datetime/default_start_of_today_local.pm','lib/Sah/SchemaR/datetime/default_start_of_today_utc.pm','lib/Sah/Schemas/Date.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
