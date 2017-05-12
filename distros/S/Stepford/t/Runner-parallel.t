use strict;
use warnings;

use lib 't/lib';

use File::Temp qw( tempdir );
use Path::Class qw( dir );
use Stepford::Runner;
use Test1::Step::CombineFiles;

use Test::More;

my $tempdir = dir( tempdir( CLEANUP => 1 ) );

{
    my $runner = Stepford::Runner->new(
        step_namespaces => 'Test1::Step',
        jobs            => 3,
    );

    $runner->run(
        final_steps => 'Test1::Step::CombineFiles',
        config      => {
            tempdir => $tempdir,
        },
    );

    for my $file ( map { $tempdir->file($_) } qw( a1 a2 combined ) ) {
        ok( -f $file, $file->basename . ' file exists' );
    }
}

done_testing();
