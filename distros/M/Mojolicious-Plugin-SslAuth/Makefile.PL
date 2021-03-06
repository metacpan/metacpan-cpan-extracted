
# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v5.020.
use strict;
use warnings;



use ExtUtils::MakeMaker ;



my %WriteMakefileArgs = (
  "ABSTRACT" => "SSL client certificate auth helper",
  "AUTHOR" => "Glen Hinkle <tempire\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Mojolicious-Plugin-SslAuth",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Mojolicious::Plugin::SslAuth",
  "PREREQ_PM" => {
    "IO::Socket::SSL" => "1.44",
    "Mojolicious" => "5.0"
  },
  "VERSION" => "0.08",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "IO::Socket::SSL" => "1.44",
  "Mojolicious" => "5.0"
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



