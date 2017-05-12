use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Parse::File::Metadata',
    VERSION_FROM => 'lib/Parse/File/Metadata.pm', # finds \$VERSION
    AUTHOR       => 'James E Keenan (jkeenan@cpan.org)',
    ABSTRACT     => 'For plain-text files that contain metadata (in key-value pairs) and data records, parse metadata first before proceeding',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'Carp' => 0,
                     'File::Spec' => 0,
                     'Scalar::Util' => 0, # changeme
                    },
);
