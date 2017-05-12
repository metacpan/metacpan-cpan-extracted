use strict;
use warnings;
use ExtUtils::MakeMaker;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # dev version
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

WriteMakefile(
    NAME            => 'Mock::Net::Ping',
    AUTHOR          => 'Matthew Musgrove <mr.muskrat@gmail.com>',
    VERSION_FROM    => 'lib/Mock/Net/Ping.pm',
    ABSTRACT_FROM   => 'lib/Mock/Net/Ping.pm',
    PL_FILES        => {},
    PREREQ_PM       => {
        'Net::Ping'         => 2.31, # 28 Jun 2003
        'Socket'            => 0,
    },
    BUILD_REQUIRES  => {
        'Test::Exception'   => 0,
    },
    INSTALLDIRS     => 'site',
    dist            => { COMPRESS => 'gzip -9f', SUFFIX => '.gz', },
    clean           => { FILES => 'Mock-Net-Ping-*' },
    ($mm_ver < 6.46 ? () : (META_MERGE => {
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            homepage    => 'http://github.com/mrmuskrat/Mock-Net-Ping/',
            bugtracker  => 'http://github.com/mrmuskrat/Mock-Net-Ping/issues/',
            repository  => 'http://github.com/mrmuskrat/Mock-Net-Ping/',
        },
    })),
    ($mm_ver >= 6.48
        ? (MIN_PERL_VERSION => 5.006)
        : ()
    ),
);
