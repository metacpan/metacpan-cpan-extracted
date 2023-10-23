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

my $filenames = ['lib/Data/Sah/Filter/perl/Str/maybe_convert_to_re.pm','lib/Data/Sah/Filter/perl/Str/maybe_eval.pm','lib/Sah/Schema/hexstr.pm','lib/Sah/Schema/latin_alpha.pm','lib/Sah/Schema/latin_alphanum.pm','lib/Sah/Schema/latin_letter.pm','lib/Sah/Schema/latin_lowercase_alpha.pm','lib/Sah/Schema/latin_lowercase_letter.pm','lib/Sah/Schema/latin_uppercase_alpha.pm','lib/Sah/Schema/latin_uppercase_letter.pm','lib/Sah/Schema/lowercase_str.pm','lib/Sah/Schema/non_empty_str.pm','lib/Sah/Schema/percent_str.pm','lib/Sah/Schema/str1.pm','lib/Sah/Schema/str_or_aos.pm','lib/Sah/Schema/str_or_aos1.pm','lib/Sah/Schema/str_or_code.pm','lib/Sah/Schema/str_or_re.pm','lib/Sah/Schema/str_or_re_or_code.pm','lib/Sah/Schema/uppercase_str.pm','lib/Sah/SchemaR/hexstr.pm','lib/Sah/SchemaR/latin_alpha.pm','lib/Sah/SchemaR/latin_alphanum.pm','lib/Sah/SchemaR/latin_letter.pm','lib/Sah/SchemaR/latin_lowercase_alpha.pm','lib/Sah/SchemaR/latin_lowercase_letter.pm','lib/Sah/SchemaR/latin_uppercase_alpha.pm','lib/Sah/SchemaR/latin_uppercase_letter.pm','lib/Sah/SchemaR/lowercase_str.pm','lib/Sah/SchemaR/non_empty_str.pm','lib/Sah/SchemaR/percent_str.pm','lib/Sah/SchemaR/str1.pm','lib/Sah/SchemaR/str_or_aos.pm','lib/Sah/SchemaR/str_or_aos1.pm','lib/Sah/SchemaR/str_or_code.pm','lib/Sah/SchemaR/str_or_re.pm','lib/Sah/SchemaR/str_or_re_or_code.pm','lib/Sah/SchemaR/uppercase_str.pm','lib/Sah/Schemas/Str.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
