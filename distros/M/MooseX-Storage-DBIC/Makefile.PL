use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'MooseX::Storage::DBIC',
    AUTHOR              => q{Mischa Spiegelmock <revmischa@cpan.org>},
    VERSION_FROM        => 'lib/MooseX/Storage/DBIC.pm',
    ABSTRACT_FROM       => 'lib/MooseX/Storage/DBIC.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Test::DBIC' => 0,
        'Test::Memory::Cycle' => 0,
        'SQL::Translator' => 0,

        'MooseX::Storage' => 0,
        'MooseX::NonMoose' => 0,
        'MooseX::MarkAsMethods' => 0,
        'namespace::autoclean' => 0,
        'Data::Dump' => '1.21',
    },
    META_ADD => { resources => { repository => 'git://github.com/revmischa/moosex-storage-dbic.git' } },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'MooseX-Storage-DBIC-*' },
);
