
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Let you use a filehandle in the response body that has ->read but not ->getline",
  "AUTHOR" => "John Napiorkowski <jjnapiork\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Plack-Middleware-AdaptFilehandleRead",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Plack::Middleware::AdaptFilehandleRead",
  "PREREQ_PM" => {
    "Plack::Middleware" => 0,
    "Plack::Util" => 0,
    "Plack::Util::Accessor" => 0,
    "Scalar::Util" => 0
  },
  "TEST_REQUIRES" => {
    "HTTP::Request::Common" => 0,
    "IO::File" => 0,
    "Plack::Test" => 0,
    "Test::Most" => 0
  },
  "VERSION" => "0.003",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "HTTP::Request::Common" => 0,
  "IO::File" => 0,
  "Plack::Middleware" => 0,
  "Plack::Test" => 0,
  "Plack::Util" => 0,
  "Plack::Util::Accessor" => 0,
  "Scalar::Util" => 0,
  "Test::Most" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



