use Module::Build;

my $b = Module::Build->new(
  configure_requires    => {'Module::Build'=>0.4224},
  create_readme         =>  0,
  dist_abstract         => 'Create and use an LR(1) parser',
  license               => 'perl',
  module_name           => 'Parser::LR',
  perl                  => '5.26',
  requires              => {
     Carp                      => 0,
    'Data::Dump'               => 0,
    'Data::Table::Text'              => 20191110,
    'Data::DFA'                      => 20191119,
    'Data::NFA'                      => 20191110,
    'Exporter'                 => 0,
    'Math::Cartesian::Product' => '1.009',
    'Test::More'               => 0,
    'Test2::API'               => 0,
   },
 );

$b->create_build_script();

