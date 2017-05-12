
use strict;
use warnings;

use 5.009005;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Serve static files with case insensitive paths",
  "AUTHOR" => "Arthur Axel \"fREW\" Schmidt <frioux+cpan\@gmail.com>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Plack-App-File-CaseInsensitive",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Plack::App::File::CaseInsensitive",
  "PREREQ_PM" => {
    "File::Find" => 0,
    "Plack" => "1.0016"
  },
  "TEST_REQUIRES" => {
    "HTTP::Request::Common" => 6,
    "Plack" => "1.0016",
    "Test::More" => "1.001002"
  },
  "VERSION" => "0.001000",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "File::Find" => 0,
  "HTTP::Request::Common" => 6,
  "Plack" => "1.0016",
  "Test::More" => "1.001002"
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



