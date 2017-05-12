use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new
    ( module_name     => 'SeeAlso::Identifier::PND',
      license         => 'perl',
      requires        => {
		perl => '5.8.2',
		SeeAlso::Identifier      => 0.46,
		SeeAlso::Identifier::GND => 0.54,
                         },
    )->create_build_script;
