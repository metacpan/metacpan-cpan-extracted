

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Set::Partitions::Similarity',
    VERSION_FROM => 'lib/Set/Partitions/Similarity.pm', # finds \$VERSION
    AUTHOR       => 'Jeff Kubina (jeff.kubina@gmail.com)',
    ABSTRACT     => 'Routines to measure similarity of partitions.',
    PREREQ_PM    => {
                     'Data::Dump' => '1.19',
                     'List::MoreUtils' => '0.33',
                     'Text::CSV' => '1.21',
                    },
    LICENSE      => 'perl',
);
__END__
# Below are the automatically recommended values for PREREQ_PM.
    PREREQ_PM    => {
                     # list of core modules used:
                     'Getopt::Long' => '2.38',
                     'Pod::Usage' => '1.36',
                     'strict' => '1.04',
                     'Test::More' => '0.98',
                     'vars' => '1.02',
                     'warnings' => '1.12',

                     # list of installed modules used:
                     'Data::Dump' => '1.19',
                     'List::MoreUtils' => '0.33',
                     'Text::CSV' => '1.21',

                     # list of unknown modules used:
                    },