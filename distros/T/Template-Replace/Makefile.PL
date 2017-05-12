use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Template::Replace',
    AUTHOR              => q{Christian Augustin <mail@caugustin.de>},
    VERSION_FROM        => 'lib/Template/Replace.pm',
    ABSTRACT_FROM       => 'lib/Template/Replace.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
    	'Carp'       => 0,
    	'Encode'     => 0,
    	'File::Spec::Functions' => 0,
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Template-Replace-*' },
);
