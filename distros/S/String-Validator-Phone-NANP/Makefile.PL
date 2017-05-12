use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'String::Validator::Phone::NANP',
    AUTHOR              => q{John Karr <brainbuz@brainbuz.org>},
    VERSION_FROM        => 'lib/String/Validator/Phone/NANP.pm',
    ABSTRACT_FROM       => 'lib/String/Validator/Phone/NANP.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'gpl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'String::Validator::Common' => 0.96,
	'Number::Phone' => 2.0,
	'Number::Phone::Country' => 1.7,
	'Number::Phone::NANP' => 1.3,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'String-Validator-Phone-NANP-*' },
);
