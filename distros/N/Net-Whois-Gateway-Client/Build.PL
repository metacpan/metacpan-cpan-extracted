#!/usr/bin/perl -w
use strict;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Net::Whois::Gateway::Client',
    license  => 'perl',
    requires => {
	'Storable' => 0,
	'bytes' => 0, 
    },
    create_makefile_pl => 'traditional',
    script_files => [ 'script/nwhois.pl' ],
);

$build->create_build_script;
