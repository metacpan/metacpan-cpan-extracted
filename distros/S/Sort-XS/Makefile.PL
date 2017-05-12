use ExtUtils::MakeMaker;
use Config;

my %CFG = (
    'NAME'          => 'Sort::XS',
    'AUTHOR'        => 'Nicolas R <me@eboxr.com>',
    'VERSION_FROM'  => 'lib/Sort/XS.pm',
    'ABSTRACT_FROM' => 'lib/Sort/XS.pm',
    'PL_FILES'      => {},
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002 ? ( 'LICENSE' => 'perl', ) : () ),
    'PREREQ_PM' => {
        'Test::More' => 0,    # For testing
        'Carp' => 0,
        'XSLoader' => 0,
        'Exporter' => 0,
    },
    'dist'        => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    'clean'       => { FILES    => 'Sort-XS-* *.o' },
    'INSTALLDIRS' => 'site',
    'OBJECT'      => "sort.o XS.o",
    'META_MERGE'  => {
        build_requires => {
            'Test::More' => 0,    # For testing
            'Carp' => 0,
            'XSLoader' => 0,
            'Exporter' => 0,

        },
        resources => { license => 'http://dev.perl.org/licenses/', },
    }
);

if ($Config{"byteorder"} =~ /^1234/) {
    $CFG{'DEFINE'} .= ' -DARCH_IS_BIG_ENDIAN=0';
}

if ($^O =~ /^MSWin/i) {
    $CFG{'DEFINE'} .= ' -DWINDOWS';
}

WriteMakefile(%CFG);
