use Module::Build;
my $build = new Module::Build
(
  module_name => 'Template::Plugin::XML::LibXML',
  license     => 'perl',
  requires    => {
		  Template                => 2.06,
		  'XML::LibXML'           => 1.52,
		 },
  recommends  => {
                  'Scalar::Util'          => 1.07,
                 },
);
$build->create_build_script;

