# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.012.
use strict;
use warnings;



use ExtUtils::MakeMaker;

use File::ShareDir::Install;
$File::ShareDir::Install::INCLUDE_DOTFILES = 1;
$File::ShareDir::Install::INCLUDE_DOTDIRS = 1;
install_share dist => "share";


my %WriteMakefileArgs = (
  "ABSTRACT" => "A handy cli interface for MySQL::Util",
  "AUTHOR" => "John Gravatt <gravattj\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::ShareDir::Install" => "0.06"
  },
  "DISTNAME" => "MySQL-Util-CLI",
  "EXE_FILES" => [
    "bin/mysql-util"
  ],
  "LICENSE" => "perl",
  "NAME" => "MySQL::Util::CLI",
  "PREREQ_PM" => {
    "CLI::Driver" => "0.50",
    "Carp" => 0,
    "Data::Printer" => 0,
    "File::Basename" => 0,
    "File::ShareDir" => 0,
    "Getopt::Long" => 0,
    "Kavorka" => 0,
    "Modern::Perl" => 0,
    "Moose" => 0,
    "MySQL::Util" => 0,
    "Text::ASCIITable" => 0,
    "Util::Medley::Roles::Attributes::List" => 0,
    "Util::Medley::Roles::Attributes::Logger" => 0,
    "Util::Medley::Roles::Attributes::String" => 0,
    "constant" => 0,
    "namespace::autoclean" => 0,
    "vars" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Test::More" => 0
  },
  "VERSION" => "0.002",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "CLI::Driver" => "0.50",
  "Carp" => 0,
  "Data::Printer" => 0,
  "File::Basename" => 0,
  "File::ShareDir" => 0,
  "Getopt::Long" => 0,
  "Kavorka" => 0,
  "Modern::Perl" => 0,
  "Moose" => 0,
  "MySQL::Util" => 0,
  "Test::More" => 0,
  "Text::ASCIITable" => 0,
  "Util::Medley::Roles::Attributes::List" => 0,
  "Util::Medley::Roles::Attributes::Logger" => 0,
  "Util::Medley::Roles::Attributes::String" => 0,
  "constant" => 0,
  "namespace::autoclean" => 0,
  "vars" => 0,
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

{
package
MY;
use File::ShareDir::Install qw(postamble);
}
