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

use FindBin '$Bin';
use lib File::Spec->catfile($Bin, '..', 'lib');
use Sys::Path::SPc;

my @path_types = Sys::Path::SPc->_path_types;
my %canonical_values = map { ($_ => "/configured/$_") } @path_types;
my $canonical_result = configure_build_and_load(
    map { '--sp-'.$_.'='.$canonical_values{$_} } @path_types,
);
is($canonical_result->{'configure_status'}, 0, 'all canonical options configure');
is($canonical_result->{'build_status'}, 0, 'canonical option build succeeds');
is($canonical_result->{'load_status'}, 0, 'canonical generated module loads');
is_deeply(
    $canonical_result->{'values'},
    \%canonical_values,
    'every canonical option reaches its generated accessor',
);

my %aliases = (
    cache => 'cachedir',
    lock  => 'lockdir',
    log   => 'logdir',
    run   => 'rundir',
    spool => 'spooldir',
    state => 'sharedstatedir',
);
my %alias_values = map {
    ($aliases{$_} => "/legacy/$_")
} keys %aliases;
my $alias_result = configure_build_and_load(
    map { '--sp-'.$_.'=/legacy/'.$_ } sort keys %aliases,
);
is($alias_result->{'configure_status'}, 0, 'all legacy aliases configure');
is($alias_result->{'build_status'}, 0, 'legacy alias build succeeds');
is($alias_result->{'load_status'}, 0, 'legacy alias generated module loads');
is_deeply(
    {
        map { ($_ => $alias_result->{'values'}->{$_}) }
            sort values %aliases
    },
    \%alias_values,
    'every legacy alias reaches its generated accessor',
);

done_testing();

sub configure_build_and_load {
    my (@args) = @_;
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
    my ($configure_status, $configure_output) = run_process(
        $^X,
        'Build.PL',
        @args,
    );
    my ($build_status, $build_output) = $configure_status == 0
        ? run_process($^X, 'Build')
        : (-1, '');
    my ($load_status, $generated_output) = $build_status == 0
        ? run_process(
            $^X,
            '-Iblib/lib',
            '-MSys::Path::SPc',
            '-e',
            'print join qq{\0}, map { Sys::Path::SPc->$_ } '
                .'Sys::Path::SPc->_path_types',
        )
        : (-1, '');
    chdir $original_dir or die "failed to return to $original_dir: $!";

    diag($configure_output) if $configure_status != 0;
    diag($build_output) if $build_status != 0;
    my @values = split /\0/, $generated_output, -1;
    return {
        temp_dir        => $tmp_dir,
        configure_status => $configure_status,
        build_status     => $build_status,
        load_status      => $load_status,
        values           => {
            map { ($path_types[$_] => $values[$_]) } 0 .. $#path_types
        },
    };
}

sub run_process {
    my (@command) = @_;
    my $error_fh = gensym();
    my $pid = open3(my $input_fh, my $output_fh, $error_fh, @command);
    close $input_fh;
    my $output = do { local $/; <$output_fh> };
    $output .= do { local $/; <$error_fh> };
    waitpid($pid, 0);
    return ($?, $output);
}
