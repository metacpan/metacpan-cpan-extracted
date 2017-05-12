use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new
    ( module_name     => 'SeeAlso::Identifier::ISSN',
      license         => 'perl',
   configure_requires => {
		Module::Build => 0.35,
                         },
      requires        => {
		perl	=> '5.8.2',
		Business::ISSN      => 0,
		SeeAlso::Identifier => 0.46,
                         },
    )->create_build_script;
