use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.039

use Test::More  tests => 119 + ($ENV{AUTHOR_TESTING} ? 1 : 0);



my @module_files = (
    'App/Pinto.pm',
    'App/Pinto/Command.pm',
    'App/Pinto/Command/add.pm',
    'App/Pinto/Command/clean.pm',
    'App/Pinto/Command/copy.pm',
    'App/Pinto/Command/default.pm',
    'App/Pinto/Command/delete.pm',
    'App/Pinto/Command/diff.pm',
    'App/Pinto/Command/help.pm',
    'App/Pinto/Command/init.pm',
    'App/Pinto/Command/install.pm',
    'App/Pinto/Command/kill.pm',
    'App/Pinto/Command/list.pm',
    'App/Pinto/Command/lock.pm',
    'App/Pinto/Command/log.pm',
    'App/Pinto/Command/manual.pm',
    'App/Pinto/Command/migrate.pm',
    'App/Pinto/Command/new.pm',
    'App/Pinto/Command/nop.pm',
    'App/Pinto/Command/pin.pm',
    'App/Pinto/Command/props.pm',
    'App/Pinto/Command/pull.pm',
    'App/Pinto/Command/register.pm',
    'App/Pinto/Command/rename.pm',
    'App/Pinto/Command/roots.pm',
    'App/Pinto/Command/stacks.pm',
    'App/Pinto/Command/statistics.pm',
    'App/Pinto/Command/thanks.pm',
    'App/Pinto/Command/unlock.pm',
    'App/Pinto/Command/unpin.pm',
    'App/Pinto/Command/unregister.pm',
    'App/Pinto/Command/verify.pm',
    'Pinto.pm',
    'Pinto/Action.pm',
    'Pinto/Action/Add.pm',
    'Pinto/Action/Clean.pm',
    'Pinto/Action/Copy.pm',
    'Pinto/Action/Default.pm',
    'Pinto/Action/Delete.pm',
    'Pinto/Action/Diff.pm',
    'Pinto/Action/Install.pm',
    'Pinto/Action/Kill.pm',
    'Pinto/Action/List.pm',
    'Pinto/Action/Lock.pm',
    'Pinto/Action/Log.pm',
    'Pinto/Action/New.pm',
    'Pinto/Action/Nop.pm',
    'Pinto/Action/Pin.pm',
    'Pinto/Action/Props.pm',
    'Pinto/Action/Pull.pm',
    'Pinto/Action/Register.pm',
    'Pinto/Action/Rename.pm',
    'Pinto/Action/Roots.pm',
    'Pinto/Action/Stacks.pm',
    'Pinto/Action/Statistics.pm',
    'Pinto/Action/Unlock.pm',
    'Pinto/Action/Unpin.pm',
    'Pinto/Action/Unregister.pm',
    'Pinto/Action/Verify.pm',
    'Pinto/ArchiveUnpacker.pm',
    'Pinto/Chrome.pm',
    'Pinto/Chrome/Net.pm',
    'Pinto/Chrome/Term.pm',
    'Pinto/Config.pm',
    'Pinto/Constants.pm',
    'Pinto/Database.pm',
    'Pinto/Difference.pm',
    'Pinto/DistributionSpec.pm',
    'Pinto/Exception.pm',
    'Pinto/Globals.pm',
    'Pinto/IndexCache.pm',
    'Pinto/IndexWriter.pm',
    'Pinto/Initializer.pm',
    'Pinto/Locker.pm',
    'Pinto/Migrator.pm',
    'Pinto/ModlistWriter.pm',
    'Pinto/PackageExtractor.pm',
    'Pinto/PackageSpec.pm',
    'Pinto/PrerequisiteWalker.pm',
    'Pinto/Remote.pm',
    'Pinto/Remote/Action.pm',
    'Pinto/Remote/Action/Add.pm',
    'Pinto/Remote/Action/Install.pm',
    'Pinto/Remote/Result.pm',
    'Pinto/Repository.pm',
    'Pinto/Result.pm',
    'Pinto/RevisionWalker.pm',
    'Pinto/Role/Committable.pm',
    'Pinto/Role/FileFetcher.pm',
    'Pinto/Role/Installer.pm',
    'Pinto/Role/PauseConfig.pm',
    'Pinto/Role/Plated.pm',
    'Pinto/Role/Puller.pm',
    'Pinto/Role/Schema/Result.pm',
    'Pinto/Role/Transactional.pm',
    'Pinto/Schema.pm',
    'Pinto/Schema/Result/Ancestry.pm',
    'Pinto/Schema/Result/Distribution.pm',
    'Pinto/Schema/Result/Package.pm',
    'Pinto/Schema/Result/Prerequisite.pm',
    'Pinto/Schema/Result/Registration.pm',
    'Pinto/Schema/Result/RegistrationChange.pm',
    'Pinto/Schema/Result/Revision.pm',
    'Pinto/Schema/Result/Stack.pm',
    'Pinto/Schema/ResultSet/Distribution.pm',
    'Pinto/Schema/ResultSet/Package.pm',
    'Pinto/Schema/ResultSet/Registration.pm',
    'Pinto/Server.pm',
    'Pinto/Server/Responder.pm',
    'Pinto/Server/Responder/Action.pm',
    'Pinto/Server/Responder/File.pm',
    'Pinto/Server/Router.pm',
    'Pinto/SpecFactory.pm',
    'Pinto/Statistics.pm',
    'Pinto/Store.pm',
    'Pinto/Types.pm',
    'Pinto/Util.pm'
);

my @scripts = (
    'bin/pinto',
    'bin/pintod'
);

# fake home for cpan-testers
use File::Temp;
local $ENV{HOME} = File::Temp::tempdir( CLEANUP => 1 );


my $inc_switch = -d 'blib' ? '-Mblib' : '-Ilib';

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, $inc_switch, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}

foreach my $file (@scripts)
{ SKIP: {
    open my $fh, '<', $file or warn("Unable to open $file: $!"), next;
    my $line = <$fh>;
    close $fh and skip("$file isn't perl", 1) unless $line =~ /^#!.*?\bperl\b\s*(.*)$/;

    my @flags = $1 ? split(/\s+/, $1) : ();

    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, $inc_switch, @flags, '-c', $file);
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$file compiled ok");

   # in older perls, -c output is simply the file portion of the path being tested
    if (@_warnings = grep { !/\bsyntax OK$/ }
        grep { chomp; $_ ne (File::Spec->splitpath($file))[2] } @_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
} }



is(scalar(@warnings), 0, 'no warnings found') if $ENV{AUTHOR_TESTING};


