
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'All you need to start with Catalyst',
  'AUTHOR' => 'Sebastian Riedel <sri@oook.de>, Brian Cassidy <bricas@cpan.org>, Andy Grundman <andy@hybridized.org>, Marcus Ramberg <mramberg@cpan.org>, Tomas Doran <bobtfish@bobtfish.net>, Rafael Kitover <rkitover@io.com>, Florian Ragwitz <rafl@debian.org>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30'
  },
  'DISTNAME' => 'Task-Catalyst',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Task::Catalyst',
  'PREREQ_PM' => {
    'Catalyst' => '5.80',
    'Catalyst::Action::REST' => '0',
    'Catalyst::ActionRole::ACL' => '0',
    'Catalyst::Authentication::Credential::HTTP' => '0',
    'Catalyst::Authentication::Store::DBIx::Class' => '0',
    'Catalyst::Component::InstancePerContext' => '0',
    'Catalyst::Controller::ActionRole' => '0',
    'Catalyst::Devel' => '1.26',
    'Catalyst::Manual' => '5.80',
    'Catalyst::Model::Adaptor' => '0',
    'Catalyst::Model::DBIC::Schema' => '0',
    'Catalyst::Plugin::Authentication' => '0',
    'Catalyst::Plugin::ConfigLoader' => '0',
    'Catalyst::Plugin::I18N' => '0',
    'Catalyst::Plugin::Session' => '0',
    'Catalyst::Plugin::Session::State::Cookie' => '0',
    'Catalyst::Plugin::Session::Store::DBIC' => '0',
    'Catalyst::Plugin::Session::Store::File' => '0',
    'Catalyst::Plugin::StackTrace' => '0',
    'Catalyst::Plugin::Static::Simple' => '0',
    'Catalyst::Plugin::Unicode::Encoding' => '0',
    'Catalyst::View::Email' => '0',
    'Catalyst::View::TT' => '0',
    'CatalystX::Component::Traits' => '0',
    'CatalystX::LeakChecker' => '0',
    'CatalystX::Profile' => '0',
    'CatalystX::REPL' => '0',
    'CatalystX::SimpleLogin' => '0',
    'FCGI' => '0',
    'FCGI::ProcManager' => '0',
    'Starman' => '0',
    'Test::WWW::Mechanize::Catalyst' => '0',
    'local::lib' => '0'
  },
  'VERSION' => '4.02',
  'test' => {
    'TESTS' => 't/*.t'
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



