use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.057

use Test::More;

plan tests => 22 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Data/Sah/Coerce/perl/obj/str_perl_version.pm',
    'Data/Sah/Coerce/perl/str/str_convert_perl_pm_or_pod_to_path.pm',
    'Data/Sah/Coerce/perl/str/str_convert_perl_pm_to_path.pm',
    'Data/Sah/Coerce/perl/str/str_convert_perl_pod_or_pm_to_path.pm',
    'Data/Sah/Coerce/perl/str/str_convert_perl_pod_to_path.pm',
    'Data/Sah/Coerce/perl/str/str_normalize_perl_distname.pm',
    'Data/Sah/Coerce/perl/str/str_normalize_perl_modname.pm',
    'Sah/Schema/perl/distname.pm',
    'Sah/Schema/perl/filename.pm',
    'Sah/Schema/perl/modname.pm',
    'Sah/Schema/perl/pm_filename.pm',
    'Sah/Schema/perl/pod_filename.pm',
    'Sah/Schema/perl/pod_or_pm_filename.pm',
    'Sah/Schema/perl/version.pm',
    'Sah/SchemaR/perl/distname.pm',
    'Sah/SchemaR/perl/filename.pm',
    'Sah/SchemaR/perl/modname.pm',
    'Sah/SchemaR/perl/pm_filename.pm',
    'Sah/SchemaR/perl/pod_filename.pm',
    'Sah/SchemaR/perl/pod_or_pm_filename.pm',
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


