use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'SWISH',
    'VERSION_FROM'  => 'SWISH.pm', # finds $VERSION
    'NORECURS'      => 1,          # keep it from recursing into subdirectories
    'DIR'           => [],

    'dist' => {
        COMPRESS    =>"gzip",
        SUFFIX      =>"gz",
        # PREOP       => 'pod2text -80 < SWISH.pm > README',
        },

);
