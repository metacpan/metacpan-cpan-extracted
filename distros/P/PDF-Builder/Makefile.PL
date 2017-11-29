#! perl

use strict;
use warnings;
use 5.008006;
use ExtUtils::MakeMaker 6.5503;

# for future consideration
#my $master  = 'lib/PDF/Builder.pm';
#my $version = MM->parse_version($master);

my %WriteMakefileArgs =
(
 NAME		=> "PDF::Builder",
 DISTNAME       => "PDF-Builder",
# VERSION	 => $version,
 VERSION        => "3.009",
# ABSTRACT_FROM	 => $master,
 ABSTRACT       => "Facilitates the creation and modification of PDF files",

 AUTHOR		=> 'Phil Perry <phil4597@catskilltech.com>',
 LICENSE	=> "lgpl",
 MIN_PERL_VERSION	=> 5.008006,
 INSTALLDIRS	=> "site",

 CONFIGURE_REQUIRES => {
    "ExtUtils::MakeMaker" => 6.5503,
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
    #"Graphics::TIFF" => 0,    use if possible, but don't make mandatory
    # found in CORE, so no need to explicitly list
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

# META_MERGE => {
#    resources => {
#	homepage => "https://www.catskilltech.com",
#    },
# },

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
