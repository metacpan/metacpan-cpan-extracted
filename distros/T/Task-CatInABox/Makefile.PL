use inc::Module::Install 0.85;

all_from      'lib/Task/CatInABox.pm';
requires      'Template'                                       => 0;
requires      'Catalyst::Devel'                                => 0;
requires      'DBIx::Class'                                    => 0;
requires      'DBIx::Class::EncodedColumn'                     => 0;
requires      'DBIx::Class::Timestamp'                         => 0;
requires      'DBIx::Class::InflateColumn::DateTime'           => 0;
requires      'DBIx::Class::Schema::Loader'                    => 0;
requires      'Catalyst::View::TT'                             => 0;
requires      'Catalyst::View::JSON'                           => 0;
requires      'Catalyst::Model::DBIC::Schema'                  => 0;
requires      'Catalyst::Model::File'                          => 0;
requires      'Catalyst::Plugin::Authentication'               => 0;
requires      'Catalyst::Authentication::Store::DBIx::Class'   => 0;
requires      'Catalyst::Authentication::Store::Htpasswd'      => 0;
requires      'Catalyst::Authentication::Credential::Password' => 0;
requires      'Catalyst::Authentication::Credential::HTTP'     => 0;
test_requires 'Test::More'                                     => '0.42';

WriteAll;
