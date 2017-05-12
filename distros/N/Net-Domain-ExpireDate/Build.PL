#!/usr/bin/perl -w
use strict;
use Module::Build;

my $build = Module::Build->new(
    module_name => 'Net::Domain::ExpireDate',
    license  => 'perl',
    requires => {
        'Getopt::Long' => '2',
        'Net::Whois::Raw' => 1.0,
        'Time::Piece' => 0,
    },
    create_makefile_pl => 'traditional',
    dist_abstract => 'Net::Domain::ExpireDate -- obtain expiration date of domain names',
    meta_merge => {
        resources => {
            repository => 'https://github.com/regru/Net-Domain-ExpireDate'
        }
    },
);

$build->create_build_script;
