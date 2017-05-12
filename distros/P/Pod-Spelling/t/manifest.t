use strict;
use warnings;
my $VERSION = 2;

# Copyright (C) Lee Goddard 2001 ff. All Rights Reserved.

use lib 'lib';
use ExtUtils::testlib;
use ExtUtils::Manifest;
use Cwd;
use Data::Dumper;
use Test::More tests => 3;

# ExtUtils::Manifest::mkmanifest();

my ($missing, $extra) = ExtUtils::Manifest::fullcheck();

@_ = grep {/\.t$/} @$missing;
is( scalar(@_), 0, 'No tests missing from manifest') or &list('missing',@_);

@_ = grep {/\.pm$/} @$missing;
is( scalar(@_), 0, 'No PMs missing from manifest') or &list('missing',@_);

is( scalar(@$extra), 0, 'No un-MANIFESTed files found') or &list('Found un-MANIFEST-ed', @$extra );

sub list {
	my $what = shift;
	diag map {"\t$what ".('.'x20)." $_\n"} @_;
}

