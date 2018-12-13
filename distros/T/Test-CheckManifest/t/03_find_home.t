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
my $sub = Test::CheckManifest->can('_find_home');

my $dir  = Cwd::realpath( dirname __FILE__ );
$dir     =~ s{.t\z}{};
my $file = File::Spec->catfile( $dir, 'MANIFEST' );

is $sub->( {} ), $dir, 'tmp_path => $0';
is $sub->( { file => $file } ), $dir, 'file';
is $sub->( { dir  => $dir } ), $dir, 'dir';

done_testing();
