#!perl -T

use strict;
use warnings;

use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 2;
use Perl::Critic::Policy::CodeLayout::TabIndentSpaceAlign;


can_ok(
	'Perl::Critic::Policy::CodeLayout::TabIndentSpaceAlign',
	'default_themes',
);

isnt(
	Perl::Critic::Policy::CodeLayout::TabIndentSpaceAlign->default_themes(),
	undef,
	'The policy is assigned to a default theme.',
);
