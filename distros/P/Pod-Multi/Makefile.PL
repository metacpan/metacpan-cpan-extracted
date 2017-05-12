#$Id: Makefile.PL 1201 2007-10-27 01:22:17Z jimk $

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Pod::Multi',
    VERSION_FROM => 'lib/Pod/Multi.pm', # finds \$VERSION
    AUTHOR       => 'James E Keenan (jkeenan@cpan.org)',
    ABSTRACT     => 'pod2man, pod2text, pod2html simultaneously',
    EXE_FILES    => [ 'scripts/pod2multi' ],
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'IO::Capture' => 0.05,
                     'Pod::Text' => 0,
                     'Pod::Man' => 0,
                     'Pod::Html' => 0,
                     'Carp' => 0,
                     'File::Basename' => 0,
                     'File::Path' => 0,
                     'File::Spec' => 0,
                     'File::Save::Home' => 0.03,
                     'Data::Dumper' => 0,
                    },
);
