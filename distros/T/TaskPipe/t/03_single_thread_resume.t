#!/usr/bin/perl

use strict;
use warnings;

use File::Basename;
use File::Spec;
use Test::More;
use Cwd 'abs_path';
use lib 't/lib';

use TaskPipe::TestUtils::Threaded;
use TaskPipe::TestUtils::Resume;

my $root_dir = File::Spec->catdir(
    dirname(abs_path(__FILE__)),'..','t','non_threaded'
);

my $threaded = TaskPipe::TestUtils::Threaded->new(
    root_dir => $root_dir
);

$threaded->skip_if_no_config;

my $resume = TaskPipe::TestUtils::Resume->new(
    root_dir => $root_dir,
    n_tests => 3,
    configs => [{
        city => 2,
        company => 2,
        employee => 0,
        threads => 1
    }, 
    {
        city => 2,
        company => 3,
        employee => 2,
        threads => 1
    }]
);


my $n_tests = 60;
foreach my $config (@{$resume->{configs}}){
    foreach my $table ( keys %$config ){
        next if $table eq 'threads';
        $n_tests += 6 * $config->{$table};
    }
}    

plan tests => $n_tests;

warn "Running resume mechanism tests. Please be patient - this will take some time\n";

$resume->run_tests;

done_testing();
