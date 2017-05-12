#!/usr/bin/perl

use 5.006;
use strict;
use warnings;

use ExtUtils::MakeMaker;
use File::Find;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) {
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

WriteMakefile(
    NAME              => "Test::DBGp",
    VERSION_FROM      => "lib/Test/DBGp.pm",
    ABSTRACT_FROM     => "lib/Test/DBGp.pm",
    AUTHOR            => 'Mattia Barbon <mbarbon@cpan.org>',
    PREREQ_PM         => {
        'Test::Differences'         => '0.63',
        'File::Temp'                => 0,
    },
    ( $mm_ver >= 6.48 ?     ( MIN_PERL_VERSION  => 5.006 ) :
                            () ),
    ( $mm_ver >= 6.31 ?     ( LICENSE           => 'perl_5' ) :
                            () ),
    ( $mm_ver >= 6.46 ?
      ( META_MERGE  => {
          "meta-spec" => { version => 2 },
          resources   => {
              license     => [ 'http://dev.perl.org/licenses/' ],
#              homepage    => 'https://github.com/mbarbon/test-dbgp',
              bugtracker  => {
                  web    => 'https://github.com/mbarbon/test-dbgp/issues',
              },
              repository  => {
                  url  => 'git@github.com:mbarbon/test-dbgp.git',
                  web  => 'https://github.com/mbarbon/test-dbgp',
                  type => 'git',
              },
          },
        },
      ) : () ),
);
