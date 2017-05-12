
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Web-related modules RSRCHBOY uses!",
  "AUTHOR" => "Chris Weyl <cweyl\@alumni.drew.edu>",
  "BUILD_REQUIRES" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "Test::More" => "0.88",
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Task-BeLike-RSRCHBOY-Web",
  "EXE_FILES" => [],
  "LICENSE" => "lgpl",
  "NAME" => "Task::BeLike::RSRCHBOY::Web",
  "PREREQ_PM" => {
    "Catalyst::Controller::REST" => 0,
    "Catalyst::Devel" => 0,
    "Catalyst::Model::DBIC::Schema" => "0.59",
    "Catalyst::Plugin::Authentication" => 0,
    "Catalyst::Plugin::Authorization::ACL" => 0,
    "Catalyst::Plugin::Authorization::Roles" => 0,
    "Catalyst::Plugin::AutoCRUD" => "1.112560",
    "Catalyst::Plugin::RedirectAndDetach" => 0,
    "Catalyst::Plugin::Session" => 0,
    "Catalyst::Plugin::Session::State::Cookie" => 0,
    "Catalyst::Plugin::Session::Store::File" => 0,
    "Catalyst::Runtime" => "5.9",
    "Catalyst::TraitFor::Request::BrowserDetect" => 0,
    "Catalyst::TraitFor::Request::REST::ForBrowsers" => 0,
    "Catalyst::View::Haml" => 0,
    "Catalyst::View::TT" => 0,
    "CatalystX::RoleApplicator" => 0,
    "CatalystX::SimpleLogin" => 0,
    "Dancer" => 0,
    "HTML::Builder" => "0.006",
    "HTML::FormHandler" => 0,
    "MooseX::MethodAttributes::Role" => 0,
    "Plack" => 0,
    "Plack::Middleware::Debug" => 0,
    "Plack::Middleware::MethodOverride" => "0.10",
    "Plack::Middleware::SetAccept" => 0,
    "Starlet" => 0,
    "Starman" => 0,
    "Task::BeLike::RSRCHBOY" => "0.002",
    "Task::Catalyst" => 0,
    "Template" => 0,
    "Template::Plugin::JSON::Escape" => 0,
    "Text::Haml" => 0
  },
  "VERSION" => "0.002",
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



