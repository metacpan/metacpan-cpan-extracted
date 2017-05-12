#!/usr/bin/perl -w
use strict;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Net::Whois::Gateway::Server',
    license  => 'perl',
    requires => {
	'POE' => 0,
	'POE::Component::Server::TCP' => 0,
	'POE::Filter::Reference' => 0, 
	'POE::Component::Client::Whois::Smart' => '0.11',
        'Proc::Daemon' => 0,
        'Proc::PID::File' => 0,
        'Net::Ifconfig::Wrapper' => 0,
    },
    create_makefile_pl => 'traditional',
    script_files => 'script/whois-gateway-d',
);

$build->create_build_script;
