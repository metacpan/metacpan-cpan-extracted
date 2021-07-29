#!/usr/bin/env perl

use 5.010;
use warnings;
use autodie;

use Carp;
use File::Basename;
use File::Path qw(rmtree);
use File::Temp;
use Rex::Commands::File;
use Rex::Hook;
use Rex::Hook::File::Impostor;
use Test2::V0;
use Test::File 1.443;

our $VERSION = '9999';

plan tests => 5;

my $managed_file = File::Temp->new(
    TEMPLATE => 'managed_file_XXXX',
    DIR      => Rex::Config->get_tmp_dir(),
)->filename();

my $impostor_file = Rex::Hook::File::Impostor::get_impostor_for($managed_file);
my $impostor_directory = Rex::Hook::File::Impostor::get_impostor_directory();

my $original_content = 'original';
my $impostor_content = 'impostor';

register_function_hooks {
    before_change => { file => \&test_intermediate_state, }, };

sub test_intermediate_state {
    my ( $managed_path, %options ) = @_;

    is( $managed_path, $impostor_file,
        'impostor file path overrides managed file path' );

    if ( -e ($managed_file) ) {
        dir_exists_ok( File::Spec->join( dirname($impostor_file) ) );
        file_exists_ok($impostor_file);

        file_contains_like( $impostor_file, qr{$original_content}msx );
    }

    return $managed_path, %options;
}

sub create_managed_file {
    open my $FILE, '>', $managed_file;
    print {$FILE} $original_content or croak "Couldn't write to $managed_file";
    close $FILE;

    return;
}

sub cleanup {
    if ( -e $managed_file ) {
        unlink $managed_file;
    }

    if ( -d $impostor_directory ) {
        rmtree( $impostor_directory, { safe => 1 } );
    }

    file_not_exists_ok($managed_file);
    file_not_exists_ok($impostor_file);
    file_not_exists_ok($impostor_directory);

    return;
}

subtest 'create new empty file' => sub {
    file_not_exists_ok($managed_file);
    file_not_exists_ok($impostor_file);

    file $managed_file, ensure => 'present';

    file_not_exists_ok($managed_file);
    file_exists_ok($impostor_file);

    file_empty_ok($impostor_file);

    cleanup();
};

subtest 'ensure presence of an existing file' => sub {
    create_managed_file();

    file_exists_ok($managed_file);
    file_not_exists_ok($impostor_file);

    file_contains_like( $managed_file, qr{$original_content}msx );

    file $managed_file,
      ensure => 'present'; ## no critic ( ProhibitDuplicateLiteral )

    file_exists_ok($managed_file);
    file_exists_ok($impostor_file);

    file_contains_like( $managed_file,  qr{$original_content}msx );
    file_contains_like( $impostor_file, qr{$original_content}msx );

    cleanup();
};

subtest 'create new file with content' => sub {
    file_not_exists_ok($managed_file);
    file_not_exists_ok($impostor_file);

    file $managed_file, content => $impostor_content;

    file_not_exists_ok($managed_file);
    file_exists_ok($impostor_file);

    file_contains_like( $impostor_file, qr{$impostor_content}msx );

    cleanup();
};

subtest 'modify existing file' => sub {
    create_managed_file();

    file_exists_ok($managed_file);
    file_not_exists_ok($impostor_file);

    file_contains_like( $managed_file, qr{$original_content}msx );

    file $managed_file, content => $impostor_content;

    file_exists_ok($managed_file);
    file_exists_ok($impostor_file);

    file_contains_like( $managed_file,  qr{$original_content}msx );
    file_contains_like( $impostor_file, qr{$impostor_content}msx );

    cleanup();
};

subtest 'delete existing file' => sub {
    create_managed_file();

    file_exists_ok($managed_file);
    file_not_exists_ok($impostor_file);

    file_contains_like( $managed_file, qr{$original_content}msx );

    file $managed_file, ensure => 'absent';

    file_exists_ok($managed_file);
    file_not_exists_ok($impostor_file);

    cleanup();
};
