use 5.008001;
use bytes;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'SVN::Dumpfile',
    VERSION_FROM => 'lib/SVN/Dumpfile.pm',    # finds $VERSION
    PREREQ_PM    => {
        'Carp'         => 1.04,
        'Data::Dumper' => 2.121,
        'Digest::MD5'  => 2.36,
        'IO::File'     => 1.13,
        'IO::Handle'   => 1.25,
        'File::Temp'   => 0.20,
        'Date::Parse'  => 2.27,
        'Readonly'     => 1.03,
    },
    (
        $] >= 5.005
        ?    ## Add these new keywords supported since 5.005
          (
            ABSTRACT_FROM => 'lib/SVN/Dumpfile.pm',
            AUTHOR        => 'Martin Scharrer <martin@scharrer-online.de>'
          )
        : ()
    ),

    #PM_FILTER         => 'perl ./strippod',
);

if ( !eval { require Data::UUID } && !eval { require Data::UUID } ) {
    print "\n",
      'You should also install either Data::GUID or Data::UUID to get good ',
      'UUIDs in new created dumpfiles, otherwise they will just be made out ',
      'of random elements.',
      "\n\n";
}
