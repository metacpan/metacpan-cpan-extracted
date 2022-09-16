use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 74 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Data/Sah/Coerce/perl/To_array/From_str_or_array/expand_perl_modname_wildcard.pm',
    'Data/Sah/Coerce/perl/To_array/From_str_or_array/expand_perl_modprefix_wildcard.pm',
    'Data/Sah/Coerce/perl/To_obj/From_str/perl_version.pm',
    'Data/Sah/Coerce/perl/To_str/From_str/convert_perl_pm_or_pod_to_path.pm',
    'Data/Sah/Coerce/perl/To_str/From_str/convert_perl_pm_to_path.pm',
    'Data/Sah/Coerce/perl/To_str/From_str/convert_perl_pod_or_pm_to_path.pm',
    'Data/Sah/Coerce/perl/To_str/From_str/convert_perl_pod_to_path.pm',
    'Data/Sah/Coerce/perl/To_str/From_str/normalize_perl_distname.pm',
    'Data/Sah/Coerce/perl/To_str/From_str/normalize_perl_modname.pm',
    'Data/Sah/Coerce/perl/To_str/From_str/normalize_perl_modname_or_prefix.pm',
    'Data/Sah/Coerce/perl/To_str/From_str/normalize_perl_modprefix.pm',
    'Data/Sah/Filter/perl/Perl/check_module_installed.pm',
    'Data/Sah/Filter/perl/Perl/check_module_not_installed.pm',
    'Data/Sah/Filter/perl/Perl/normalize_perl_modname.pm',
    'Data/Sah/Filter/perl/Perl/normalize_perl_modname_pm.pm',
    'Data/Sah/Value/perl/Perl/these_dists.pm',
    'Data/Sah/Value/perl/Perl/these_mods.pm',
    'Data/Sah/Value/perl/Perl/this_dist.pm',
    'Data/Sah/Value/perl/Perl/this_mod.pm',
    'Sah/Schema/perl/distname.pm',
    'Sah/Schema/perl/distname/default_this_dist.pm',
    'Sah/Schema/perl/distname_with_optional_ver.pm',
    'Sah/Schema/perl/distname_with_ver.pm',
    'Sah/Schema/perl/filename.pm',
    'Sah/Schema/perl/funcname.pm',
    'Sah/Schema/perl/modargs.pm',
    'Sah/Schema/perl/modname.pm',
    'Sah/Schema/perl/modname/default_this_mod.pm',
    'Sah/Schema/perl/modname/installed.pm',
    'Sah/Schema/perl/modname/not_installed.pm',
    'Sah/Schema/perl/modname_or_prefix.pm',
    'Sah/Schema/perl/modname_pm.pm',
    'Sah/Schema/perl/modname_with_optional_args.pm',
    'Sah/Schema/perl/modname_with_optional_ver.pm',
    'Sah/Schema/perl/modname_with_ver.pm',
    'Sah/Schema/perl/modnames.pm',
    'Sah/Schema/perl/modprefix.pm',
    'Sah/Schema/perl/modprefixes.pm',
    'Sah/Schema/perl/pm_filename.pm',
    'Sah/Schema/perl/pod_filename.pm',
    'Sah/Schema/perl/pod_or_pm_filename.pm',
    'Sah/Schema/perl/podname.pm',
    'Sah/Schema/perl/qualified_funcname.pm',
    'Sah/Schema/perl/release/version.pm',
    'Sah/Schema/perl/unqualified_funcname.pm',
    'Sah/Schema/perl/version.pm',
    'Sah/SchemaR/perl/distname.pm',
    'Sah/SchemaR/perl/distname/default_this_dist.pm',
    'Sah/SchemaR/perl/distname_with_optional_ver.pm',
    'Sah/SchemaR/perl/distname_with_ver.pm',
    'Sah/SchemaR/perl/filename.pm',
    'Sah/SchemaR/perl/funcname.pm',
    'Sah/SchemaR/perl/modargs.pm',
    'Sah/SchemaR/perl/modname.pm',
    'Sah/SchemaR/perl/modname/default_this_mod.pm',
    'Sah/SchemaR/perl/modname/installed.pm',
    'Sah/SchemaR/perl/modname/not_installed.pm',
    'Sah/SchemaR/perl/modname_or_prefix.pm',
    'Sah/SchemaR/perl/modname_pm.pm',
    'Sah/SchemaR/perl/modname_with_optional_args.pm',
    'Sah/SchemaR/perl/modname_with_optional_ver.pm',
    'Sah/SchemaR/perl/modname_with_ver.pm',
    'Sah/SchemaR/perl/modnames.pm',
    'Sah/SchemaR/perl/modprefix.pm',
    'Sah/SchemaR/perl/modprefixes.pm',
    'Sah/SchemaR/perl/pm_filename.pm',
    'Sah/SchemaR/perl/pod_filename.pm',
    'Sah/SchemaR/perl/pod_or_pm_filename.pm',
    'Sah/SchemaR/perl/podname.pm',
    'Sah/SchemaR/perl/qualified_funcname.pm',
    'Sah/SchemaR/perl/release/version.pm',
    'Sah/SchemaR/perl/unqualified_funcname.pm',
    'Sah/SchemaR/perl/version.pm',
    'Sah/Schemas/Perl.pm'
);



# no fake home requested

my @switches = (
    -d 'blib' ? '-Mblib' : '-Ilib',
);

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'} . $str . q{'} }
            $^X, @switches, '-e', "require q[$lib]"))
        if $ENV{PERL_COMPILE_TEST_DEBUG};

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, @switches, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { +require blib; blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};


