use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Silly::Werder',
    'VERSION_FROM' => 'Werder.pm',
    'PREREQ_PM'    => { 'Storable' => 0,
                        'File::Spec' => 0,
                      },

    dist => { COMPRESS => "gzip", SUFFIX => "gz" }

);
