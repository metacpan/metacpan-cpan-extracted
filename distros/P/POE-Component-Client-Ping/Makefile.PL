#!/usr/bin/perl

use ExtUtils::MakeMaker;

# Touch CHANGES so it exists.
open(CHANGES, ">>CHANGES") and close CHANGES;

WriteMakefile(
  NAME         => 'POE::Component::Client::Ping',
  AUTHOR       => 'Rocco Caputo <rcaputo@cpan.org>',
  ABSTRACT     => 'POE component for non-blocking/concurrent ICMP ping.',
  LICENSE      => 'perl',
  VERSION_FROM => 'lib/POE/Component/Client/Ping.pm',
  META_ADD     => {
    resources  => {
      license    => 'http://dev.perl.org/licenses/',
      repository => 'http://github.com/rcaputo/poe-component-client-ping/'
    },
  },
  PREREQ_PM    => {
    'POE'         => 1.007,
    'Time::HiRes' => 1.20,
  },
  dist         => {
    COMPRESS   => 'gzip -9f',
    SUFFIX     => 'gz',
    PREOP      => (
      'git-log.pl | tee ./$(DISTNAME)-$(VERSION)/CHANGES > ./CHANGES'
    ),
  },
);
