#!/usr/bin/env perl

use 5.006;
use warnings;

use English qw( -no_match_vars );
use File::Basename;
use File::Touch 0.08;
use File::Temp;
use Rex::Hook::File::Diff;
use Test2::V0 0.000071;
use Test::File 1.443;

our $VERSION = '9999';

plan tests => 3;

my $null = File::Spec->devnull();

subtest 'create new file' => sub {
    my ( $file, $rex_temp_file ) = get_test_files();

    touch $rex_temp_file;

    file_not_exists_ok($file);
    file_exists_ok($rex_temp_file);

    my @involved_files = Rex::Hook::File::Diff::involved_files($file);
    my @expected_files = ( $null, $rex_temp_file );

    is( \@involved_files, \@expected_files, 'filenames match for file creation' );

    unlink $file, $rex_temp_file;

    file_not_exists_ok($file);
    file_not_exists_ok($rex_temp_file);
};

subtest 'modify existing file' => sub {
    my ( $file, $rex_temp_file ) = get_test_files();

    touch $file;
    touch $rex_temp_file;

    file_exists_ok($file);
    file_exists_ok($rex_temp_file);

    my @involved_files = Rex::Hook::File::Diff::involved_files($file);
    my @expected_files = ( $file, $rex_temp_file );

    is( \@involved_files, \@expected_files,
        'filenames match for file modification' );

    unlink $file, $rex_temp_file;

    file_not_exists_ok($file);
    file_not_exists_ok($rex_temp_file);
};

subtest 'delete file' => sub {
    my ( $file, $rex_temp_file ) = get_test_files();

    touch $file;

    file_exists_ok($file);
    file_not_exists_ok($rex_temp_file);

    my @involved_files = Rex::Hook::File::Diff::involved_files($file);
    my @expected_files = ( $file, $null );

    is( \@involved_files, \@expected_files, 'filenames match for file deletion' );

    unlink $file, $rex_temp_file;

    file_not_exists_ok($file);
    file_not_exists_ok($rex_temp_file);
};

sub get_test_files {
    my $file = File::Temp->new( TEMPLATE => "$PROGRAM_NAME.XXXX" )->filename();
    my $rex_temp_file =
      File::Spec->catfile( dirname($file), '.rex.tmp.' . basename($file) );

    return $file, $rex_temp_file;
}
