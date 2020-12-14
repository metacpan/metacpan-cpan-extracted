use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Net::Stomp::Receipt',
    VERSION_FROM      => 'lib/Net/Stomp/Receipt.pm',
    PL_FILES            => {},
    SIGN                => 1,
    PREREQ_PM         => { "Net::Stomp" => 0.34 },
    ABSTRACT_FROM  => 'lib/Net/Stomp/Receipt.pm',
    AUTHOR         => 'Hugo Salgado <huguei@cpan.org>',
    META_MERGE        => {
      'meta-spec' => { version => 2 },
      resources   => {
         bugtracker => {
            "web" => "https://todo.sr.ht/~huguei/perl-Net-Stomp-Receipt",
         },
         repository => {
            type => 'mercurial',
            url => 'https://hg.sr.ht/~huguei/perl-Net-Stomp-Receipt',
            web => 'https://hg.sr.ht/~huguei/perl-Net-Stomp-Receipt'
         }
      }
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-Stomp-Receipt-*' },
);
