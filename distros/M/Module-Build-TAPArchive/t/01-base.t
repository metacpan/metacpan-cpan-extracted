#!/usr/bin/perl -w

# run our tests in the t/ lib so that it doesn't interfere with the blib && _build stuff
# that happens in the main directory
BEGIN
{
    chdir 't' if -d 't';
    use lib '../lib', '../blib/lib';
}

use strict;
use File::Spec::Functions qw(catfile rel2abs);
use Test::More (tests => 14);
use TAP::Harness::Archive;
use File::Path qw(rmtree);
use Capture::Tiny qw(capture);

my $module = 'Module::Build::TAPArchive';
use_ok( $module ) or exit;
my $ok;
can_ok( $module, 'new' );
my %args = ( module_name => 'Some::Module', dist_version => '1.0' );
my $build = $module->new( %args );

isa_ok( $build, 'Module::Build' );
isa_ok( $build, $module );
is( $build->{properties}{archive_file}, 'test_archive.tar.gz', 'default archive_file is test_archive.tar.gz');
$build = $module->new(%args, archive_file => 'foo.tar.gz');
isa_ok( $build, 'Module::Build' );
isa_ok( $build, $module );
is( $build->{properties}{archive_file}, 'foo.tar.gz', 'override archive_file');

can_ok( $build, 'ACTION_test' );
can_ok( $build, 'ACTION_test_archive' );

# make sure we create the default archive file and it works
# use our fake tests for this
capture {
    local $ENV{HARNESS_VERBOSE} = 0;
    no warnings;
    local *Module::Build::find_test_files = sub {
        [ map { catfile( 'fake_tests', $_ ) } qw( fail.t pass.t ) ]
    };
    $build = $module->new(%args, verbose => 0, quiet => 1);
    $build->ACTION_test_archive();
};

ok(-e 'test_archive.tar.gz', 'created archive file');

my $aggregator = TAP::Harness::Archive->aggregator_from_archive({archive => rel2abs('test_archive.tar.gz')});
isa_ok($aggregator, 'TAP::Parser::Aggregator');
is($aggregator->passed, 3, 'right number of passed tests');
is($aggregator->failed, 1, 'right number of failed tests');

# clean up
unlink 'test_archive.tar.gz' if -e 'test_archive.tar.gz';
rmtree('blib');

