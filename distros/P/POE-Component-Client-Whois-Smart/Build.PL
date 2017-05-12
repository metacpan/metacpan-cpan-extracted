#!/usr/bin/perl -w
use strict;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'POE::Component::Client::Whois::Smart',
    license  => 'perl',
    requires => {
        'POE'               => 0,
        'URI::URL'          => 0,
        'HTTP::Request'     => 0,
        'Hash::MoreUtils'   => 0,
        'Module::Pluggable::Ordered'   => 0,
        'SOAP::DirectI'	    => 0,
	'POE::Filter::Line' => 0,
	'POE::Wheel::ReadWrite'         => 0,
	'POE::Wheel::SocketFactory'     => 0,
	'POE::Component::Client::HTTP'  => 0,
	'POE::Component::SSLify'  => 0,
	'Net::Whois::Raw'   => '1.56',
	'CLASS'		    => 0,
	'Tie::Cache::LRU'   => 0,
	'Time::HiRes'       => 0,
    },
    create_makefile_pl => 'traditional',
);
$build->create_build_script;
