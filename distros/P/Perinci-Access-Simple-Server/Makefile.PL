# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.023.
use strict;
use warnings;

use 5.010001;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Riap::Simple server implementations",
  "AUTHOR" => "perlancar <perlancar\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Perinci-Access-Simple-Server",
  "EXE_FILES" => [
    "script/peri-pipe",
    "script/peri-sockserve"
  ],
  "LICENSE" => "perl",
  "MIN_PERL_VERSION" => "5.010001",
  "NAME" => "Perinci::Access::Simple::Server",
  "PREREQ_PM" => {
    "Class::XSAccessor" => 0,
    "Data::Clean::FromJSON" => "0.11",
    "Data::Clean::JSON" => "0.38",
    "File::HomeDir" => 0,
    "IO::Handle::Record" => 0,
    "IO::Select" => 0,
    "IO::Socket" => 0,
    "IO::Socket::INET" => 0,
    "IO::Socket::UNIX" => 0,
    "JSON::MaybeXS" => 0,
    "Log::ger" => "0.038",
    "Log::ger::Level::FromEnv" => 0,
    "Log::ger::Output" => "0.005",
    "Log::ger::Output::Screen" => "0.015",
    "Module::List" => 0,
    "Module::Load" => 0,
    "Moo" => 0,
    "Perinci::Access" => 0,
    "Perinci::Access::Perl" => "0.87",
    "Perinci::Access::Schemeless" => "0.87",
    "Perinci::AccessUtil" => "0.06",
    "Perinci::CmdLine::Any" => 0,
    "Perinci::Gen::ForModule" => 0,
    "Perinci::Sub::Property::timeout" => 0,
    "Proc::Daemon::Prefork" => "0.711",
    "Time::HiRes" => 0,
    "URI::Escape" => 0,
    "lib" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "TEST_REQUIRES" => {
    "Capture::Tiny" => 0,
    "Cwd" => 0,
    "File::Spec" => 0,
    "IO::Handle" => 0,
    "IPC::Open3" => 0,
    "Perinci::Access::Simple::Client" => "0.19",
    "Perinci::Examples" => "0.821",
    "Test::More" => "0.96"
  },
  "VERSION" => "0.290",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Capture::Tiny" => 0,
  "Class::XSAccessor" => 0,
  "Cwd" => 0,
  "Data::Clean::FromJSON" => "0.11",
  "Data::Clean::JSON" => "0.38",
  "File::HomeDir" => 0,
  "File::Spec" => 0,
  "IO::Handle" => 0,
  "IO::Handle::Record" => 0,
  "IO::Select" => 0,
  "IO::Socket" => 0,
  "IO::Socket::INET" => 0,
  "IO::Socket::UNIX" => 0,
  "IPC::Open3" => 0,
  "JSON::MaybeXS" => 0,
  "Log::ger" => "0.038",
  "Log::ger::Level::FromEnv" => 0,
  "Log::ger::Output" => "0.005",
  "Log::ger::Output::Screen" => "0.015",
  "Module::List" => 0,
  "Module::Load" => 0,
  "Moo" => 0,
  "Perinci::Access" => 0,
  "Perinci::Access::Perl" => "0.87",
  "Perinci::Access::Schemeless" => "0.87",
  "Perinci::Access::Simple::Client" => "0.19",
  "Perinci::AccessUtil" => "0.06",
  "Perinci::CmdLine::Any" => 0,
  "Perinci::Examples" => "0.821",
  "Perinci::Gen::ForModule" => 0,
  "Perinci::Sub::Property::timeout" => 0,
  "Proc::Daemon::Prefork" => "0.711",
  "Test::More" => "0.96",
  "Time::HiRes" => 0,
  "URI::Escape" => 0,
  "lib" => 0,
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
