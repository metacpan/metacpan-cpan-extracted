use inc::Module::Install;

name          'Module-Inspector';
all_from      'lib/Module/Inspector.pm';
requires      'Carp'                   => 0;
requires      'version'                => '0.74';
requires      'File::Spec'             => '0.80';
requires      'Params::Util'           => '0.17';
requires      'YAML::Tiny'             => '1.00';
requires      'File::Find::Rule'       => 0;
requires      'File::Find::Rule::VCS'  => '1.02';
requires      'File::Find::Rule::Perl' => 0;
requires      'PPI'                    => '1.118';
requires      'Module::Extract'        => '0.01';
requires      'Module::Manifest'       => '0.01';
requires      'Module::Math::Depends'  => '0.02';
test_requires 'Test::More'             => '0.47';

WriteAll;
