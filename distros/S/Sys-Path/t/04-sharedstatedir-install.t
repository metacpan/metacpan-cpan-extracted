#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Cwd 'getcwd';
use File::Basename 'dirname';
use File::Copy 'copy';
use File::Path 'make_path';
use File::Spec;
use File::Temp;
use IPC::Open3 'open3';
use Symbol 'gensym';

for my $configuration (
    {
        name  => 'CLI override',
        args  => sub { '--sp-sharedstatedir='.$_[0] },
        input => '',
    },
    {
        name  => 'prompted override',
        args  => sub { () },
        input => sub { "\n" x 11 . $_[0] . "\n\n\n" },
    },
) {
    subtest $configuration->{'name'} => sub {
        my $result = configure_build_and_install($configuration);
        is($result->{'configure_status'}, 0, 'configuration succeeds');
        is($result->{'build_status'}, 0, 'build succeeds');
        is($result->{'load_status'}, 0, 'generated module loads');
        is(
            $result->{'generated_sharedstatedir'},
            $result->{'configured_sharedstatedir'},
            'generated accessor uses the configured sharedstatedir',
        );
        is($result->{'install_status'}, 0, 'staged installation succeeds');
        ok(
            -d $result->{'staged_registry_dir'},
            'registry directory is staged beneath the configured sharedstatedir',
        );
    };
}

done_testing();

sub configure_build_and_install {
    my ($configuration) = @_;
    my $source_dir = getcwd();
    my $tmp_dir = File::Temp->newdir();
    my $configured_sharedstatedir = File::Spec->catdir(
        File::Spec->rootdir,
        'tmp',
        'custom-state',
    );
    my $stage_dir = File::Spec->catdir($tmp_dir, 'stage');

    open my $manifest_fh, '<', File::Spec->catfile($source_dir, 'MANIFEST')
        or die "failed to open MANIFEST: $!";
    my @filenames = map { (split)[0] } <$manifest_fh>;
    close $manifest_fh;
    for my $filename (@filenames) {
        my $destination = File::Spec->catfile($tmp_dir, $filename);
        make_path(dirname($destination));
        copy(File::Spec->catfile($source_dir, $filename), $destination)
            or die "failed to copy $filename: $!";
    }

    my $input = ref($configuration->{'input'}) eq 'CODE'
        ? $configuration->{'input'}->($configured_sharedstatedir)
        : $configuration->{'input'};
    my @args = $configuration->{'args'}->($configured_sharedstatedir);
    my $original_dir = getcwd();
    chdir $tmp_dir or die "failed to enter $tmp_dir: $!";
    local $ENV{'PERL_MM_USE_DEFAULT'} = 0;
    my ($configure_status, $configure_output) = run_process(
        $input,
        $^X,
        'Build.PL',
        @args,
    );
    my ($build_status, $build_output) = $configure_status == 0
        ? run_process('', $^X, 'Build')
        : (-1, '');
    my ($load_status, $generated_sharedstatedir) = $build_status == 0
        ? run_process(
            '',
            $^X,
            '-Iblib/lib',
            '-MSys::Path::SPc',
            '-e',
            'print Sys::Path::SPc->sharedstatedir',
        )
        : (-1, '');
    my ($install_status, $install_output) = $build_status == 0
        ? run_process('', $^X, 'Build', 'install', '--destdir='.$stage_dir)
        : (-1, '');
    chdir $original_dir or die "failed to return to $original_dir: $!";

    diag($configure_output) if $configure_status != 0;
    diag($build_output) if $build_status != 0;
    diag($install_output) if $install_status != 0;
    return {
        temp_dir                  => $tmp_dir,
        configure_status          => $configure_status,
        build_status              => $build_status,
        load_status               => $load_status,
        generated_sharedstatedir  => $generated_sharedstatedir,
        configured_sharedstatedir => $configured_sharedstatedir,
        install_status            => $install_status,
        staged_registry_dir       => File::Spec->catdir(
            $stage_dir,
            $configured_sharedstatedir,
            'syspath',
        ),
    };
}

sub run_process {
    my ($input, @command) = @_;
    my $error_fh = gensym();
    my $pid = open3(my $input_fh, my $output_fh, $error_fh, @command);
    print {$input_fh} $input;
    close $input_fh;
    my $output = do { local $/; <$output_fh> };
    $output .= do { local $/; <$error_fh> };
    waitpid($pid, 0);
    return ($?, $output);
}
