use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new
    ( module_name     => 'Net::Intermapper',
      license => 'gpl',
      requires => { 'Moose' => '>= 2.0',
                    'IO::Socket::SSL' => ' >= 2.0',
                    'LWP::UserAgent' => '6.15',
                    'XML::Simple' => '>= 2.0',
                    'MIME::Base64' => '3.15',
                    'URI' => '1.71',
                    'Module::Build' => '0.42',
                    'Text::CSV_XS' => '1.20'
      }
    )->create_build_script;
