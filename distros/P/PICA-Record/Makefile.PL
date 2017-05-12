
use strict;
use warnings;

use 5.010000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Perl module for handling PICA+ records",
  "AUTHOR" => "Jakob Vo\x{df} <voss\@gbv.de>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "PICA-Record",
  "EXE_FILES" => [
    "bin/parsepica",
    "bin/winibw2pica",
    "bin/picaimport"
  ],
  "LICENSE" => "perl",
  "NAME" => "PICA::Record",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Config::Simple" => 0,
    "Cwd" => 0,
    "DBD::SQLite" => 0,
    "DBI" => 0,
    "Data::Dumper" => 0,
    "Encode" => 0,
    "Exporter" => 0,
    "Getopt::Long" => 0,
    "IO::File" => 0,
    "IO::Handle" => 0,
    "IO::Scalar" => 0,
    "LWP::Simple" => 0,
    "POSIX" => 0,
    "PerlIO" => 0,
    "Pod::Usage" => 0,
    "SOAP::Lite" => 0,
    "Scalar::Util" => 0,
    "String::Escape" => 0,
    "URI::Escape" => 0,
    "Unicode::Normalize" => 0,
    "XML::SAX::Base" => 0,
    "XML::SAX::ParserFactory" => "1.01",
    "XML::Writer" => 0,
    "base" => 0,
    "constant" => 0,
    "overload" => 0,
    "sort" => 0,
    "strict" => 0,
    "utf8" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "File::Temp" => 0,
    "SOAP::Transport::HTTP" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.585",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Config::Simple" => 0,
  "Cwd" => 0,
  "DBD::SQLite" => 0,
  "DBI" => 0,
  "Data::Dumper" => 0,
  "Encode" => 0,
  "Exporter" => 0,
  "File::Temp" => 0,
  "Getopt::Long" => 0,
  "IO::File" => 0,
  "IO::Handle" => 0,
  "IO::Scalar" => 0,
  "LWP::Simple" => 0,
  "POSIX" => 0,
  "PerlIO" => 0,
  "Pod::Usage" => 0,
  "SOAP::Lite" => 0,
  "SOAP::Transport::HTTP" => 0,
  "Scalar::Util" => 0,
  "String::Escape" => 0,
  "Test::More" => 0,
  "URI::Escape" => 0,
  "Unicode::Normalize" => 0,
  "XML::SAX::Base" => 0,
  "XML::SAX::ParserFactory" => "1.01",
  "XML::Writer" => 0,
  "base" => 0,
  "constant" => 0,
  "overload" => 0,
  "sort" => 0,
  "strict" => 0,
  "utf8" => 0,
  "warnings" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



