#!/usr/bin/perl

use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    dist_name           => 'OOTools',
    dist_author         => [
	'Domizio Demichelis - perl.4pro.net {Original Author}',
	'Sebastian Knapp <sknpp@cpan.org> {Maintainer}'
    ],
    dist_version_from   => './lib/Class/props.pm',
    dist_abstract       => 'Pragmas to implement constructors and accessors',
    license             => 'perl',
    
    requires => {
        'perl'          => '5.006_001'
    },
    build_requires => {
        'Test::More' => 0,
	'Test::Pod' => 0,
	'CGI' => 0
    },
    add_to_cleanup      => [ 'OOTools-*' ],
    create_makefile_pl  => 'traditional', 
);

$builder->create_build_script();
