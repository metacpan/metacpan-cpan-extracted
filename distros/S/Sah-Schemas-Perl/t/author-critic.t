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

my $filenames = ['lib/Data/Sah/Coerce/perl/To_array/From_str_or_array/expand_perl_modname_wildcard.pm','lib/Data/Sah/Coerce/perl/To_array/From_str_or_array/expand_perl_modprefix_wildcard.pm','lib/Data/Sah/Coerce/perl/To_obj/From_str/perl_version.pm','lib/Data/Sah/Coerce/perl/To_str/From_str/convert_perl_pm_or_pod_to_path.pm','lib/Data/Sah/Coerce/perl/To_str/From_str/convert_perl_pm_to_path.pm','lib/Data/Sah/Coerce/perl/To_str/From_str/convert_perl_pod_or_pm_to_path.pm','lib/Data/Sah/Coerce/perl/To_str/From_str/convert_perl_pod_to_path.pm','lib/Data/Sah/Coerce/perl/To_str/From_str/normalize_perl_distname.pm','lib/Data/Sah/Coerce/perl/To_str/From_str/normalize_perl_modname.pm','lib/Data/Sah/Coerce/perl/To_str/From_str/normalize_perl_modname_or_prefix.pm','lib/Data/Sah/Coerce/perl/To_str/From_str/normalize_perl_modprefix.pm','lib/Data/Sah/Filter/perl/Perl/check_module_installed.pm','lib/Data/Sah/Filter/perl/Perl/check_module_not_installed.pm','lib/Data/Sah/Filter/perl/Perl/normalize_perl_modname.pm','lib/Data/Sah/Value/perl/Perl/these_dists.pm','lib/Data/Sah/Value/perl/Perl/these_mods.pm','lib/Data/Sah/Value/perl/Perl/this_dist.pm','lib/Data/Sah/Value/perl/Perl/this_mod.pm','lib/Sah/Schema/perl/distname.pm','lib/Sah/Schema/perl/distname/default_this_dist.pm','lib/Sah/Schema/perl/distname_with_optional_ver.pm','lib/Sah/Schema/perl/distname_with_ver.pm','lib/Sah/Schema/perl/filename.pm','lib/Sah/Schema/perl/funcname.pm','lib/Sah/Schema/perl/modargs.pm','lib/Sah/Schema/perl/modname.pm','lib/Sah/Schema/perl/modname/default_this_mod.pm','lib/Sah/Schema/perl/modname/installed.pm','lib/Sah/Schema/perl/modname/not_installed.pm','lib/Sah/Schema/perl/modname_or_prefix.pm','lib/Sah/Schema/perl/modname_with_optional_args.pm','lib/Sah/Schema/perl/modname_with_optional_ver.pm','lib/Sah/Schema/perl/modname_with_ver.pm','lib/Sah/Schema/perl/modnames.pm','lib/Sah/Schema/perl/modprefix.pm','lib/Sah/Schema/perl/modprefixes.pm','lib/Sah/Schema/perl/pm_filename.pm','lib/Sah/Schema/perl/pod_filename.pm','lib/Sah/Schema/perl/pod_or_pm_filename.pm','lib/Sah/Schema/perl/podname.pm','lib/Sah/Schema/perl/qualified_funcname.pm','lib/Sah/Schema/perl/release/version.pm','lib/Sah/Schema/perl/unqualified_funcname.pm','lib/Sah/Schema/perl/version.pm','lib/Sah/SchemaR/perl/distname.pm','lib/Sah/SchemaR/perl/distname/default_this_dist.pm','lib/Sah/SchemaR/perl/distname_with_optional_ver.pm','lib/Sah/SchemaR/perl/distname_with_ver.pm','lib/Sah/SchemaR/perl/filename.pm','lib/Sah/SchemaR/perl/funcname.pm','lib/Sah/SchemaR/perl/modargs.pm','lib/Sah/SchemaR/perl/modname.pm','lib/Sah/SchemaR/perl/modname/default_this_mod.pm','lib/Sah/SchemaR/perl/modname/installed.pm','lib/Sah/SchemaR/perl/modname/not_installed.pm','lib/Sah/SchemaR/perl/modname_or_prefix.pm','lib/Sah/SchemaR/perl/modname_with_optional_args.pm','lib/Sah/SchemaR/perl/modname_with_optional_ver.pm','lib/Sah/SchemaR/perl/modname_with_ver.pm','lib/Sah/SchemaR/perl/modnames.pm','lib/Sah/SchemaR/perl/modprefix.pm','lib/Sah/SchemaR/perl/modprefixes.pm','lib/Sah/SchemaR/perl/pm_filename.pm','lib/Sah/SchemaR/perl/pod_filename.pm','lib/Sah/SchemaR/perl/pod_or_pm_filename.pm','lib/Sah/SchemaR/perl/podname.pm','lib/Sah/SchemaR/perl/qualified_funcname.pm','lib/Sah/SchemaR/perl/release/version.pm','lib/Sah/SchemaR/perl/unqualified_funcname.pm','lib/Sah/SchemaR/perl/version.pm','lib/Sah/Schemas/Perl.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
