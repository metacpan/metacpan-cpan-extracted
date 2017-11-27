#!/usr/bin/env perl

use 5.014;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME           => 'Net::Async::Beanstalk',
  AUTHOR         => 'Matthew King (cpan:CHOHAG) <chohag@jtan.com>',
  ABSTRACT_FROM  => 'lib/Net/Async/Beanstalk.pm',
  VERSION_FROM   => 'lib/Net/Async/Beanstalk.pm',
  LICENSE        => 'wtfpl_2',
  PREREQ_PM      => {
    'perl'               => '5.014',
    # TODO: Find out minimum versions of these
    'IO::Async'          => '0',
    'List::Util'         => '0',
    'Moo'                => '0',
    'MooX::EventHandler' => '0',
    'MooX::HandlesVia'   => '0',
    'PerlX::Maybe'       => '0',
    'YAML::Any'          => '0',
    'namespace::clean'   => '0',
    'strictures'         => '2',
  },
);
