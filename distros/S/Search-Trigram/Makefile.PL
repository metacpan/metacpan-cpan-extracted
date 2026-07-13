use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Search::Trigram',
    VERSION_FROM     => 'lib/Search/Trigram.pm',
    ABSTRACT_FROM    => 'lib/Search/Trigram.pm',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => '0' },
    TEST_REQUIRES    => { 'Test::More' => '0.88' },
    PREREQ_PM        => {},
    INC              => '-I. -Iinclude',
    OBJECT           => '$(BASEEXT)$(OBJ_EXT) strigram$(OBJ_EXT)',
    C                => ['strigram.c'],
    macro            => { TARFLAGS => '--format=ustar -c -v -f' },
    dist             => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean            => { FILES => 'Search-Trigram-*' },
);
