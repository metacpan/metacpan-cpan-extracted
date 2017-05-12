use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::Spotify',
    AUTHOR              => 'Edoardo Sabadelli <edoardo@cpan.org>',
    VERSION_FROM        => 'lib/Net/Spotify.pm',
    ABSTRACT_FROM       => 'lib/Net/Spotify.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'LWP::UserAgent' => 0,
        'URI' => 0,
        'URI::QueryParam' => 0,
        'XML::TreePP' => 0,
        'Getopt::Long' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-Spotify-*' },
);
