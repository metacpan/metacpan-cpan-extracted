
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Modules I find handy from time to time...",
  "dist_author" => [
    "Glenn Fowler <cebjyre\@cpan.org>"
  ],
  "dist_name" => "Task-BeLike-Cebjyre",
  "dist_version" => "1.0.2",
  "license" => "perl",
  "module_name" => "Task::BeLike::Cebjyre",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "App::Ack" => 0,
    "App::Base64" => 0,
    "App::Whatsit" => 0,
    "CGI::Session" => 0,
    "CPAN::Reporter" => 0,
    "Cache::Memcached::Fast" => 0,
    "Dist::Zilla::Plugin::TaskWeaver" => 0,
    "Dist::Zilla::PluginBundle::CEBJYRE" => "v0.4.0",
    "Email::MIME" => 0,
    "Email::Sender" => 0,
    "File::chdir" => 0,
    "JSON" => 0,
    "LWP::Protocol::https" => 0,
    "Log::Log4perl" => 0,
    "MIME::Parser" => 0,
    "Mail::IMAPClient" => "3.21",
    "Module::Find" => 0,
    "MongoDB" => 0,
    "Net::Google::FederatedLogin" => 0,
    "Net::LDAP" => 0,
    "Net::OAuth" => 0,
    "Net::Server::Mail" => 0,
    "Pod::Coverage::TrustPod" => 0,
    "Telephony::CountryDialingCodes" => 0,
    "Template" => 0,
    "Term::ReadLine::Perl" => 0,
    "Test::ConsistentVersion" => 0,
    "Test::Pod" => 0,
    "Test::Pod::Coverage" => 0,
    "Test::Reporter::Transport::Metabase" => 0,
    "Text::Context" => 0,
    "Tie::SecureHash" => 0,
    "Try::Tiny" => 0,
    "Versionify::Dispatch" => 0,
    "XML::Quote" => 0,
    "YAML" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [],
  "test_requires" => {
    "Test::More" => 0
  }
);


unless ( eval { Module::Build->VERSION(0.4004) } ) {
  my $tr = delete $module_build_args{test_requires};
  my $br = $module_build_args{build_requires};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
