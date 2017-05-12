use strict;
use warnings;

use ExtUtils::MakeMaker;
WriteMakefile(
    NAME                => 'Sslscan::Parser',
    AUTHOR              => 'Joshua "Jabra" Abraham < jabra@spl0it.org >',
    VERSION_FROM        => 'lib/Sslscan/Parser.pm',
    ABSTRACT_FROM       => 'lib/Sslscan/Parser.pod',
    PREREQ_PM           => {
                'Test::More'        => '0',
                'Test::Class'        => '0',
                'Object::InsideOut' => '0',
                'XML::LibXML'	    => '0',
                'File::Temp'	    => '0',
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
