
# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v5.019.
use strict;
use warnings;

use 5.010_000;

use ExtUtils::MakeMaker 6.30;

use File::ShareDir::Install;
$File::ShareDir::Install::INCLUDE_DOTFILES = 1;
$File::ShareDir::Install::INCLUDE_DOTDIRS = 1;
install_share dist => "share";


my %WriteMakefileArgs = (
  "ABSTRACT" => "Notification queue for Zabbix, Nagios, et.al.",
  "AUTHOR" => "Dominik Schulz <tex\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "File::ShareDir::Install" => "0.06"
  },
  "DISTNAME" => "Monitoring-Spooler",
  "EXE_FILES" => [
    "bin/mon-spooler-api.cgi",
    "bin/mon-spooler.psgi",
    "bin/mon-spooler.pl",
    "bin/mon-spooler-api.psgi",
    "bin/mon-spooler.cgi"
  ],
  "LICENSE" => "perl",
  "NAME" => "Monitoring::Spooler",
  "PREREQ_PM" => {
    "Config::Yak" => 0,
    "DBD::SQLite" => 0,
    "DBI" => 0,
    "File::ShareDir" => 0,
    "File::Temp" => 0,
    "HTTP::Cookies" => 0,
    "IPC::Open2" => 0,
    "JSON" => 0,
    "LWP::UserAgent" => 0,
    "Log::Tree" => 0,
    "Log::Tree::RequiredLogger" => 0,
    "Module::Pluggable::Object" => 0,
    "Moose" => 0,
    "MooseX::App::Cmd" => 0,
    "MooseX::App::Cmd::Command" => 0,
    "Plack::Builder" => 0,
    "Plack::Loader" => 0,
    "Plack::Request" => 0,
    "Proc::ProcessTable" => 0,
    "SMS::Send" => 0,
    "Template" => 0,
    "Try::Tiny" => 0,
    "URI::Escape" => 0,
    "XMLRPC::Lite" => 0,
    "feature" => 0,
    "lib" => 0,
    "mro" => 0,
    "namespace::autoclean" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.05",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Config::Yak" => 0,
  "DBD::SQLite" => 0,
  "DBI" => 0,
  "File::ShareDir" => 0,
  "File::Temp" => 0,
  "HTTP::Cookies" => 0,
  "IPC::Open2" => 0,
  "JSON" => 0,
  "LWP::UserAgent" => 0,
  "Log::Tree" => 0,
  "Log::Tree::RequiredLogger" => 0,
  "Module::Pluggable::Object" => 0,
  "Moose" => 0,
  "MooseX::App::Cmd" => 0,
  "MooseX::App::Cmd::Command" => 0,
  "Plack::Builder" => 0,
  "Plack::Loader" => 0,
  "Plack::Request" => 0,
  "Proc::ProcessTable" => 0,
  "SMS::Send" => 0,
  "Template" => 0,
  "Try::Tiny" => 0,
  "URI::Escape" => 0,
  "XMLRPC::Lite" => 0,
  "feature" => 0,
  "lib" => 0,
  "mro" => 0,
  "namespace::autoclean" => 0,
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

{
package
MY;
use File::ShareDir::Install qw(postamble);
}


