#!/usr/bin/perl -w
# this test just tests functionality from our parent Module::Build::TAPArchive
# to make sure we dont alter it in a negative way
BEGIN
{
    # run our tests in the t/ lib so that it doesn't interfere with the 
    # blib && _build stuff that happens in the main directory
    chdir 't' if -d 't';
    use lib '../lib', '../blib/lib';
}

use strict;
use File::Spec::Functions qw(catfile rel2abs);
use Test::More (tests => 25);
use TAP::Harness::Archive;
use File::Path qw(rmtree);
use Capture::Tiny qw(capture_merged capture);

my $module = 'Module::Build::Smolder';
use_ok( $module ) or exit;
my $ok;
can_ok( $module, 'new' );
my %args = ( module_name => 'Some::Module', dist_version => '1.0' );
my $build = $module->new( %args );

isa_ok( $build, 'Module::Build' );
isa_ok( $build, $module );
my $p = $build->{properties};
is($p->{archive_file}, 'test_archive.tar.gz', 'default archive_file is test_archive.tar.gz');
ok(exists $p->{server}       && !defined $p->{server},       'no server set');
ok(exists $p->{password}     && !defined $p->{password},     'no password set');
ok(exists $p->{password}     && !defined $p->{password},     'no password set');
ok(exists $p->{project_id}   && !defined $p->{project_id},   'no project_id set');
ok(exists $p->{architecture} && !defined $p->{architecture}, 'no architecture set');
ok(exists $p->{platform}     && !defined $p->{platform},     'no platform set');
ok(exists $p->{tags}         && !defined $p->{tags},         'no tags set');
ok(exists $p->{comments}     && !defined $p->{comments},     'no tags set');
ok(exists $p->{use_existing_archive} && !defined $p->{use_existing_archive},
    'no use_existing_archive set');

$build = $module->new(%args, server => 'foo.com', project_id => 123);
isa_ok( $build, 'Module::Build' );
isa_ok( $build, $module );
is( $build->{properties}{server}, 'foo.com', 'set server');
is( $build->{properties}{project_id}, 123, 'set project_id');

can_ok( $build, 'ACTION_test' );
can_ok( $build, 'ACTION_test_archive' );
can_ok( $build, 'ACTION_smolder' );

# check required arguments
my $err;
capture_merged {
    $build = $module->new(%args);
    eval { $build->ACTION_smolder() };
    $err = $@;
};
like($err, qr/Required option --server/i, '--server is required');

capture_merged {
    $build = $module->new(%args, server => 'foo.com');
    eval { $build->ACTION_smolder() };
    $err = $@;
};
like($err, qr/Required option --project_id/i, '--project_id is required');

capture_merged {
    $build = $module->new(%args, server => 'foo.com', project_id => 123, username => 'bar');
    eval { $build->ACTION_smolder() };
    $err = $@;
};
like($err, qr/need to specify --password/i, '--password is required if --username is used');

capture_merged {
    $build = $module->new(%args, server => 'foo.com', project_id => 123, password => 'bar');
    eval { $build->ACTION_smolder() };
    $err = $@;
};
like($err, qr/need to specify --username/i, '--username is required if --password is used');

# clean up if we need to
unlink 'test_archive.tar.gz' if -e 'test_archive.tar.gz';
rmtree('blib') if -d 'blib';

