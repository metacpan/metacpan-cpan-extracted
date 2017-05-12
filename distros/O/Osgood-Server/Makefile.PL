use inc::Module::Install;

name 'Osgood-Server';
all_from 'lib/Osgood/Server.pm';

requires 'DBIx::Class::TimeStamp';
requires 'DateTime';
requires 'DateTime::Format::DBI';
requires 'Osgood::Client' => '2.0.0';

requires 'Catalyst::Runtime' => '5.7011';
requires 'Catalyst::Model::DBIC::Schema';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Params::Nested';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::REST';
requires 'JSON::XS';
requires 'YAML'; # This should reflect the config file format you've chosen
                 # See Catalyst::Plugin::ConfigLoader for supported formats
catalyst;

install_script glob('script/*.pl');
WriteAll;
