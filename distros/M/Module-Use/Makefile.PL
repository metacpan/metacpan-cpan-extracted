use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'                      =>      'Module::Use',
    'VERSION_FROM'      =>      'lib/Module/Use.pm', # finds $VERSION
        'dist'                  =>      { COMPRESS=>"gzip", SUFFIX=>"gz" },
);

