use strict;
use warnings;
use Module::Build;

Module::Build->new(
  module_name => 'Net::CLI::Interact',
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
    'Class::Load' => '0',
    'Class::Mix' => '0',
    'File::Basename' => '0',
    'File::ShareDir' => '0',
    'FileHandle' => '0',
    'IO::Pty' => '0',
    'IPC::Run' => '0',
    'List::Util' => '0',
    'Log::Dispatch::Config' => '0',
    'Log::Dispatch::Configurator::Any' => '0',
    'Config::Any' => '0.27',
    'Moo' => '0',
    'Moo::Role' => '0',
    'MooX::Types::MooseLike::Base' => '0',
    'Net::Telnet' => '0',
    'POSIX' => '0',
    'Path::Class' => '0',
    'Sub::Quote' => '0',
    'Time::HiRes' => '0',
  },
  test_requires => {
    'Test::More' => '0.88',
    'Test::File::ShareDir' => '1.001002',
  },
  share_dir => 'share',
  meta_merge => {
    resources => {
      bugtracker => 'https://github.com/ollyg/Net-CLI-Interact/issues',
      repository => 'https://github.com/ollyg/Net-CLI-Interact',
    },
  },
)->create_build_script;
