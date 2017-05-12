use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'OO::InsideOut',
    AUTHOR              => q{André Rivotti Casimiro <rivotti@cpan.org>},
    VERSION_FROM        => 'lib/OO/InsideOut.pm',
    ABSTRACT_FROM       => 'lib/OO/InsideOut.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'   => 0,
        'Class::Isa'   => 0,
        'Scalar::Util' => "1.09",
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'OO-InsideOut-*' },
);
