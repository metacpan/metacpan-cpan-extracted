#!/usr/bin/perl

use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    dist_name           => 'Template-Magic',
    dist_author         => 'Domizio Demichelis - perl.4pro.net',
    dist_version_from   => './lib/Template/Magic.pm',
    dist_abstract       => 'Template using dynamic scoped vars and more',
    license             => 'perl',
    
    requires => {
        'perl'          => '5.006_001',
        'Class::constr' => 2.1,
        'Class::props'  => 2.1,
        'Object::props' => 2.1,
        'Class::Util'   => 2.1,
        'IO::Util'      => 1.46,
        'File::Spec'    => 0
    },
    recommends => {
	'HTML::TableTiler' => 1.21,
        'HTML::FillInForm' => 1.07
    },	
    build_requires => {
        'Test::More' => 0
    },
    add_to_cleanup      => [ 'Template-Magic-*' ],
    create_makefile_pl  => 'traditional', 
);

$builder->create_build_script();
