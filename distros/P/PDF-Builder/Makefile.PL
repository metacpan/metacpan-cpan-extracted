#! perl

use strict;
use warnings;
use 5.016000;
use ExtUtils::MakeMaker 6.5503;

my $PERL_version = '5.016000';  # can't use in "use" statement above! eval?
                                # could read from .perl-version file otherwise
my $MakeMaker_version = '6.5503';
my $version = '3.012';          # PDFbuild.pl updates from 'version' file

# EVERY RELEASE: check https://www.cpan.org/src/ "First release in each branch
#   of Perl" (NOT "Latest releases in each branch of Perl"!) and subtract 
#   6 years to get date of oldest release, and then go one release before that. 
#   Update the required Perl minimum here and in .perl-version, dist.ini[.old], 
#   and .travis.yml[.HOLD], and commit to repository.
#   Can't fully automate, since "use $PERL_version;" is invalid (eval?).
#   Would be nice to read cpan First Release and figure out min Perl version.

# for future consideration
#my $master  = 'lib/PDF/Builder.pm';
#my $version = MM->parse_version($master);

my %WriteMakefileArgs =
(
 NAME		=> "PDF::Builder",
 DISTNAME       => "PDF-Builder",
 VERSION        => $version,
# ABSTRACT_FROM	 => $master,
 ABSTRACT       => "Facilitates the creation and modification of PDF files",

 AUTHOR		=> 'Phil Perry <phil4597@catskilltech.com>',
 LICENSE	=> "lgpl",
 MIN_PERL_VERSION	=> $PERL_version,
 INSTALLDIRS	=> "site",

 CONFIGURE_REQUIRES => {
    "ExtUtils::MakeMaker" => $MakeMaker_version,
 },

# BUILD_REQUIRES => {
# },

 TEST_REQUIRES	=> {
    "Test::Exception" => 0,
    "Test::Memory::Cycle" => 1.0,
 },

 PREREQ_PM => {
    "Compress::Zlib" => 1.0,
    "Font::TTF" => 1.04,
    # === "optional prerequisites", used if present, but not mandatory
    #     update t/00-all-usable.t to exclude modules using these libraries!
    #"Graphics::TIFF" => 0,
    #"Image::PNG::Libpng" => 0,
    # === found in CORE, so no need to explicitly list
    #"utf8" => 0,
    #"File::Temp" => 0,
    #"File::Basename" => 0,
    #"File::Find" => 0,
    #"Scalar::Util" => 0,
    #"IO::File" => 0,
    #"Unicode::UCD" => 0,
    #"warnings" => 0,
    #"Math::Trig" => 0,
    #"List::Util" => 0,
    #"POSIX" => 0
  },

  META_MERGE        => {

    "meta-spec" => { version => 2 },

    resources => {

      homepage => "https://www.catskilltech.com",

      repository => {
          type => 'git',
          url => 'git://github.com/PhilterPaper/Perl-PDF-Builder.git',
          web => 'https://github.com/PhilterPaper/Perl-PDF-Builder',
      },

      bugtracker => 'https://github.com/PhilterPaper/Perl-PDF-Builder/issues',

    },

  },

);

# restore if make use of Win32.pm again
#if ( $^O eq 'MSWin32' ) {
#	$WriteMakefileArgs{PREREQ_PM}{'Win32::TieRegistry'} = '0';
#}

# enable if required for build on Mac
#if ( $^O eq 'MacOS' ) {
#	$WriteMakefileArgs{PREREQ_PM}{'MacPerl'} = '0';
#}

WriteMakefile(%WriteMakefileArgs);
