#!/usr/bin/perl -w
use strict;
use Test;
use blib;

BEGIN { plan tests => 2 }

use Template::Provider::MD5;
use Template;

ok(1);	# Hey we have loaded the modules

my $config = {
	# XXX Make it work on windows !
	INCLUDE_PATH    => "/tmp",
	EVAL_PERL       => 0,
	COMPILE_DIR     => "/tmp/ttcache",
	COMPILE_EXT     => '.ttc',
};

my $p = Template::Provider::MD5->new($config);
$config->{LOAD_TEMPLATES} = [$p];
$config->{PREFIX_MAP} = {default => 0};
my $tt = Template->new($config);

ok(ref($tt));

