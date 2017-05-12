use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::MakeMaker::CPANfile;

# Normalize version strings like 6.30_02 to 6.3002,
# so that we can do numerical comparisons on it.
my $eumm_version = $ExtUtils::MakeMaker::VERSION;
$eumm_version =~ s/_//;

WriteMakefile(
    NAME                => 'MooseX-Role-REST-Consumer',
    AUTHOR              => q{Shutterstock Webstack Team},
    VERSION_FROM        => 'lib/MooseX/Role/REST/Consumer.pm',
    ABSTRACT            => 'Take a REST inside Moose',
    ($eumm_version >= 6.3001
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Moose'                       => 0,
        'MooseX::Role::Parameterized' => 0,
        'REST::Consumer'              => 0,
        'Test::Exception'             => 0,
        'Try::Tiny'                   => 0,
        'Test::Easy'                  => 0,
        'WWW::Curl::UserAgent'        => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'MooseX-Role-REST-Consumer-*' },
);
