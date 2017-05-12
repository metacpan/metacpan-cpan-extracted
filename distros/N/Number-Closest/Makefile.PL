use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Number::Closest',
    AUTHOR              => 'Mike Accardo <accardo@cpan.org>',
    VERSION_FROM        => 'lib/Number/Closest.pm',
    ABSTRACT_FROM       => 'lib/Number/Closest.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Moose' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Number-Closest-*' },
);
