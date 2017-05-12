use strict;
use warnings;

use lib 't/lib';

use File::Temp qw( tempdir );
use Path::Class qw( dir );
use Stepford::Runner;
use Test1::Step::CombineFiles;

use Test::More;

# BackupAFile depends on CreateAFile, and both are nested inside
# the step group Test1::StepGroup::CreateAndBackup

my $tempdir = dir( tempdir( CLEANUP => 1 ) );

{

    # adding the step group namespace will load any nested step classes
    my $runner = Stepford::Runner->new(
        step_namespaces => [
            'Test1::StepGroup',
            'Test1::Step',
        ],
    );

    $runner->run(
        final_steps => 'Test1::Step::BackupAFile',
        config      => {
            tempdir => $tempdir,
        },
    );

    my $file = $tempdir->file('foo.bak');
    ok( -f $file, "$file file exists" );
}

done_testing();
