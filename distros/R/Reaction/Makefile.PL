use inc::Module::Install 0.76;

use 5.008001;

name 'Reaction';
license 'perl';
perl_version '5.008001';
author 'Matt S Trout <mst@shadowcat.co.uk>';
all_from 'lib/Reaction.pm';

requires 'Catalyst' => '5.80002';
requires 'Catalyst::Component::ACCEPT_CONTEXT' => '0.05';
requires 'Catalyst::Component::InstancePerContext' => '0.001001';
requires 'Catalyst::Model::DBIC::Schema' => '0.23';
requires 'Catalyst::Plugin::ConfigLoader' => '0.23';
requires 'Catalyst::Plugin::I18N' => '0.09';
requires 'Catalyst::Plugin::Static::Simple' => '0.21';
requires 'Catalyst::View::TT' => '0.29';
requires 'Config::General' => '2.42';
requires 'Crypt::Eksblowfish::Bcrypt' => '0.005';
requires 'Class::MOP' => '0.81';
requires 'DBIx::Class' => '0.08100';
requires 'DBIx::Class::IntrospectableM2M' => '0.001001';
requires 'DateTime' => '0.47';
requires 'DateTime::Event::Recurrence' => '0.16';
requires 'DateTime::Span';
requires 'Devel::Declare' => '0.005000';
requires 'Email::Valid' => '0.181';
requires 'File::ShareDir' => '1.00';
requires 'File::Spec' => '3.29';
requires 'Moose' => '0.74';
requires 'MooseX::Types' => '0.10';
requires 'MooseX::Types::URI' => '0.02';
requires 'MooseX::Types::Common' => '0.001000';
requires 'MooseX::Types::DateTime' => '0.03';
requires 'MooseX::MethodAttributes' => '0.18';
requires 'Path::Class::Dir';
requires 'Path::Class::File';
requires 'Scalar::Util' => '1.19';
requires 'Sub::Exporter' => '0.982';
requires 'Sub::Name' => '0.04';
requires 'Template' => '2.20';
requires 'Time::ParseDate' => '2006.0814';
requires 'URI' => '1.37';
requires 'aliased' => '0.22';
requires 'namespace::clean' => '0.11';
requires 'metaclass' => '0.81';
requires 'Method::Signatures::Simple' => '0.03';
requires 'signatures' => '0.05';
requires 'MooseX::Role::Parameterized' => '0.24';
requires 'JSON';

test_requires 'Test::Class' => '0.31';
test_requires 'Test::WWW::Mechanize::Catalyst' => '0.51';
test_requires 'Test::Memory::Cycle' => '1.04';
test_requires 'SQL::Translator' => '0.11002';

install_share;

install_script glob('script/*.pl');

auto_install;
WriteAll;
