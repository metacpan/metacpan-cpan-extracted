#!/usr/bin/perl

use strictures 2;

use Test2::V0 -no_srand => 1;
use Test::Pod;
use Test::Pod::Coverage;

subtest 'pod syntax' => sub {
    my @files = grep { !_is_internal_path($_) } all_pod_files('lib');
    all_pod_files_ok(@files);
};

subtest 'pod coverage' => sub {
    my @modules = grep { !_is_internal_module($_) } all_modules('lib');
    pod_coverage_ok($_) for sort @modules;
    done_testing;
};

sub _is_internal_path {
    my ($path) = @_;
    return $path =~ m{/(?:_[^/]+)\.pm\z};
}

sub _is_internal_module {
    my ($module) = @_;
    return $module =~ /::_/;
}

done_testing;
