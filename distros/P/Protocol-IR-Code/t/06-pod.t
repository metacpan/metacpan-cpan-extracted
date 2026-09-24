#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Find;
use lib '.';

use File::Spec;
use File::Basename qw(dirname);
use Pod::Checker;

# This is an author test: at installation time the user does not care
# whether the POD is stylistically valid, so skip unless AUTHOR_TESTING.
unless ($ENV{AUTHOR_TESTING}) {
    plan skip_all => 'author test; set AUTHOR_TESTING=1 to run';
}

my $lib = File::Spec->rel2abs(File::Spec->catdir(dirname(__FILE__), '..', 'lib'));
my @files;
find(sub { push @files, $File::Find::name if /\.pm$/ }, $lib);

my @bad;
for my $file (sort @files) {
    my $checker = Pod::Checker->new();
    open my $errfh, '>', \my $diag;
    $checker->parse_from_file($file, $errfh);
    close $errfh;
    if ($checker->num_errors || $checker->num_warnings) {
        push @bad, [ $file, $checker->num_errors, $checker->num_warnings, $diag ];
    }
}

is(scalar(@bad), 0, 'all modules pass podchecker');
diag("$_->[3]") for @bad;
diag('Modules checked: ' . scalar(@files)) if !@bad;

done_testing;
