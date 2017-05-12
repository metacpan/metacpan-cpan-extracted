use inc::Module::Install 0.75;

name          'Perl-SAX';
all_from      'lib/Perl/SAX.pm';
requires      'XML::SAX::Base'   => '1.04';
requires      'XML::SAX::Writer' => '0.44';
requires      'PPI'              => '1.002';
test_requires 'File::Spec'       => '0.80';
test_requires 'Test::More'       => '0.47';
test_requires 'Class::Autouse'   => '1.26';

WriteAll;
