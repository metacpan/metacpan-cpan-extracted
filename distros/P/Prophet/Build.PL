
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
  "dist_abstract" => "A distributed database system",
  "dist_author" => [
    "Jesse Vincent <jesse\@bestpractical.com>",
    "Chia-Liang Kao <clkao\@bestpractical.com>",
    "Christine Spang <christine\@spang.cc>"
  ],
  "dist_name" => "Prophet",
  "dist_version" => "0.751",
  "license" => "mit",
  "module_name" => "Prophet",
  "recommends" => {
    "DBD::SQLite" => 0,
    "DBI" => 0,
    "File::ShareDir" => "1.00",
    "HTTP::Server::Simple" => "0.40",
    "JSON::XS" => "2.23",
    "Module::Refresh" => 0,
    "Net::Bonjour" => 0,
    "Net::Rendezvous::Publish" => 0,
    "Template::Declare" => "0.35",
    "Term::ReadKey" => 0,
    "Term::ReadLine" => 0,
    "Test::Exception" => "0.26",
    "Test::HTTP::Server::Simple" => 0,
    "Test::Pod::Coverage" => 0,
    "Test::WWW::Mechanize" => "1.16",
    "YAML::Syck" => 0
  },
  "recursive_test_files" => 1,
  "requires" => {
    "Any::Moose" => "0.04",
    "Config::GitLike" => "1.02",
    "Digest::SHA" => 0,
    "Exporter::Lite" => 0,
    "HTTP::Date" => 0,
    "JSON" => "2.00",
    "LWP::UserAgent" => 0,
    "MIME::Base64::URLSafe" => 0,
    "Mouse" => "0.89",
    "Params::Validate" => 0,
    "Path::Dispatcher" => "1.02",
    "Path::Dispatcher::Declarative" => "0.03",
    "Proc::InvokeEditor" => 0,
    "Time::Progress" => 0,
    "URI" => 0,
    "UUID::Tiny" => "1.02",
    "XML::Atom::SimpleFeed" => 0
  },
  "script_files" => [
    "bin/prophet"
  ],
  "share_dir" => {
    "dist" => "share"
  },
  "test_requires" => {}
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

if ( $^O eq 'MSWin32' ) {
	$module_build_args{requires}{'Win32'} = '0';
}

my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
