use strict;
use warnings;

use lib 't/lib';

use Path::Class qw( tempdir );
use Stepford::Runner;

use Test::More;

my $tempdir = tempdir( CLEANUP => 1 );

{
    _run_combine_files();

    my $a1_updated_file = $tempdir->file('a1-updated');

    $a1_updated_file->remove;

    _run_combine_files();

    ok( -f $a1_updated_file, 'a1_updated_file recreated' );
}

done_testing();

sub _run_combine_files {
    my $runner = Stepford::Runner->new( step_namespaces => 'Test1::Step', );
    $runner->run(
        final_steps => 'Test1::Step::CombineFiles',
        config      => {
            tempdir => $tempdir,
        },
    );
}
