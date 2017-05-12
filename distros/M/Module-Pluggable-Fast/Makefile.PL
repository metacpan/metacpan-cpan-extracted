use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Module::Pluggable::Fast',
    'VERSION_FROM' => 'Fast.pm',
    'PREREQ_PM'    => { UNIVERSAL::require => 0, File::Find => 0 }
);
