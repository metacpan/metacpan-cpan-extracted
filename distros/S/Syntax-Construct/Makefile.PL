use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

my $lib_file = 'lib/Syntax/Construct.pm';

sub extract_version {
    open my $F, '<', $lib_file or die $!;
    while (<$F>) {
        return $1 if /^our \$VERSION = '(.*)'/;
    }
}

WriteMakefile(
    NAME             => 'Syntax::Construct',
    AUTHOR           => q{E. Choroba <choroba@cpan.org>},
    VERSION_FROM     => $lib_file,
    ABSTRACT_FROM    => $lib_file,
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    META_MERGE       => {
                        resources => { repository => 'https://github.com/choroba/syntactic-construct' },
                        provides  => { 'Syntax::Construct' => {
                                             file    => $lib_file,
                                             version => extract_version(),
                                          },
                                     },
                        },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'File::Spec' => 0,
        'FindBin'    => 0,
    },
    PREREQ_PM => {
        Config => 0,
    },
    macro => { TARFLAGS => '--format=ustar -cvf' },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Syntax-Construct-*' },
);
