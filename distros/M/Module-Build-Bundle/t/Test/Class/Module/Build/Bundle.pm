package Test::Class::Module::Build::Bundle;

use strict;
use warnings;
use Test::More;
use CPAN::Meta;
use Test::MockObject::Extends;
use FindBin;
use lib "$FindBin::Bin/../t";
use File::Temp qw/ tempfile tempdir /;
#require File::Temp;
use Env qw($TEST_VERBOSE);
use Data::Dumper;

use base qw(Test::Class);

sub startup : Test(startup) {
    my $test = shift;

    my $tmpdir = tempdir( CLEANUP => 0 );

    if ($TEST_VERBOSE) {
        diag "Created temporary directory: ", $tmpdir;

        my $mode = ( stat( $tmpdir ) )[2];

        diag sprintf "with permissions %04o\n", $mode & 07777;
    }

    $test->{tmpdir} = $tmpdir;
}

sub setup : Test(setup => 3) {
    my $test = shift;

    ok(-e $test->{tmpdir}, 'temporary directory created');

    use_ok('Module::Build::Bundle');

    ok( my $build = Module::Build::Bundle->new(
            module_name        => 'Dummy',
            dist_version       => '6.66',
            dist_author        => 'jonasbn',
            dist_abstract      => 'this is a dummy',
            configure_requires => { 'Module::Build::Bundle' => $Module::Build::Bundle::VERSION }
        ),
        'calling constructor'
    );

    $build = Test::MockObject::Extends->new($build);

    $build->set_true('_add_to_manifest');

    $test->{version}   = $Module::Build::Bundle::VERSION;
    $test->{package}   = 'Module::Build::Bundle'; #ref $build;
    $test->{build}     = $build;
    $test->{canonical} = $test->{version};
}

sub do_create_metafile : Test(12) {
    my $test = shift;

    my $build             = $test->{build};
    my $package           = $test->{package};
    my $version           = $test->{version};
    my $canonical_version = $test->{canonical};

    ok( $build->metafile( $test->{tmpdir} . '/META.yml' ),
        'setting META file name to testMETA.yml' );
    ok( $build->metafile2( $test->{tmpdir} . '/META.json' ),
        'setting META file name to testMETA.json' );

    ok( my $rv = $build->do_create_metafile, 'creating META files' );
    
    ok( -e $build->metafile,  'metafile ' . $build->metafile . ' exists' );
    ok( -e $build->metafile2, 'metafile2 ' . $build->metafile2 . ' exists' );

    ok( -r $build->metafile,  'metafile ' . $build->metafile . ' is readable' );
    ok( -r $build->metafile2, 'metafile2 ' . $build->metafile2 . ' is readable' );

    my $meta = CPAN::Meta->load_file($build->metafile);

    like(
        $meta->{generated_by},
        qr/\A$package version \d+\.\d+(?:,\s+\w+)*/,
        q[asserting 'generated_by']
    );

    like(
        $meta->{generated_by},
        qr/\A$package version $version(?:,\s+\w+)*/,
        q[asserting 'generated_by']
    );

    ok( my $req = $meta->{prereqs}->{configure}->{requires},
        q[checking 'configure_requires']
    );

    like( $req->{$package}, qr/\A\d+\.\d+\z/,
        'asserting version number format' );

    is( $req->{$package}, $canonical_version,
        'asserting version against canonical version' );

    $test->{file} = $build->metafile;
}

1;
