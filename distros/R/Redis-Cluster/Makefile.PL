#!/usr/bin/perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  ABSTRACT           => 'Redis Cluster client for Perl',
  AUTHOR             => [ 'SMS Online <dev.opensource@sms-online.com>' ],
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '6.63_03',
  },
  DISTNAME           => 'Redis-Cluster',
  LICENSE            => 'artistic_2',
  MIN_PERL_VERSION   => '5.008',
  NAME               => 'Redis::Cluster',
  PREREQ_PM          => {
    'Carp'                => 0,
    'Data::Dumper'        => 0,
    'Digest::CRC'         => '0.18',
    'List::MoreUtils'     => '0.22',
    'Params::Validate'    => 0,
    'Redis'               => '1.979',
    'Try::Tiny'           => 0,
  },
  TEST_REQUIRES      => {
    'File::Path'          => 0,
    'Pod::Coverage'       => '0.18',
    'Test::EOL'           => 0,
    'Test::Exception'     => 0,
    'Test::Fixme'         => 0,
    'Test::Kwalitee'      => 0,
    'Test::More'          => 0,
    'Test::Perl::Critic'  => 0,
    'Test::Pod'           => '1.22',
    'Test::Pod::Coverage' => '1.08',
    'Test::Strict'        => 0,
  },
  VERSION            => '0.14',
  test               => { TESTS => 't/*.t' },
);
