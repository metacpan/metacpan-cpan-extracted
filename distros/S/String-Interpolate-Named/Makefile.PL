#! perl

use strict;
use warnings;

# Ease the life of the CPAN testers.
exit 0 if $ENV{AUTOMATED_TESTING} && $] < 5.010001;

use ExtUtils::MakeMaker;

WriteMakefile(
 NAME                => 'String::Interpolate::Named',
 AUTHOR              => 'Johan Vromans <jv@cpan.org>',
 VERSION_FROM        => 'lib/String/Interpolate/Named.pm',
 ABSTRACT_FROM       => 'lib/String/Interpolate/Named.pm',
 LICENSE             => 'perl_5',
 PL_FILES            => {},
 MIN_PERL_VERSION    => "5.010001",
 PREREQ_PM           => {
			},
 TEST_REQUIRES       => {
			 'Test::More'  => 0,
			},
 META_MERGE => {
   resources => {
     repository => {
       type => 'git',
       web  => 'https://github.com/sciurius/perl-String-Interpolate-Named',
       url  => 'https://github.com/sciurius/perl-String-Interpolate-Named.git',
     },
     bugtracker => {
       web => "https://github.com/sciurius/perl-String-Interpolate-Named/issues",
     },
   },
   'meta-spec' => {
     version => '2',
     url     => 'https://metacpan.org/pod/CPAN::Meta::Spec',
   },
 },
);
