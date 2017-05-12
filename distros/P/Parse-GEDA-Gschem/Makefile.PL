use strict;
use warnings;
use ExtUtils::MakeMaker;
use 5.10.0;

WriteMakefile(
    NAME             => 'Parse::GEDA::Gschem',
    AUTHOR           => 'JP Fricker <JPFRICKER@CPAN.org>',
    VERSION_FROM     => 'lib/Parse/GEDA/Gschem.pm',
    ABSTRACT         => 'gEDA/gaf gschem file parser',
    PL_FILES         => {},
    PREREQ_PM        => {
        'File::Copy'        => 0,
        'File::Basename'    => 0,
        'Data::Dumper'      => 0,
        'Parse::RecDescent' => '1.96.0',
        'Test::More'        => 0,
        'version'           => 0,
        'Exporter'          => 0,
    },
    dist             => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean            => { FILES => 'Parse-GEDA-Gschem-*' },
);
