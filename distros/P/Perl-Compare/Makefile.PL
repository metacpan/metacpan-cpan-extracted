use inc::Module::Install 0.75;

all_from      'lib/Perl/Compare.pm';
requires      'File::chdir'      => '0.06';
requires      'Params::Util'     => '0.10';
requires      'List::MoreUtils'  => '0.08';
requires      'File::Find::Rule' => '0.20';
requires      'Perl::Signature'  => '0.04';
test_requires 'Test::More'       => '0.47';
test_requires 'File::Spec'       => '0.82';

WriteAll;
