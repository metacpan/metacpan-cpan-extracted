#!/usr/bin/perl
# $RedRiver: Build.PL,v 1.7 2007/02/21 05:25:33 andrew Exp $
########################################################################
# Build.PL *** the Build.pl for Palm::Keyring
# 
# 2007.01.28 #*#*# andrew fresh <andrew@mad-techies.org>
########################################################################
use strict;
use warnings;

use Module::Build;
my $build = Module::Build->new
(
	module_name => 'Palm::Keyring',
    dist_abstract => 'Handler for Palm Keyring databases.',
	license  => 'perl',
	requires => {
		'perl'             => '5.6.1',
		'Palm::StdAppInfo' => '0',
    },
    recommends => {
		'Digest::MD5'       => '0',
		'Crypt::DES'        => '0',
        'Crypt::CBC'        => '0',
        'Digest::HMAC_SHA1' => '0',
        'Digest::SHA1'      => '0',
	},
	create_makefile_pl => 'traditional',
	create_readme => 1,
	create_html   => 1,
	auto_features => {
		YAML_support =>
		{
			description => "Use YAML.pm to write META.yml files",
			requires => { YAML => ' >= 0.35, != 0.49_01 ' },
		},
		manpage_support =>
		{
			description => "Create Unix man pages",
			requires => { 'Pod::Man' => 0 },
		},
		HTML_support =>
		{
			description => "Create HTML documentation",
			requires => { 'Pod::Html' => 0 },
		},
	},
);
$build->create_build_script;
