use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::CIDR::Lookup',
    AUTHOR              => 'Matthias Bethke <matthias@towiski.de>',
    VERSION_FROM        => 'lib/Net/CIDR/Lookup.pm',
	ABSTRACT            => 'Hash-like lookup table based on CIDR blocks',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002 ? ('LICENSE'=> 'perl') : ()),
    PL_FILES            => {},
    MIN_PERL_VERSION    => 5.008008,
    PREREQ_PM => {
        'version'     => 0,
        'parent'      => 0,
        'Bit::Vector' => 0,
        'Socket'      => 1.94,
    },
    BUILD_REQUIRES => {
        'Test::More'                => 0,
        'Test::Class'               => 0,
        'Class::Data::Inheritable'  => 0,
    },
    dist                => { COMPRESS => 'bzip2', SUFFIX => 'bz2', },
    clean               => { FILES => 'Net-CIDR-Lookup-*' },
);
