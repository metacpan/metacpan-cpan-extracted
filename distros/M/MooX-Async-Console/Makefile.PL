#!/usr/bin/env perl

use 5.014;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;
use File::Find;

sub find_tests {
#define go return
#define home unless
    return unless -e 't';
    my @tests;
    find sub {
        push @tests, $File::Find::name . '/*.t'
          if -d and $File::Find::name !~ m(^t/lib(?:$|/));
    }, 't';
    return sort @tests;
}

WriteMakefile(
  NAME            => 'MooX::Async::Console',
  AUTHOR          => 'Matthew King (cpan:CHOHAG) <chohag@jtan.com>',
  ABSTRACT_FROM   => 'lib/MooX/Async/Console.pm',
  LICENSE         => 'wtfpl_2',

  EXE_FILES       => [<src/*.pl>],
  test => { TESTS => join ' ', find_tests },
  VERSION_FROM    => 'lib/MooX/Async/Console.pm',

  PREREQ_PM       => {
    'perl'                 => '5.024', # 5.016 for S:K:T
    'curry'                => '1',
    'IO::Async'            => '0.71',
    'Import::Into'         => '1.002',
    'List::Util'           => '1.29',
    'Future'               => '0.33',
    'Modern::Perl'         => '1.2017',
    'Moo'                  => '2',
    'Module::Runtime'      => '0.016',
    'MooX::Role::Logger'   => '0.005',
    'namespace::clean'     => '0.27',
    'strictures'           => '2',
    'Syntax::Keyword::Try' => '0.09',
  },
);
