use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
              NAME => 'Pod::POM::View::Restructured',
              DISTNAME => 'Pod-POM-View-Restructured',
              VERSION_FROM => 'lib/Pod/POM/View/Restructured.pm',
              ABSTRACT_FROM => 'lib/Pod/POM/View/Restructured.pm',
              AUTHOR => 'Don Owens <don@regexguy.com>',
              LICENSE => 'perl',
              EXE_FILES => [ 'bin/pod2rst' ],
              PREREQ_PM => { 'Pod::POM' => 0 },
              clean => { FILES => 'Pod-POM-View-Restructured-*.tar.gz' },
);
