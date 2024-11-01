#!/usr/bin/perl
use 5.016;
use strict;

use Test::More;

use Slackware::SBoKeeper;

plan tests => 7;

# Tests:
# * All packages methods

my $TEST_REPO = 't/data/repo';

my $sbokeeper = Slackware::SBoKeeper->new(
	'',
	$TEST_REPO
);

$sbokeeper->add(['a', 'b', 'f'], 1);

my @all       = qw(a b c d e f);
my @manual    = qw(a b f);
my @nonmanual = qw(c d e);

my @pkgs;

@pkgs = $sbokeeper->packages('all');
is_deeply(\@pkgs, \@all,       'packges("all") list is ok');

@pkgs = $sbokeeper->packages('manual');
is_deeply(\@pkgs, \@manual,    'packages("manual") list is ok');

@pkgs = $sbokeeper->packages('nonmanual');
is_deeply(\@pkgs, \@nonmanual, 'packages("nonmanual") list is ok');

$sbokeeper->remove(['f']);

my @necessary   = qw(a b);
my @unnecessary = qw(c d e);

@pkgs = $sbokeeper->packages('necessary');
is_deeply(\@pkgs, \@necessary,   'packages("necessary") list is ok');

@pkgs = $sbokeeper->packages('unnecessary');
is_deeply(\@pkgs, \@unnecessary, 'packages("unnecessary") list is ok');

$sbokeeper->remove(['a', 'b', 'c', 'd', 'e']);
$sbokeeper->tack(['f'], 1);

my @missing = qw(a b e);
my %missinghash = ( 'f' => ['a', 'b', 'e',], );

@pkgs = $sbokeeper->packages('missing');
is_deeply(\@pkgs, \@missing,            'packages("missing") list is ok');
my %missingret = $sbokeeper->missing();
is_deeply(\%missingret, \%missinghash, 'missing() hash ok');
