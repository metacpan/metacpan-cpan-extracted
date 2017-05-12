use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Module::Want',
    AUTHOR        => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    VERSION_FROM  => 'lib/Module/Want.pm',
    ABSTRACT_FROM => 'lib/Module/Want.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'       => 0,
        'Test::Carp'       => 0,
        'File::Spec'       => 0,
        'File::Temp'       => 0,    # testing
        'File::Path::Tiny' => 0,    # testing
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Module-Want-*' },
);
