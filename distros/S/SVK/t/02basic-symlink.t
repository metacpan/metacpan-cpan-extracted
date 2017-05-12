#!/usr/bin/perl -w
use Test::More;
use strict;
use SVK::Test;
use SVK::Util qw(HAS_SYMLINK);

if (!HAS_SYMLINK) {
    plan(skip_all => 'symlink not supported');
}

no warnings 'redefine';
sub get_copath {
    my ($name) = @_;
    my $copath = SVK::Path::Checkout->copath ('t', "checkout/$name");
    mkpath [$copath] unless -d $copath;
    $copath = 't/checkout/_real';
    rmtree [$copath] if -e $copath;
    mkdir ($copath);
    unlink 't/checkout/_symlinked';
    symlink (File::Spec->rel2abs($copath), 't/checkout/_symlinked');
    $copath = "t/checkout/_symlinked/$name";
    rmtree [$copath] if -e $copath;
    return ($copath, File::Spec->rel2abs("t/checkout/_real/$name"));
}

local $^W;
my $file = $0;
$file =~ s'-symlink.t'.t';
require $file;

