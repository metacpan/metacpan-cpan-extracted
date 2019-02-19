#!/usr/bin/env perl

use strict;
use warnings;

use File::Basename;
use File::Spec;
use Test::More;
use Test::CheckManifest;

use Cwd;

local $ENV{NO_MANIFEST_CHECK} = 1;

my $sub = Test::CheckManifest->can('_manifest_files');
ok $sub;

my $dir = dirname __FILE__;
my $manifest = File::Spec->catfile( $dir, '..', 'MANIFEST' );

my @files = $sub->( $dir, $manifest );
ok @files;

done_testing();
