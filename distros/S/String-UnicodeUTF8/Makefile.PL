use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'String::UnicodeUTF8',
    AUTHOR        => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    VERSION_FROM  => 'lib/String/UnicodeUTF8.pm',
    ABSTRACT_FROM => 'lib/String/UnicodeUTF8.pm',
    PL_FILES      => {},
    LICENSE       => 'perl',
    PREREQ_PM     => {
        'Test::More'          => 0,     # for testing, I know I know: Test::XT
        'String::Unquotemeta' => 0,
        'Module::Want'        => 0.6,
        'B::Flags'            => 0,     # make optional?
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'String-UnicodeUTF8-*' },
);
