#! perl

use Test::More;

use Test::Module::Build::Pluggable;

my $test =  Test::Module::Build::Pluggable->new();

$test->write_file( 'Build.PL',

q[
use Module::Build::Pluggable ( AuthorTests => { test_dirs => ['xtt']  } );

my $builder = Module::Build::Pluggable->new(
    module_name        => 'Foo',
    dist_version       => '0.01',
    dist_author        => 'FidoMcGruff',
    dist_abstract      => 'Test Me',
    configure_requires => { 'Module::Build' => 0 },
);

$builder->create_build_script();
]);

$test->write_file( 'xtt/pass.t', 'use Test::More tests => 1 ; pass(); ' );

$test->write_file( 'MANIFEST.SKIP', q[
MYMETA.*
_build/*
Build$
.*[.]bak
] );
$test->write_manifest();
$test->run_build_pl;
$DB::single=1;
$test->run_build_script( 'authortest' );

done_testing;
