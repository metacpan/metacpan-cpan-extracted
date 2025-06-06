#
# This file is part of Pod-Markdown
#
# This software is copyright (c) 2011 by Randy Stauner.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.024.
use strict;
use warnings;

use 5.008;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Convert POD to Markdown",
  "AUTHOR" => "Marcel Gruenauer <marcel\@cpan.org>, Victor Moral <victor\@taquiones.net>, Ryan C. Thompson <rct at thompsonclan d0t org>, Aristotle Pagaltzis <pagaltzis\@gmx.de>, Randy Stauner <rwstauner\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Pod-Markdown",
  "EXE_FILES" => [
    "bin/pod2markdown"
  ],
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.008",
  "NAME" => "Pod::Markdown",
  "PREREQ_PM" => {
    "Encode" => 0,
    "Getopt::Long" => 0,
    "Pod::Simple" => "3.27",
    "Pod::Simple::Methody" => 0,
    "Pod::Usage" => 0,
    "URI::Escape" => 0,
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Exporter" => 0,
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "File::Spec::Functions" => 0,
    "File::Temp" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Symbol" => 0,
    "Test::Differences" => 0,
    "Test::More" => "0.88",
    "lib" => 0,
    "utf8" => 0
  },
  "VERSION" => "3.400",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Encode" => 0,
  "Exporter" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "File::Spec::Functions" => 0,
  "File::Temp" => 0,
  "Getopt::Long" => 0,
  "IO::Handle" => 0,
  "IPC::Open3" => 0,
  "Pod::Simple" => "3.27",
  "Pod::Simple::Methody" => 0,
  "Pod::Usage" => 0,
  "Symbol" => 0,
  "Test::Differences" => 0,
  "Test::More" => "0.88",
  "URI::Escape" => 0,
  "lib" => 0,
  "parent" => 0,
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
