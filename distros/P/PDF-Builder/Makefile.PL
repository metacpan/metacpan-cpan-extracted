#! perl

use strict;
use warnings;
use 5.026000;
use ExtUtils::MakeMaker 6.66;

my $PERL_version = '5.026000';  # Both here and in "use" statement above,
                                # PDFbuild.pl updates from 'version' file
my $MakeMaker_version = '6.66';
my $version = '3.026';          # PDFbuild.pl updates from 'version' file

# optional libraries... most users will attempt to install full set. they are
# nice to have but not vital for many users. if one fails to install, it might 
# alarm the user, but installation of PDF::Builder can still proceed. the
# user can remove any optional installed library if they don't need it and 
# want to reclaim the space. or, they can run optional_update.pl to select
# optional libraries, before running Makefile.PL.

# for future consideration
#my $master  = 'lib/PDF/Builder.pm';
#my $version = MM->parse_version($master);

my %WriteMakefileArgs =
(
  NAME		 => "PDF::Builder",
  DISTNAME       => "PDF-Builder",
# VERSION_FROM   => $master,
  VERSION        => $version,
# ABSTRACT_FROM	 => $master,
  ABSTRACT       => "Facilitates the creation and modification of PDF files",

  AUTHOR	 => 'Phil Perry',
  LICENSE        => "lgpl_2_1", # some files also MIT license
  MIN_PERL_VERSION	=> $PERL_version,
  INSTALLDIRS	 => "site",

  CONFIGURE_REQUIRES => {
    "ExtUtils::MakeMaker" => $MakeMaker_version,
  },

# BUILD_REQUIRES => {  # mandatory prereqs listed here
# },

  TEST_REQUIRES	=> {
    "Test::Exception" => 0,
    "Test::Memory::Cycle" => 1.0,
  },

  PREREQ_PM => {
    "Compress::Zlib" => 1.0,
    "Font::TTF" => 1.04,
 #  "Readonly" => 0,      use when TIFF changes go in

    # === found in CORE, so no need to explicitly list
    #"Carp" => 0,
    #"constant" => 0,
    #"Encode" => 0,
    #"Exporter" =>0,
    #"FileHandle" => 0,
    #"File::Find" => 0,
    #"File::Basename" => 0,
    #"File::Temp" => 0,
    #"IO::File" => 0,
    #"List::Util" => 0,
    #"Math::Trig" => 0,
    #"POSIX" => 0
    #"Scalar::Util" => 0,
    #"strict" => 0,
    #"Unicode::UCD" => 0,
    #"utf8" => 0,
    #"vars" => 0,
    #"warnings" => 0,
     
    # === NOT core, but not currently used
    #"Win32::TieRegistry" => 0,  # if manually use Win32, need to install
  },

  META_MERGE        => {

    "meta-spec" => { "version" => 2 },

    "resources" => {

      "homepage" => "https://metacpan.org/pod/PDF::Builder",

      "repository" => {
        "type" => 'git',
        "url"  => 'git://github.com/PhilterPaper/Perl-PDF-Builder.git',
        "web"  => 'https://github.com/PhilterPaper/Perl-PDF-Builder',
      },

      "bugtracker" => {
	    "web" => 'https://github.com/PhilterPaper/Perl-PDF-Builder/issues',
      },

    },

    # recommends (optional prereqs) goes here
    # if remove or comment out any, also do so in META.json and META.yml
    #"recommends" => {
    #  # fast TIFF image processing.
    #  "Graphics::TIFF" => 19, 
    #  # advanced/fast PNG image processing.
    #  "Image::PNG::Libpng" => 0.57,
    #  # text shaping for Latin script ligatures and kerning, and for 
    #  # many complex scripts both LTR and RTL directions.
    #  "HarfBuzz::Shaper" => 0.024,
    #  # 'md1' markup
    #  Text::Markdown => 1.000031,
    #  # 'md1' and 'html' markup
    #  HTML::TreeBuilder => 5.07,
    #  # use of buildDoc.pl to build HTML documentation from POD
    #  Pod::Simple::XHTML => 3.45,
    #},     

  }

);

# restore if make use of Win32.pm again
#if ( $^O eq 'MSWin32' ) {
#	$WriteMakefileArgs{PREREQ_PM}{'Win32::TieRegistry'} = '0';
#}

# enable if required for build on Mac
#if ( $^O eq 'MacOS' ) {
#	$WriteMakefileArgs{PREREQ_PM}{'MacPerl'} = '0';
#}

#print <<'END';
#===========================================================================
#The installation process will attempt to install or update several OPTIONAL
#prerequisite packages. If one or more should fail to install, Don't Panic
#-- you will still be able to run PDF::Builder, but may not be able to use 
#some advanced features. See the README.md file for more information.
#===========================================================================
#END

WriteMakefile(%WriteMakefileArgs);
