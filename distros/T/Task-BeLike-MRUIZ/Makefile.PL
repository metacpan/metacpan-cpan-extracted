
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Perl modules MRUIZ likes to use",
  "AUTHOR" => "Miquel Ruiz <mruiz\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Task-BeLike-MRUIZ",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Task::BeLike::MRUIZ",
  "PREREQ_PM" => {
    "Carp::Always" => 0,
    "DBI" => 0,
    "Data::Dump" => 0,
    "DateTime" => 0,
    "DateTime::Format::Strptime" => 0,
    "Dist::Zilla" => 0,
    "Dist::Zilla::Plugin::CopyReadmeFromBuild" => 0,
    "Dist::Zilla::Plugin::NextRelease" => 0,
    "Dist::Zilla::Plugin::PkgVersion" => 0,
    "Dist::Zilla::Plugin::ReadmeFromPod" => 0,
    "Dist::Zilla::PluginBundle::Git" => 0,
    "Dist::Zilla::PluginBundle::GitHub" => 0,
    "File::Slurp" => 0,
    "Getopt::Long" => 0,
    "HTTP::Tiny" => "0.014",
    "JSON" => 0,
    "JSON::XS" => 0,
    "Moo" => 0,
    "Moose" => 0,
    "Mozilla::CA" => 0,
    "Net::SSLeay" => 0,
    "Path::Class" => 0,
    "Test::Exception" => 0,
    "Test::More" => 0,
    "Try::Tiny" => 0,
    "URI" => 0,
    "YAML" => 0
  },
  "TEST_REQUIRES" => {},
  "VERSION" => "0.01",
  "test" => {
    "TESTS" => ""
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
  my $br = $WriteMakefileArgs{BUILD_REQUIRES};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

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



