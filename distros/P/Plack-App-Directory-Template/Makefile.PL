
use strict;
use warnings;

use 5.010000;

use ExtUtils::MakeMaker 6.30;

use File::ShareDir::Install;
install_share dist => "share";


my %WriteMakefileArgs = (
  "ABSTRACT" => "Serve static files from document root with directory index template",
  "AUTHOR" => "Jakob Vo\x{df}",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "File::ShareDir::Install" => "0.03"
  },
  "DISTNAME" => "Plack-App-Directory-Template",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Plack::App::Directory::Template",
  "PREREQ_PM" => {
    "File::ShareDir" => "1.00",
    "Plack::Middleware::TemplateToolkit" => "0.26"
  },
  "TEST_REQUIRES" => {},
  "VERSION" => "0.27",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "File::ShareDir" => "1.00",
  "Plack::Middleware::TemplateToolkit" => "0.26"
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


