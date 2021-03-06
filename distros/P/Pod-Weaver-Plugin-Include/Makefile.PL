# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.012.
use strict;
use warnings;

use 5.014000;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Support for including segments of Pod from other files",
  "AUTHOR" => "Vadim Belman <vrurg\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Pod-Weaver-Plugin-Include",
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.014000",
  "NAME" => "Pod::Weaver::Plugin::Include",
  "PREREQ_PM" => {
    "File::Find::Rule" => 0,
    "Log::Dispatchouli" => 0,
    "Moose" => 0,
    "Pod::Elemental" => "0.103004",
    "Pod::Elemental::Transformer" => 0,
    "Pod::Elemental::Transformer::Pod5" => 0,
    "Pod::Find" => 0,
    "Pod::Weaver" => "4.000",
    "Pod::Weaver::Role::Dialect" => 0,
    "Pod::Weaver::Role::Preparer" => 0,
    "namespace::autoclean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Carp" => 0,
    "Data::Dumper" => 0,
    "Exporter" => 0,
    "File::Spec" => 0,
    "File::Spec::Unix" => 0,
    "PPI" => 0,
    "Pod::Coverage::TrustPod" => 0,
    "Pod::Elemental" => "0.103004",
    "Pod::Elemental::PerlMunger" => 0,
    "Pod::Weaver" => "4.000",
    "Software::License::BSD" => 0,
    "Test::Differences" => "0.500",
    "Test::MockObject" => "1.09",
    "Test::More" => "0.96",
    "Test::Pod" => 0,
    "Test::Pod::Coverage" => 0,
    "lib" => 0
  },
  "VERSION" => "v0.1.9",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Data::Dumper" => 0,
  "Exporter" => 0,
  "File::Find::Rule" => 0,
  "File::Spec" => 0,
  "File::Spec::Unix" => 0,
  "Log::Dispatchouli" => 0,
  "Moose" => 0,
  "PPI" => 0,
  "Pod::Coverage::TrustPod" => 0,
  "Pod::Elemental" => "0.103004",
  "Pod::Elemental::PerlMunger" => 0,
  "Pod::Elemental::Transformer" => 0,
  "Pod::Elemental::Transformer::Pod5" => 0,
  "Pod::Find" => 0,
  "Pod::Weaver" => "4.000",
  "Pod::Weaver::Role::Dialect" => 0,
  "Pod::Weaver::Role::Preparer" => 0,
  "Software::License::BSD" => 0,
  "Test::Differences" => "0.500",
  "Test::MockObject" => "1.09",
  "Test::More" => "0.96",
  "Test::Pod" => 0,
  "Test::Pod::Coverage" => 0,
  "lib" => 0,
  "namespace::autoclean" => 0,
  "strict" => 0,
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
