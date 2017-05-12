use Module::Build;
use strict;

my $build = Module::Build->new(
  create_makefile_pl => 'traditional',
  license     => 'perl',
  module_name => 'Net::Amazon::SimpleQueue',
  requires    => {
    'Class::Accessor::Fast' => '0',
    'LWP::UserAgent'  => '0',
    'IO::Prompt'      => '0',
    'XML::LibXML'     => '0',
    'XML::LibXML::XPathContext' => '0',
    'Module::Build'   => '0',
    'Test::Exception' => '0.15',
    'Test::More'      => '0.01',

  },
);
$build->create_build_script;
