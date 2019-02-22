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

my $abs_t_file = File::Spec->rel2abs( __FILE__ );
my $bak_t_file = $abs_t_file . '.bak';

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
        [ $abs_t_file ],
        0,
        "this file",
    ], 
    [
        [ $abs_t_file, [] ],
        0,
        "this file, empty dirref",
    ], 
    [
        [ $abs_t_file, [ $t_dir ] ],
        1,
        "this file, t/ dir",
    ], 
    [
        [ $abs_t_file, [ $t_dir ], [qr/excluded/] ],
        2,
        "this file, t/ dir, filter: 'excluded'",
    ], 
    [
        [ $abs_t_file, [ $t_dir ], [qr/excluded/], 'and' ],
        1,
        "this file, t/ dir, filter: 'excluded', bool => 'and'",
    ], 
    [
        [ $abs_t_file, [ $t_dir ], [qr/not_excluded/] ],
        1,
        "this file, t/ dir, filter: 'not_excluded'",
    ], 
    [
        [ $abs_t_file, [ $t_dir ], [qr/not_excluded/], 'and' ],
        0,
        "this file, t/ dir, filter: 'not_excluded', bool => 'and'",
    ], 
    [
        [ $abs_t_file, [ $t_dir ], [qr/excluded/], 'and', [] ],
        1,
        "this file, t/ dir, filter: 'excluded', bool => 'and', empty files_in_skip",
    ], 
    [
        [ $abs_t_file, [ $t_dir ], [qr/excluded/], 'and', [qr/\Q$abs_t_file\E/] ],
        1,
        "this file, t/ dir, filter: 'excluded', bool => 'and', skip this file",
    ], 
    [
        [ $abs_t_file . '.bak', [ $t_dir ], [qr/excluded/], 'and', [qr/\Q$bak_t_file\E/] ],
        1,
        "<this_file>.bak, t/ dir, filter: 'excluded', bool => 'and', skip backup of this file",
    ], 
    [
        [ '/tmp/test', [ $t_dir ], [qr/excluded/], 'and', [qr/\Q$bak_t_file\E/] ],
        0,
        "/tmp/test, t/ dir, filter: 'excluded', bool => 'and', skip backup of this file",
    ], 
    [
        [ '/tmp/test', [ $t_dir ], [qr/excluded/], 'and', ['/test'], '/tmp' ],
        1,
        "/tmp/test, t/ dir, filter: 'excluded', bool => 'and', skip /test in /tmp",
    ], 
    [
        [ $abs_t_file, [ $t_dir ], [qr/excluded/], 'and', [qr/\Q$bak_t_file\E/] ],
        1,
        "this file, t/ dir, filter: 'excluded', bool => 'and', skip backup of this file",
    ], 
    [
        [ $abs_t_file, [ $t_dir ], [qr/excluded/], 'and', {} ],
        0,
        "this file, t/ dir, filter: 'excluded', bool => 'and', wrong reftype files_in_skip",
    ], 
    [
        [ $abs_t_file, [ $t_dir ], [qr/excluded/], 'and' ],
        1,
        "this file, t/ dir, filter: 'excluded', bool => 'and'",
    ], 
    [
        [ $abs_t_file, [ $t_dir ], [qr/excluded/], 'or' ],
        2,
        "this file, t/ dir, filter: 'excluded', bool => 'or'",
    ], 
    [
        [ $abs_t_file, [ $t_dir ], [qr/excluded/], 'and', [qr/\Q$abs_t_file\E/] ],
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
