use strict;
use warnings;

use ExtUtils::MakeMaker;
use ExtUtils::MakeMaker::Config;

my $output = WriteMakefile(
    NAME           => 'Net::IP::XS',
    AUTHOR         => 'Tom Harrison <tomhrr@cpan.org>',
    LICENSE        => 'gpl',
    VERSION_FROM   => 'lib/Net/IP/XS.pm',
    ABSTRACT_FROM  => 'lib/Net/IP/XS.pm',
    META_MERGE     => {
        resources => {
            repository => 'https://github.com/tomhrr/p5-Net-IP-XS'
        }
    },
    PERL_MALLOC_OK => 1,
    OBJECT         => '$(O_FILES)',
    clean          => { FILES => '$(O_FILES)' },
    PREREQ_PM      => { 'Tie::Simple'         => 0,
                        'Math::BigInt'        => 0,
                        # Test prereqs.
                        'Test::More'          => 0,
                        'IO::Capture::Stderr' => 0 },
);

1;
