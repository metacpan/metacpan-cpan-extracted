#!/usr/bin/perl

use strict;
use Test::More tests => 3;
use File::Spec;

use Template::TT2Site;

my $ok = 0;
my $lib = "";
foreach my $i ( keys(%INC) ) {
    next unless $i =~ /^Template.TT2Site\.pm$/;
    $lib = $INC{$i};
}
$lib =~ s/.Template.TT2Site\.pm$//;

ok( -s File::Spec->catfile($lib,
			   qw(Template TT2Site.pm)),
    "module found in $lib");

$lib = File::Spec->catfile($lib, qw(Template TT2Site));

ok( -s File::Spec->catfile($lib,
			   qw(lib config site.base)),
    "lib files found in $lib");

ok( -s File::Spec->catfile($lib,
			   qw(setup data src css site.css)),
    "setup files found in $lib");
