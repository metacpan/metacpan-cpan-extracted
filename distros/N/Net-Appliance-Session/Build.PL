use strict;
use warnings;
use Module::Build;

Module::Build->new(
  module_name => 'Net::Appliance::Session',
  author      => 'Oliver Gorwits <oliver@cpan.org>',
  license     => 'perl',
  dynamic_config => 1,
  configure_requires => {
    'Module::Build' => '0.42',
  },
  build_requires => {
    'ExtUtils::CBuilder' => '0',
  },
  requires => {
    "Cwd" => 0,
    "Data::Dumper" => 0,
    "Getopt::Long" => "2.24",
    "IO::Handle" => 0,
    "IO::Prompt::Tiny" => 0,
    "Moo" => 0,
    "Moo::Role" => 0,
    "MooX::Types::MooseLike::Base" => 0,
    "Net::CLI::Interact" => "2.300002",
    "Sub::Quote" => 0,
    "Term::ANSIColor" => 0,
    "Term::ReadPassword" => 0,
    "Text::Glob" => 0,
    "Text::ParseWords" => 0,
    "Try::Tiny" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  test_requires => {
    'Test::More' => '0.88',
  },
  script_files => [
    'bin/nas',
  ],
  share_dir => 'share',
  meta_merge => {
    resources => {
      bugtracker => 'https://github.com/ollyg/Net-Appliance-Session/issues',
      repository => 'https://github.com/ollyg/Net-Appliance-Session',
    },
  },
)->create_build_script;
