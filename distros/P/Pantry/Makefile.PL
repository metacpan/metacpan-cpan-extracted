
use strict;
use warnings;

use 5.014000;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Configuration management tool for chef-solo",
  "AUTHOR" => "David Golden <dagolden\@cpan.org>",
  "BUILD_REQUIRES" => {
    "App::Cmd::Tester" => 0,
    "App::Cmd::Tester::CaptureExternal" => 0,
    "File::Find" => 0,
    "File::pushd" => "1.00",
    "Test::Deep" => "0.110",
    "Test::More" => "0.96",
    "parent" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Pantry",
  "EXE_FILES" => [
    "bin/pantry"
  ],
  "LICENSE" => "apache",
  "NAME" => "Pantry",
  "PREREQ_PM" => {
    "App::Cmd::Setup" => "0.317",
    "Carp" => 0,
    "Exporter" => 0,
    "File::Basename" => 0,
    "File::Path" => 0,
    "File::Slurp" => 0,
    "File::Temp" => "0.22",
    "Hash::Merge" => 0,
    "IO::Prompt::Tiny" => 0,
    "IPC::Cmd" => 0,
    "JSON" => 2,
    "List::AllUtils" => 0,
    "Moose" => 2,
    "Moose::Role" => 0,
    "Moose::Util" => 0,
    "MooseX::Role::Parameterized" => 0,
    "MooseX::Types::Path::Class::MoreCoercions" => "0.002",
    "Net::OpenSSH" => 0,
    "Path::Class" => 0,
    "Path::Class::Rule" => 0,
    "Storable" => 0,
    "autodie" => 0,
    "namespace::autoclean" => 0,
    "namespace::clean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.012",
  "test" => {
    "TESTS" => "t/*.t t/app/*.t t/app/init/*.t t/model/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



