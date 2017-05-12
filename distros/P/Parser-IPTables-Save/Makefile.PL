use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Parser::IPTables::Save',
    AUTHOR              => q{Geovanny Junio <geovannyjs@gmail.com>},
    VERSION_FROM        => 'lib/Parser/IPTables/Save.pm',
    ABSTRACT_FROM       => 'lib/Parser/IPTables/Save.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
		'Tie::File' => 0,
		'Carp' => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Parser-IPTables-Save-*' },
);
