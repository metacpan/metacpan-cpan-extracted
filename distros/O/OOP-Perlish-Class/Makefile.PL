use strict;
use warnings;
use ExtUtils::MakeMaker;

use 5.008;

WriteMakefile(
    NAME                => 'OOP::Perlish::Class',
    AUTHOR              => q{Jamie Beverly <jbeverly@cpan.org>},
    VERSION_FROM        => 'lib/OOP/Perlish/Class.pm',
    ABSTRACT_FROM       => 'lib/OOP/Perlish/Class.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    	'Test::Class' => 0.3,
	    'Tie::IxHash' => 1,
	    'Scalar::Util' => 1.2,
	    'Data::Dumper' => 1,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'OOP-Perlish-Class-*' },
);
