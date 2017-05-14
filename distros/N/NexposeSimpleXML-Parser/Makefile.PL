use strict;
use warnings;

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME                => 'NexposeSimpleXML::Parser',
    AUTHOR              => 'Joshua D. Abraham < jabra@spl0it.org >',
    VERSION             => '0.04',
    PREREQ_PM           => {
                'Test::More'        => '0',
                'Object::InsideOut' => '0',
                'XML::LibXML'	    => '0',
		'Test::Class'       => '0',
    },
    'INSTALLDIRS' => 'site',    
    'dist' => {
        'SUFFIX'       => ".gz",
        'DIST_DEFAULT' => 'all tardist',
        'COMPRESS'     => "gzip -9f"
    },
    'realclean' => { 'FILES' => '' },
    'clean'     => { 'FILES' => '' },

);

