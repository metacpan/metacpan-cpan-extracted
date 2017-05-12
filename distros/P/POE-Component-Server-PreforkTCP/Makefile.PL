#! /usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME		=> 'POE::Component::Server::PreforkTCP',
    ABSTRACT		=> 'POE component to make a prefork tcp server',
    VERSION_FROM	=> 'PreforkTCP.pm', 
    PREREQ_PM		=> {
				POE =>0.22
			}, 
    ABSTRACT_FROM	 => 'PreforkTCP.pm', 
    AUTHOR     		=> 'Wang,Bo <wb@95700.net>',

    dist	=> {
			COMPRESS =>'gzip -9f',
			SUFFIX 	 =>'gz',
		},
);
