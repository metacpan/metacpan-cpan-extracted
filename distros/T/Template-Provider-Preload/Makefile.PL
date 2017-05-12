use inc::Module::Install 0.77;

all_from      'lib/Template/Provider/Preload.pm';
requires      'File::Spec'       => '0.80';
requires      'File::Find::Rule' => '0.30';
requires      'Class::Adapter'   => '1.05';
requires      'Params::Util'     => '0.30';
requires      'Template'         => '2.20';
test_requires 'Test::More'       => '0.47';
test_requires 'Test::SubCalls'   => '1.07';

WriteAll;
