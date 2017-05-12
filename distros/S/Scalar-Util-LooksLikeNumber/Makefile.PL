# -*- perl -*-
BEGIN { require 5.006; }
use strict;
use warnings;
use Config;
use File::Spec;
use ExtUtils::MakeMaker;
my $PERL_CORE = grep { $_ eq 'PERL_CORE=1' } @ARGV;

WriteMakefile(
  NAME         => q[Scalar::Util::LooksLikeNumber],
  ABSTRACT     => q[Access to looks_like_number() perl API function],
  AUTHOR       => q[Steven Haryanto <stevenharyanto@gmail.com>],
  DEFINE       => q[-DPERL_EXT],
  DISTNAME     => q[Scalar-Util-LooksLikeNumber],
  VERSION_FROM => 'lib/Scalar/Util/LooksLikeNumber.pm',

  # We go through the ListUtil.xs trickery to foil platforms
  # that have the feature combination of
  # (1) static builds
  # (2) allowing only one object by the same name in the static library
  # (3) the object name matching being case-blind
  # This means that we can't have the top-level util.o
  # and the extension-level Util.o in the same build.
  # One such platform is the POSIX-BC BS2000 EBCDIC mainframe platform.
  XS     => {'LooksLikeNumber.xs' => 'LooksLikeNumber.c'},
  OBJECT => 'LooksLikeNumber$(OBJ_EXT)',
  ( $PERL_CORE
    ? ()
    : (
      INSTALLDIRS => ($] < 5.011 ? q[perl] : q[site]),
      PREREQ_PM   => {'Test::More' => 0,},
      (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'perl') : ()),
      ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (
          META_MERGE => {
            resources => {    ##
              repository => 'https://github.com/sharyanto/perl-Scalar-Util-LooksLikeNumber',
            },
          }
          )
        : ()
      ),
    )
  ),
);
