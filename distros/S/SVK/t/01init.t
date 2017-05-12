#!/usr/bin/perl -w
use strict;
use SVK::Util qw( catfile tmpdir );
use File::Spec;
use Test::More tests => 2;
use SVK::Test;

our ($answer, $output, @TOCLEAN);
my $repospath = catdir(tmpdir(), "svk-$$-".int(rand(1000)));
mkdir ($repospath);
my $xd = SVK::XD->new (depotmap => {},
		       svkpath => catfile ($repospath, '.svk'),
		       checkout => Data::Hierarchy->new);
ok (-e catfile ($repospath, '.svk'));
ok (-e catfile ($repospath, '.svk', 'cache'));
my $svk = SVK->new (xd => $xd, output => \$output);

rmtree [$repospath];
