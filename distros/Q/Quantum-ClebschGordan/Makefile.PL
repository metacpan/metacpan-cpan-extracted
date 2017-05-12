use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Quantum::ClebschGordan',
    AUTHOR              => 'David Westbrook <dwestbrook@gmail.com>',
    VERSION_FROM        => 'lib/Quantum/ClebschGordan.pm',
    ABSTRACT_FROM       => 'lib/Quantum/ClebschGordan.pm',
    PL_FILES            => {},
    EXE_FILES           => [ 'bin/cg-j1j2' ],
    PREREQ_PM => {
        'Test::More'       => 0.44,
	'Number::Fraction' => 1.09,
	'Memoize'          => 0,
	'Class::Accessor'  => 0,
	'Carp'             => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Quantum-ClebschGordan-*' },
);
