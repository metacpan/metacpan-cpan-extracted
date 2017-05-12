#!/usr/bin/perl -w

use ExtUtils::MakeMaker;
use strict;

require 5.008;

my %deps = (
        'Pod::Simple'  => 0,
);

my %resources = (
    homepage    => 'http://jmcnamara.github.com/pod-simple-wiki/',
    repository  => 'http://github.com/jmcnamara/pod-simple-wiki',
    bugtracker  => 'http://github.com/jmcnamara/pod-simple-wiki/issues',
);

my %params = (
    'AUTHOR'        => 'John McNamara (jmcnamara@cpan.org)',
    'NAME'          => 'Pod::Simple::Wiki',
    'ABSTRACT_FROM' => 'lib/Pod/Simple/Wiki.pm',
    'VERSION_FROM'  => 'lib/Pod/Simple/Wiki.pm',
    'NEEDS_LINKING' => 0,
    'dist'          => { COMPRESS => 'gzip --best', SUFFIX => 'gz' },
    'EXE_FILES'     => ['bin/pod2wiki'],
    'LICENSE'       => 'perl',
    'PREREQ_PM'     => \%deps,
);

if ( $ExtUtils::MakeMaker::VERSION ge '6.46' ) {
    $params{META_MERGE} = { resources => \%resources };
}

if ( $ExtUtils::MakeMaker::VERSION ge '6.30_01' ) {
    $params{LICENSE} = 'perl';
}

WriteMakefile(%params);
