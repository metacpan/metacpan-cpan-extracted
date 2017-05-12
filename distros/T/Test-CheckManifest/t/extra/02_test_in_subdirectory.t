#!/usr/bin/perl -T

use strict;
use warnings;
use File::Spec;
use File::Basename;
use Test::More;

eval "use Test::CheckManifest tests => 1";
plan skip_all => "Test::CheckManifest required" if $@;

ok_manifest({filter => [qr/\.(?:svn|git|build)/]},'Filter: \.(?:svn|git)');


