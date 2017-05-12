use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new
    ( module_name     => 'Phaylon::Class::Cloner',
      license         => 'perl',
      dist_author     => 'Robert Sedlacek <phaylon@dunkelheit.at>',
      requires        => {
        Carp => 0,
        Storable => 0,
      },
    )->create_build_script;
