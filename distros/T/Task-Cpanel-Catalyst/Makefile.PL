
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Provides a set of Catalyst modules",
  "AUTHOR" => "cPanel <cpanel\@cpan.org>",
  "BUILD_REQUIRES" => {
    "FindBin" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Task-Cpanel-Catalyst",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Task::Cpanel::Catalyst",
  "PREREQ_PM" => {
    "Cache::FastMmap" => 0,
    "Catalyst" => 0,
    "Catalyst::ActionRole::ACL" => 0,
    "Catalyst::Authentication::Store::DBIx::Class" => 0,
    "Catalyst::Controller::ActionRole" => 0,
    "Catalyst::Controller::REST" => 0,
    "Catalyst::Devel" => 0,
    "Catalyst::Log::Log4perl" => 0,
    "Catalyst::Model::DBIC::Schema" => 0,
    "Catalyst::Plugin::Authorization::Roles" => 0,
    "Catalyst::Plugin::AutoCRUD" => 0,
    "Catalyst::Plugin::Browser" => 0,
    "Catalyst::Plugin::Cache" => 0,
    "Catalyst::Plugin::Cache::FastMmap" => 0,
    "Catalyst::Plugin::ConfigLoader" => 0,
    "Catalyst::Plugin::HashedCookies" => 0,
    "Catalyst::Plugin::Redirect" => 0,
    "Catalyst::Plugin::Session::State::Cookie" => 0,
    "Catalyst::Plugin::Session::Store::FastMmap" => 0,
    "Catalyst::Plugin::StackTrace" => 0,
    "Catalyst::Plugin::Static::Simple" => 0,
    "Catalyst::Plugin::UploadProgress" => 0,
    "Catalyst::View::TT" => 0,
    "DBIx::Class" => 0,
    "DateTime::Format::Pg" => 0,
    "FCGI" => 0,
    "Log::Dispatch" => 0,
    "Net::OpenSSH" => 0,
    "Net::SFTP::Foreign" => 0,
    "Net::Telnet" => 0,
    "forks" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "11.36.001",
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



