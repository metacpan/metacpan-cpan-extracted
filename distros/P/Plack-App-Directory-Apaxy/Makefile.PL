
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;

use File::ShareDir::Install;
install_share dist => "share";


my %WriteMakefileArgs = (
  "ABSTRACT" => "Serve static files from document root with directory index using Apaxy",
  "AUTHOR" => "Keedi Kim - \x{ae40}\x{b3c4}\x{d615} <keedi\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "File::ShareDir::Install" => "0.03"
  },
  "DISTNAME" => "Plack-App-Directory-Apaxy",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Plack::App::Directory::Apaxy",
  "PREREQ_PM" => {
    "Number::Bytes::Human" => 0,
    "Path::Tiny" => 0,
    "Plack" => 0,
    "Time::Piece" => 0,
    "URI::Escape" => 0,
    "parent" => 0
  },
  "TEST_REQUIRES" => {
    "HTTP::Message" => 0,
    "Test::More" => 0
  },
  "VERSION" => "0.004",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "HTTP::Message" => 0,
  "Number::Bytes::Human" => 0,
  "Path::Tiny" => 0,
  "Plack" => 0,
  "Test::More" => 0,
  "Time::Piece" => 0,
  "URI::Escape" => 0,
  "parent" => 0
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


