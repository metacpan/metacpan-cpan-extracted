
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Modules that DBR likes to use.",
  "AUTHOR" => "Daniel B <dbrx\@dbrx.crux.uberspace.de>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Task-BeLike-DBR",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Task::BeLike::DBR",
  "PREREQ_PM" => {
    "App::Ack" => 0,
    "App::TimeTracker" => 0,
    "App::Uni" => 0,
    "Bread::Board" => 0,
    "Bread::Board::Declare" => 0,
    "DBIx::Class" => 0,
    "Data::Printer" => 0,
    "Data::Visitor" => 0,
    "DateTime" => 0,
    "Devel::NYTProf" => 0,
    "Dist::Zilla" => 0,
    "Dist::Zilla::PluginBundle::DBR" => 0,
    "JSON" => 0,
    "MooseX::Types::Path::Class" => 0,
    "MooseX::Types::URI" => 0,
    "Path::Class" => 0,
    "Task::Moose" => 0,
    "WWW::Mechanize" => 0,
    "Web::Scraper" => 0,
    "YAML" => 0,
    "utf8::all" => 0
  },
  "VERSION" => "0.023",
  "test" => {
    "TESTS" => "t/*.t"
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



