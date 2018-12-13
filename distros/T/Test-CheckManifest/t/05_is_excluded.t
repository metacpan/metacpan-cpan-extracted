#!/usr/bin/perl

use strict;
use warnings;
use File::Spec;
use File::Basename;
use Test::More;
use Cwd;

use Test::More;
use Test::CheckManifest;

# create a directory and a file 
my $sub = Test::CheckManifest->can('_is_excluded');

my $dir   = Cwd::realpath( dirname __FILE__ );
$dir      =~ s{.t\z}{};
my $file  = File::Spec->catfile( $dir, 'MANIFEST.SKIP' );
my $t_dir = File::Spec->catdir( $dir, 't' );
my $meta  = 'META.yml';

# my ($file,$dirref,$filter,$bool,$files_in_skip,$home) = @_;

my @tests = (
    [
        [ $meta ],
        1,
        $meta,
    ], 
    [
        [ $meta, [] ],
        1,
        "meta, empty dirref",
    ], 
    [
        [ $meta, [$t_dir] ],
        1,
        "meta, t/ directory",
    ], 
    [
        [ __FILE__ ],
        0,
        "this file",
    ], 
    [
        [ __FILE__, [] ],
        0,
        "this file, empty dirref",
    ], 
    [
        [ __FILE__, [ $t_dir ] ],
        0,
        "this file, t/ dir",
    ], 
    [
        [ __FILE__, [ $t_dir ], [qr/excluded/] ],
        1,
        "this file, t/ dir, filter: 'excluded'",
    ], 
    [
        [ __FILE__, [ $t_dir ], [qr/excluded/], 'and' ],
        0,
        "this file, t/ dir, filter: 'excluded', bool => 'and'",
    ], 
    [
        [ __FILE__, [ $t_dir ], [qr/excluded/], 'or' ],
        1,
        "this file, t/ dir, filter: 'excluded', bool => 'or'",
    ], 
    [
        [ __FILE__, [ $t_dir ], [qr/excluded/], 'and', [__FILE__] ],
        1,
        "this file, t/ dir, filter: 'excluded', bool => 'and', excluded",
    ], 
);

for my $test ( @tests ) {
    my ($input, $check, $desc) = @{$test};
    my $ret = $sub->( @{$input} );
    is $ret, $check, $desc;
}


done_testing();
