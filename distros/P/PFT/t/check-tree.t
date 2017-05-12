#!/usr/bin/perl -w

use v5.16;

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw/tempdir/;
use File::Spec;

use PFT::Tree;

my $dir = tempdir(CLEANUP => 1);

is(eval{ PFT::Tree->new($dir) }, undef, 'Error unless created');
isnt($@, undef, 'Value set for $@ (follows)');
diag($@);

my $tree = eval { PFT::Tree->new($dir, {create => 1}) };
diag('Empty string should follow: ', $@ || '');
isnt($tree, undef, 'Ok with create');

is_deeply(
    PFT::Tree->new(File::Spec->catdir($dir, 'content')),
    $tree,
    'Retrieve existing tree from subdir'
);

is(
    eval{PFT::Tree->new(
        File::Spec->catdir($dir, 'content'), {create => 1}
    )},
    undef,
    'Nested double creation error'
);
ok($@ =~ /nest/, 'Error is sound');

done_testing()
