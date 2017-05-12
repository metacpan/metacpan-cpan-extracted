use strict;
use warnings;
use ExtUtils::MakeMaker;

if ( -e 'MANIFEST' ) {
    system( 'pod2text lib/Padre/Plugin/Encode.pm > README' );
}

WriteMakefile(
    NAME                => 'Padre::Plugin::Encode',
    AUTHOR              => 'Keedi Kim - 김도형 <keedi@cpan.org>',
    VERSION_FROM        => 'lib/Padre/Plugin/Encode.pm',
    ABSTRACT_FROM       => 'lib/Padre/Plugin/Encode.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'       => 0,
        'version'          => 0,
        'Encode'           => '2.26',
        'Wx::Perl::Dialog' => '0.04',
        'Padre'            => '0.23',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Padre-Plugin-Encode-*' },
);
