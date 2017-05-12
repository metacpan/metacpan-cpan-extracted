use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new
    ( module_name     => 'POE::Component::Basement',
      dist_author     => 'Robert Sedlacek <phaylon@dunkelheit.at>',
      dist_abstract   => 'Basic Class::Std and POE component functionality',
      license         => 'perl',
      create_readme   => 1,
      requires        => {
          Scalar::Util              => 0,
          UNIVERSAL::require        => 0,
          NEXT                      => '0.60',
          POE                       => '0.3',
          Class::Std                => '0.0.4',
          Sub::Installer            => '0.0.2',
          Class::Data::Inheritable  => 0,
      },
    )->create_build_script;
