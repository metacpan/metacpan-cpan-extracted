use Module::Build;
use strict;

my $build = Module::Build->new(
  create_makefile_pl => 'traditional',
  license            => 'perl',
  module_name        => 'TV::Anytime',
  requires           => {
    'Test::More'                     => '0',
    'DateTime::Format::Duration'     => '0',
    'DateTime::Format::ISO8601'      => '0',
    'DateTime'                       => '0',
    'File::Find::Rule'               => '0',
    'List::Util'                     => '0',
    'Path::Class'                    => '0',
    'XML::LibXML'                    => '0',
    'XML::LibXML::XPathContext'      => '0',
    'Class::Accessor::Chained::Fast' => '0',
  },
);
$build->create_build_script;
