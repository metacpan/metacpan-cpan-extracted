#!/usr/bin/perl

use strict;
use warnings;
use File::Spec;
use File::Basename;
use Test::More;
use Test::CheckManifest;
use Cwd;

# create a directory and a file 
my $sub = Test::CheckManifest->can('_find_home');

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

#$sub->( { dir => $vol // '/' } );

done_testing();
