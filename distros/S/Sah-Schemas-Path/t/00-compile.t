use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 86 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Data/Sah/Coerce/perl/To_array/From_str/expand_glob.pm',
    'Data/Sah/Filter/perl/Path/check_dir_exists.pm',
    'Data/Sah/Filter/perl/Path/check_file_exists.pm',
    'Data/Sah/Filter/perl/Path/check_path_exists.pm',
    'Data/Sah/Filter/perl/Path/check_path_not_exists.pm',
    'Data/Sah/Filter/perl/Path/expand_tilde.pm',
    'Data/Sah/Filter/perl/Path/expand_tilde_when_on_unix.pm',
    'Data/Sah/Filter/perl/Path/strip_slashes.pm',
    'Data/Sah/Filter/perl/Path/strip_slashes_when_on_unix.pm',
    'Data/Sah/Value/perl/Path/curdir_abs.pm',
    'Data/Sah/Value/perl/Path/newest_file_in_curdir.pm',
    'Data/Sah/Value/perl/Path/only_file_in_curdir.pm',
    'Data/Sah/Value/perl/Path/only_file_not_dir_in_curdir.pm',
    'Data/Sah/Value/perl/Path/only_subdir_in_curdir.pm',
    'Data/Sah/Value/perl/Path/only_subdir_not_file_in_curdir.pm',
    'Sah/Schema/dirname.pm',
    'Sah/Schema/dirname/default_curdir.pm',
    'Sah/Schema/dirname/default_curdir_abs.pm',
    'Sah/Schema/dirname/default_only_subdir_in_curdir.pm',
    'Sah/Schema/dirname/default_only_subdir_not_file_in_curdir.pm',
    'Sah/Schema/dirname/exists.pm',
    'Sah/Schema/dirname/exists/default_only_subdir_in_curdir.pm',
    'Sah/Schema/dirname/not_exists.pm',
    'Sah/Schema/dirname/unix.pm',
    'Sah/Schema/dirname/unix/basename.pm',
    'Sah/Schema/dirname/unix/exists.pm',
    'Sah/Schema/dirname/unix/not_exists.pm',
    'Sah/Schema/dirnames/exist.pm',
    'Sah/Schema/filename.pm',
    'Sah/Schema/filename/default_newest_file_in_curdir.pm',
    'Sah/Schema/filename/default_only_file_in_curdir.pm',
    'Sah/Schema/filename/default_only_file_not_dir_in_curdir.pm',
    'Sah/Schema/filename/exists.pm',
    'Sah/Schema/filename/exists/default_only_file_in_curdir.pm',
    'Sah/Schema/filename/not_exists.pm',
    'Sah/Schema/filename/unix.pm',
    'Sah/Schema/filename/unix/basename.pm',
    'Sah/Schema/filename/unix/exists.pm',
    'Sah/Schema/filename/unix/not_exists.pm',
    'Sah/Schema/filenames.pm',
    'Sah/Schema/filenames/exist.pm',
    'Sah/Schema/pathname.pm',
    'Sah/Schema/pathname/exists.pm',
    'Sah/Schema/pathname/not_exists.pm',
    'Sah/Schema/pathname/unix.pm',
    'Sah/Schema/pathname/unix/basename.pm',
    'Sah/Schema/pathname/unix/exists.pm',
    'Sah/Schema/pathname/unix/not_exists.pm',
    'Sah/Schema/pathnames.pm',
    'Sah/Schema/pathnames/exist.pm',
    'Sah/SchemaR/dirname.pm',
    'Sah/SchemaR/dirname/default_curdir.pm',
    'Sah/SchemaR/dirname/default_curdir_abs.pm',
    'Sah/SchemaR/dirname/default_only_subdir_in_curdir.pm',
    'Sah/SchemaR/dirname/default_only_subdir_not_file_in_curdir.pm',
    'Sah/SchemaR/dirname/exists.pm',
    'Sah/SchemaR/dirname/exists/default_only_subdir_in_curdir.pm',
    'Sah/SchemaR/dirname/not_exists.pm',
    'Sah/SchemaR/dirname/unix.pm',
    'Sah/SchemaR/dirname/unix/basename.pm',
    'Sah/SchemaR/dirname/unix/exists.pm',
    'Sah/SchemaR/dirname/unix/not_exists.pm',
    'Sah/SchemaR/dirnames/exist.pm',
    'Sah/SchemaR/filename.pm',
    'Sah/SchemaR/filename/default_newest_file_in_curdir.pm',
    'Sah/SchemaR/filename/default_only_file_in_curdir.pm',
    'Sah/SchemaR/filename/default_only_file_not_dir_in_curdir.pm',
    'Sah/SchemaR/filename/exists.pm',
    'Sah/SchemaR/filename/exists/default_only_file_in_curdir.pm',
    'Sah/SchemaR/filename/not_exists.pm',
    'Sah/SchemaR/filename/unix.pm',
    'Sah/SchemaR/filename/unix/basename.pm',
    'Sah/SchemaR/filename/unix/exists.pm',
    'Sah/SchemaR/filename/unix/not_exists.pm',
    'Sah/SchemaR/filenames.pm',
    'Sah/SchemaR/filenames/exist.pm',
    'Sah/SchemaR/pathname.pm',
    'Sah/SchemaR/pathname/exists.pm',
    'Sah/SchemaR/pathname/not_exists.pm',
    'Sah/SchemaR/pathname/unix.pm',
    'Sah/SchemaR/pathname/unix/basename.pm',
    'Sah/SchemaR/pathname/unix/exists.pm',
    'Sah/SchemaR/pathname/unix/not_exists.pm',
    'Sah/SchemaR/pathnames.pm',
    'Sah/SchemaR/pathnames/exist.pm',
    'Sah/Schemas/Path.pm'
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


