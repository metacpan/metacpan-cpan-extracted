#!/usr/bin/perl -w

require 5.008001;

use strict;
use ExtUtils::MakeMaker;

eval 'use ExtUtils::MakeMaker::Coverage';

eval 'use Set::IntSpan::Fast::XS';

warn "================================================\n"
 . "For even faster set handling consider installing\n"
 . "Set::IntSpan::Fast::XS\n"
 . "================================================\n"
 if $@;

WriteMakefile(
  ( MM->can( 'signature_target' ) ? ( SIGN => 1 ) : () ),
  NAME          => 'Set::IntSpan::Fast',
  AUTHOR        => 'Andy Armstrong <andy@hexten.net>',
  VERSION_FROM  => 'lib/Set/IntSpan/Fast.pm',
  ABSTRACT_FROM => 'lib/Set/IntSpan/Fast.pm',
  LICENSE       => 'perl',
  PL_FILES      => {},
  PREREQ_PM     => {
    'Test::More'  => 0,
    'Data::Types' => 0,
    'List::Util'  => 0,
  },
  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES    => 'Set-IntSpan-Fast-*' },
);
