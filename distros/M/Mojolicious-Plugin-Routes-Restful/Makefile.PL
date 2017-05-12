use strict;
use warnings;
use ExtUtils::MakeMaker 6.30;
my %WriteMakefileArgs = (
  "ABSTRACT" => "Have a Hash make some Mojo routes",
  "AUTHOR" => "John Scoles <byterock\@hotmail.com>",
  "BUILD_REQUIRES" => {
    "Module::Build" => "0.38",
    "Test::Mojo" => 0,
    "Test::More" => 0,
    "strict" => 0,
    "warnings" => 0,
    "Lingua::EN::Inflect"=>1,
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.38"
  },
  "DISTNAME" => "Mojolicious-Plugin-Routes-Restful",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Mojolicious::Plugin::Routes::Restful",
  "PREREQ_PM" => {
    "Mojo::Base" => 0
  },
  "VERSION" => "0.03",
  "test" => {
    "TESTS" => "t/*.t"
  },
  "META_MERGE" => {
    "resources" => {
      "repository" => 'https://github.com/byterock/mojolicious-plugin-routes-restful',
      "bugtracker" => 'https://github.com/byterock/mojolicious-plugin-routes-restful/issues',
      "homepage"   => 'https://metacpan.org/module/Mojolicious::Plugin::Routes::Restful',
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
