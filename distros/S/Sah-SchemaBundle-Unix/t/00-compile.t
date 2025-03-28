use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 45 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Data/Sah/Filter/perl/Unix/check_gid_exists.pm',
    'Data/Sah/Filter/perl/Unix/check_uid_exists.pm',
    'Data/Sah/Filter/perl/Unix/check_unix_group_exists.pm',
    'Data/Sah/Filter/perl/Unix/check_unix_user_exists.pm',
    'Data/Sah/Filter/perl/Unix/convert_gid_to_unix_group.pm',
    'Data/Sah/Filter/perl/Unix/convert_uid_to_unix_user.pm',
    'Data/Sah/Filter/perl/Unix/convert_unix_group_to_gid.pm',
    'Data/Sah/Filter/perl/Unix/convert_unix_user_to_uid.pm',
    'Data/Sah/Filter/perl/Unix/try_convert_gid_to_unix_group.pm',
    'Data/Sah/Filter/perl/Unix/try_convert_uid_to_unix_user.pm',
    'Data/Sah/Filter/perl/Unix/try_convert_unix_group_to_gid.pm',
    'Data/Sah/Filter/perl/Unix/try_convert_unix_user_to_uid.pm',
    'Perinci/Sub/XCompletion/unix_gid.pm',
    'Perinci/Sub/XCompletion/unix_group.pm',
    'Perinci/Sub/XCompletion/unix_group_or_gid.pm',
    'Perinci/Sub/XCompletion/unix_uid.pm',
    'Perinci/Sub/XCompletion/unix_user.pm',
    'Perinci/Sub/XCompletion/unix_user_or_uid.pm',
    'Sah/Schema/unix/dirname.pm',
    'Sah/Schema/unix/filename.pm',
    'Sah/Schema/unix/gid.pm',
    'Sah/Schema/unix/gid/exists.pm',
    'Sah/Schema/unix/groupname.pm',
    'Sah/Schema/unix/groupname/exists.pm',
    'Sah/Schema/unix/pathname.pm',
    'Sah/Schema/unix/pid.pm',
    'Sah/Schema/unix/signal.pm',
    'Sah/Schema/unix/uid.pm',
    'Sah/Schema/unix/uid/exists.pm',
    'Sah/Schema/unix/username.pm',
    'Sah/Schema/unix/username/exists.pm',
    'Sah/SchemaBundle/Unix.pm',
    'Sah/SchemaR/unix/dirname.pm',
    'Sah/SchemaR/unix/filename.pm',
    'Sah/SchemaR/unix/gid.pm',
    'Sah/SchemaR/unix/gid/exists.pm',
    'Sah/SchemaR/unix/groupname.pm',
    'Sah/SchemaR/unix/groupname/exists.pm',
    'Sah/SchemaR/unix/pathname.pm',
    'Sah/SchemaR/unix/pid.pm',
    'Sah/SchemaR/unix/signal.pm',
    'Sah/SchemaR/unix/uid.pm',
    'Sah/SchemaR/unix/uid/exists.pm',
    'Sah/SchemaR/unix/username.pm',
    'Sah/SchemaR/unix/username/exists.pm'
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


