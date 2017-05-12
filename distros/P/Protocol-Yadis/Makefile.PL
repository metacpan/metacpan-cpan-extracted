use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Protocol::Yadis',
    AUTHOR        => 'Viacheslav Tykhanovskyi <vti@cpan.org>',
    VERSION_FROM  => 'lib/Protocol/Yadis.pm',
    ABSTRACT_FROM => 'lib/Protocol/Yadis.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ('LICENSE' => 'perl')
        : ()),
    PL_FILES  => {},
    PREREQ_PM => {
        'Test::More'  => '0',
        'XML::LibXML' => '2.0108'
    },
    dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz'},
    test  => {TESTS    => 't/*.t t/*/*.t'},
    clean => {FILES    => 'Protocol-Yadis-*'}
);
