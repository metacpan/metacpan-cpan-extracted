use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile( NAME          => 'Pod::Trac',
               LICENSE       => 'perl',
               AUTHOR        => 'franck cuny <franck.cuny@gmail.com>',
               VERSION_FROM  => 'lib/Pod/Trac.pm',
               ABSTRACT_FROM => 'lib/Pod/Trac.pm',
               PL_FILES      => {},
               PREREQ_PM     => {
                              'Test::More'            => 0,
                              'version'               => 0,
                              'Test::Perl::Critic'    => 0,
                              'File::Util'            => 0,
                              'URI::Escape'           => 0,
                              'HTTP::Request::Common' => 0,
                              'LWP::UserAgent'        => 0,
                              'HTTP::Cookies'         => 0,
                              'Pod::Simple::Wiki'     => 0,
                              'Class::Accessor::Fast' => 0,
               },
               dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
               clean => { FILES    => 'Pod-Trac-*' },
);
