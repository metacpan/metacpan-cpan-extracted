#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Capture::Tiny 'capture_merged';
use Cwd 'getcwd';
use File::Basename 'dirname';
use File::Copy 'copy';
use File::Path 'make_path';
use File::Spec;
use File::Temp;

my @values = (
    "/tmp/o'connor",
    "/tmp/back\\slash",
    "/tmp/trailing\\",
);

for my $value (@values) {
    my $result = build_and_load_prefix($value);
    is(
        $result->{'configure_status'},
        0,
        "configuration accepts prefix $value",
    );
    is($result->{'build_status'}, 0, "build accepts prefix $value");
    is(
        $result->{'load_status'},
        0,
        "generated module for prefix $value loads in a separate process",
    );
    is($result->{'prefix'}, $value, "generated prefix preserves $value");
}

done_testing();

sub build_and_load_prefix {
    my ($prefix) = @_;
    my $source_dir = getcwd();
    my $tmp_dir = File::Temp->newdir();

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

    my $original_dir = getcwd();
    chdir $tmp_dir or die "failed to enter $tmp_dir: $!";
    local $ENV{'PERL_MM_USE_DEFAULT'} = 1;
    my ($configure_status, $build_status);
    my $build_output = capture_merged {
        system {$^X} $^X, 'Build.PL', '--sp-prefix='.$prefix;
        $configure_status = $?;
        system {$^X} $^X, 'Build' if $configure_status == 0;
        $build_status = $?;
    };

    my ($load_status, $generated_prefix) = (-1, '');
    if ($configure_status == 0 && $build_status == 0) {
        open my $perl_fh, '-|',
            $^X,
            '-Iblib/lib',
            '-MSys::Path::SPc',
            '-e',
            'print Sys::Path::SPc->prefix'
            or die "failed to load generated module: $!";
        $generated_prefix = do { local $/; <$perl_fh> };
        close $perl_fh;
        $load_status = $?;
    }
    chdir $original_dir or die "failed to return to $original_dir: $!";
    diag($build_output)
        if $configure_status != 0 || $build_status != 0;

    return {
        configure_status => $configure_status,
        build_status     => $build_status,
        load_status      => $load_status,
        prefix           => $generated_prefix,
    };
}
