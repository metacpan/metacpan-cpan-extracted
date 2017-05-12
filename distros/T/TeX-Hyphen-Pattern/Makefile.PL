use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    ( MM->can('signature_target') ? ( SIGN => 1 ) : () ),
    NAME         => 'TeX::Hyphen::Pattern',
    VERSION_FROM => 'lib/TeX/Hyphen/Pattern.pm',
    PL_FILES     => {},
    PREREQ_PM    => {
        'Class::Meta::Express' => 0,
        'Encode'               => 0,
        'File::Temp'           => 0,
        'Log::Log4perl'        => 0,
        'Module::Pluggable'    => 0,
        'Readonly'             => 0,
        'Set::Scalar'          => 0,
        'Test::More'           => 0.81,
        'Test::NoWarnings'     => 0,
        'version'              => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'TeX-Hyphen-Pattern-*' },
    (
        $] >= 5.005 ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM =>
              'lib/TeX/Hyphen/Pattern.pm',    # retrieve abstract from module
            AUTHOR => 'Roland van Ipenburg <ipenburg@xs4all.nl>'
          )
        : ()
    ),
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002 ?
          ( 'LICENSE' => 'perl', )
        : () ),
);
