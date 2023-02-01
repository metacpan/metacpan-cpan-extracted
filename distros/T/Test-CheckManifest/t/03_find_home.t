#!/usr/bin/perl

use strict;
use warnings;
use File::Spec;
use File::Basename;
use Test::More;
use File::Path qw(make_path remove_tree);
use Test::CheckManifest;
use Cwd;

# create a directory and a file
my $sub = Test::CheckManifest->can('_find_home');
ok $sub;

my $dir  = Cwd::realpath( File::Spec->catdir( dirname( __FILE__ ), '..' ) );
my $file = File::Spec->catfile( $dir, 'MANIFEST' );

my @dirs_one = File::Spec->splitdir( $dir );
my @dirs_two = File::Spec->splitdir( $sub->( {} ) );
is_deeply \@dirs_two, \@dirs_one, 'tmp_path => $0';

my ($vol,$dirs,$file_one) = File::Spec->splitpath($file);

my @dirs_three = File::Spec->splitdir( $sub->( {file => $file} ) );
is_deeply \@dirs_three, \@dirs_one, 'file ' . $file;

my @dirs_five = File::Spec->splitdir( $sub->( { dir  => $dir } )  );
is_deeply \@dirs_five, \@dirs_one, 'dir ' . $dir;

$sub->( { dir => $vol || '/' } );
$sub->( { dir => '/this/dir/does/not/exist/test/checkmanifest' } );

my $deep_path_one = File::Spec->catdir( $dir, 'deep' );
my $deep_path_two = File::Spec->catdir( $deep_path_one, qw/path one and another level to search for/ );
make_path $deep_path_two;
$sub->( { dir => $deep_path_two } );
remove_tree $deep_path_one;

done_testing();
