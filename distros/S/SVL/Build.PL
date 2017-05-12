use Module::Build;
use strict;

my $build = Module::Build->new(
  create_makefile_pl => 'traditional',
  license            => 'perl',
  module_name        => 'SVL',
  requires           => {
    'App::CLI'                       => '0',
    'Catalyst'                       => '0',
    'Class::Accessor::Chained::Fast' => '0',
    'File::Path'                     => '0',
    'Net::DNS'                       => '0.49.03',
    'Net::OpenDHT'                   => '0.32',
    'Net::Rendezvous'                => '0',
    'Net::Rendezvous'                => '0',
    'Net::Rendezvous::Publish'       => '0',
    'Path::Class'                    => '0',
    'Pod::Usage'                     => '0',
    'Sys::HostIP'                    => '0',
    'SVK'                            => '0',
    'SVK::Simple'                    => '0',
    'SVN::Mirror'                    => '0.65',
    'Test::More'                     => '0',
    'Text::Tags::Parser'             => '0',
  },
);
$build->create_build_script;
