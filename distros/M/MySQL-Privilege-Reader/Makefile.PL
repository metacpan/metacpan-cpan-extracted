use strict;
use warnings;
use ExtUtils::MakeMaker;

# AAARRRGGHHH!! Version Numbering strickes again. :(
# Make ExtUtils::MakeMaker::VERSION numeric with eval() so we
# can compare it to a number later.
my $V = eval "$ExtUtils::MakeMaker::VERSION";

WriteMakefile(
    NAME          => 'MySQL::Privilege::Reader',
    AUTHOR        => q{Luis Motta Campos <lmc@cpan.org>},
    VERSION_FROM  => 'lib/MySQL/Privilege/Reader.pm',
    ABSTRACT_FROM => 'lib/MySQL/Privilege/Reader.pm',
    ( $V >= 6.3002 ? ( 'LICENSE' => 'gpl' ) : () ),
    PL_FILES       => {},
    BUILD_REQUIRES => {
        'Test::More'       => 0,
        'Test::MockObject' => 1.09,
        'Test::Exception'  => 0.29,
    },
    PREREQ_PM => {},
    dist      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'MySQL-Privilege-Reader-*' },
);
