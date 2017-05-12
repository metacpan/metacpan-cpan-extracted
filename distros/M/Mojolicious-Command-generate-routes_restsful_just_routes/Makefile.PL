use strict;
use warnings;
use ExtUtils::MakeMaker 6.30;
my %WriteMakefileArgs = (
  "ABSTRACT" => "Have Hash Make Code",
  "AUTHOR" => "John Scoles <byterock\@hotmail.com>",
  "BUILD_REQUIRES" => {
    "Module::Build" => "0.38",
    "Mojolicious::Lite" => 0,
    "Test::Mojo" => 0,
    "Test::More" => 0,
    "Test::Exception" => 0.32,
    "Test::Deep"      => 0.113,
    "strict" => 0,
    "warnings" => 0,
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.38"
  },
  "DISTNAME" => "Mojolicious-Command-generate-routes_restsful_just_routes",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Mojolicious::Command::generate::routes_restsful_just_routes",
  "PREREQ_PM" => {
    "Mojo::Base" => 0,
    "Lingua::EN::Inflect"=>1,    
  },
  "VERSION" => "0.01",
  "test" => {
    "TESTS" => "t/*.t"
  },
  "META_MERGE" => {
    "resources" => {
      "repository" => 'https://github.com/byterock/Mojolicious_Command_generate_routes_restsful',
      "bugtracker" => 'https://github.com/byterock/Mojolicious_Command_generate_routes_restsful_just_routes/issues',
      "homepage"   => 'https://metacpan.org/module/Mojolicious::Command::generate::routes_restsful_just_routes',
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
