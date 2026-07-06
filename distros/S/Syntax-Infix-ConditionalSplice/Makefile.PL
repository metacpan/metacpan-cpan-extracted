use 5.038;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Syntax::Infix::ConditionalSplice',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Syntax/Infix/ConditionalSplice.pm',
    ABSTRACT_FROM    => 'lib/Syntax/Infix/ConditionalSplice.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.038',
    macro => { TARFLAGS => "--format=ustar -c -v -f" },
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => '0' },
    TEST_REQUIRES    => { 'Test::More' => '0' },
    PREREQ_PM        => { 'Infix::Custom' => '0.01' },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Syntax-Infix-ConditionalSplice-*' },
);
