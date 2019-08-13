use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 91;

my @module_files = (
    'MongoDB.pm',
    'MongoDB/BSON/Binary.pm',
    'MongoDB/BSON/Regexp.pm',
    'MongoDB/BulkWrite.pm',
    'MongoDB/BulkWriteResult.pm',
    'MongoDB/BulkWriteView.pm',
    'MongoDB/ChangeStream.pm',
    'MongoDB/ClientSession.pm',
    'MongoDB/Code.pm',
    'MongoDB/Collection.pm',
    'MongoDB/CommandResult.pm',
    'MongoDB/Cursor.pm',
    'MongoDB/DBRef.pm',
    'MongoDB/Database.pm',
    'MongoDB/DeleteResult.pm',
    'MongoDB/Error.pm',
    'MongoDB/GridFSBucket.pm',
    'MongoDB/GridFSBucket/DownloadStream.pm',
    'MongoDB/GridFSBucket/UploadStream.pm',
    'MongoDB/IndexView.pm',
    'MongoDB/InsertManyResult.pm',
    'MongoDB/InsertOneResult.pm',
    'MongoDB/MongoClient.pm',
    'MongoDB/OID.pm',
    'MongoDB/Op/_Aggregate.pm',
    'MongoDB/Op/_BatchInsert.pm',
    'MongoDB/Op/_BulkWrite.pm',
    'MongoDB/Op/_ChangeStream.pm',
    'MongoDB/Op/_Command.pm',
    'MongoDB/Op/_Count.pm',
    'MongoDB/Op/_CreateIndexes.pm',
    'MongoDB/Op/_Delete.pm',
    'MongoDB/Op/_Distinct.pm',
    'MongoDB/Op/_DropCollection.pm',
    'MongoDB/Op/_DropDatabase.pm',
    'MongoDB/Op/_DropIndexes.pm',
    'MongoDB/Op/_EndTxn.pm',
    'MongoDB/Op/_Explain.pm',
    'MongoDB/Op/_FSyncUnlock.pm',
    'MongoDB/Op/_FindAndDelete.pm',
    'MongoDB/Op/_FindAndUpdate.pm',
    'MongoDB/Op/_GetMore.pm',
    'MongoDB/Op/_InsertOne.pm',
    'MongoDB/Op/_KillCursors.pm',
    'MongoDB/Op/_ListCollections.pm',
    'MongoDB/Op/_ListIndexes.pm',
    'MongoDB/Op/_ParallelScan.pm',
    'MongoDB/Op/_Query.pm',
    'MongoDB/Op/_RenameCollection.pm',
    'MongoDB/Op/_Update.pm',
    'MongoDB/QueryResult.pm',
    'MongoDB/QueryResult/Filtered.pm',
    'MongoDB/ReadConcern.pm',
    'MongoDB/ReadPreference.pm',
    'MongoDB/Role/_BypassValidation.pm',
    'MongoDB/Role/_CollectionOp.pm',
    'MongoDB/Role/_CommandCursorOp.pm',
    'MongoDB/Role/_CommandMonitoring.pm',
    'MongoDB/Role/_CursorAPI.pm',
    'MongoDB/Role/_DatabaseErrorThrower.pm',
    'MongoDB/Role/_DatabaseOp.pm',
    'MongoDB/Role/_DeprecationWarner.pm',
    'MongoDB/Role/_InsertPreEncoder.pm',
    'MongoDB/Role/_OpReplyParser.pm',
    'MongoDB/Role/_PrivateConstructor.pm',
    'MongoDB/Role/_ReadOp.pm',
    'MongoDB/Role/_ReadPrefModifier.pm',
    'MongoDB/Role/_SessionSupport.pm',
    'MongoDB/Role/_SingleBatchDocWrite.pm',
    'MongoDB/Role/_TopologyMonitoring.pm',
    'MongoDB/Role/_UpdatePreEncoder.pm',
    'MongoDB/Role/_WriteOp.pm',
    'MongoDB/Role/_WriteResult.pm',
    'MongoDB/Timestamp.pm',
    'MongoDB/UnacknowledgedResult.pm',
    'MongoDB/UpdateResult.pm',
    'MongoDB/WriteConcern.pm',
    'MongoDB/_Constants.pm',
    'MongoDB/_Credential.pm',
    'MongoDB/_Dispatcher.pm',
    'MongoDB/_Link.pm',
    'MongoDB/_Platform.pm',
    'MongoDB/_Protocol.pm',
    'MongoDB/_Server.pm',
    'MongoDB/_ServerSession.pm',
    'MongoDB/_SessionPool.pm',
    'MongoDB/_Topology.pm',
    'MongoDB/_TransactionOptions.pm',
    'MongoDB/_Types.pm',
    'MongoDB/_URI.pm'
);



# fake home for cpan-testers
use File::Temp;
local $ENV{HOME} = File::Temp::tempdir( CLEANUP => 1 );


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
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) );


