use strict;
use warnings;
use ExtUtils::MakeMaker 6.30;
my %WriteMakefileArgs = (
  "ABSTRACT" => "A plugin to make authorization a bit easier",
  "AUTHOR" => "John Scoles <byterock\@hotmail.com>",
  "BUILD_REQUIRES" => {
    "Module::Build" => "0.38",
    "Mojolicious::Lite" => 0,
    "Test::Mojo" => 0,
    "Test::More" => 0,
    "Test::Exception" => 0.32,
    "Test::Deep"      => 0.113,
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.38"
  },
  "DISTNAME" => "Mojolicious-Plugin-Authorization",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Mojolicious::Plugin::Authorization",
  "PREREQ_PM" => {
    "Mojo::Base" => 0
  },
  "VERSION" => "1.05",
  "test" => {
    "TESTS" => "t/*.t"
  },
  "META_MERGE" => {
    "resources" => {
      "repository" => 'https://github.com/byterock/mojolicious-plugin-authorization',
      "bugtracker" => 'https://github.com/byterock/mojolicious-plugin-authorization/issues',
      "homepage"   => 'https://metacpan.org/module/Mojolicious::Plugin::Authorization',
    },
  },
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
