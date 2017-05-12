use inc::Module::Install;

all_from      'lib/Perl/Metrics.pm';
requires      'File::Spec'             => '0.80';
requires      'List::Util'             => '1.15';
requires      'Class::Inspector'       => '1.12';
requires      'Params::Util'           => '0.10';
requires      'File::Find::Rule'       => '0.20';
requires      'File::Find::Rule::Perl' => '1.04';
requires      'Module::Pluggable'      => '2.2';
requires      'DBI'                    => '1.143';
requires      'DBD::SQLite'            => '1.08';
requires      'Class::DBI'             => '3.0.9';
requires      'PPI'                    => '1.201';
test_requires 'Test::More'             => '0.47';

WriteAll;
