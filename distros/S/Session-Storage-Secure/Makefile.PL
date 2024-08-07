# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.017.
use strict;
use warnings;

use 5.008001;

use ExtUtils::MakeMaker 6.17;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Encrypted, expiring, compressed, serialized session data with integrity",
  "AUTHOR" => "David Golden <dagolden\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.17"
  },
  "DISTNAME" => "Session-Storage-Secure",
  "LICENSE" => "apache",
  "MIN_PERL_VERSION" => "5.008001",
  "NAME" => "Session::Storage::Secure",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Crypt::CBC" => "3.01",
    "Crypt::Rijndael" => 0,
    "Crypt::URandom" => 0,
    "Digest::SHA" => 0,
    "MIME::Base64" => "3.12",
    "Math::Random::ISAAC::XS" => 0,
    "Moo" => 0,
    "MooX::Types::MooseLike::Base" => "0.16",
    "Sereal::Decoder" => "4.005",
    "Sereal::Encoder" => "4.005",
    "String::Compare::ConstantTime" => 0,
    "namespace::clean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "Test::Deep" => 0,
    "Test::Fatal" => 0,
    "Test::More" => "0.96",
    "Test::Tolerant" => 0
  },
  "VERSION" => "1.000",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Carp" => 0,
  "Crypt::CBC" => "3.01",
  "Crypt::Rijndael" => 0,
  "Crypt::URandom" => 0,
  "Digest::SHA" => 0,
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "MIME::Base64" => "3.12",
  "Math::Random::ISAAC::XS" => 0,
  "Moo" => 0,
  "MooX::Types::MooseLike::Base" => "0.16",
  "Sereal::Decoder" => "4.005",
  "Sereal::Encoder" => "4.005",
  "String::Compare::ConstantTime" => 0,
  "Test::Deep" => 0,
  "Test::Fatal" => 0,
  "Test::More" => "0.96",
  "Test::Tolerant" => 0,
  "namespace::clean" => 0,
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
