use inc::Module::Install;

perl_version '5.008';
all_from 'lib/MojoX/Session/Store/File.pm';

requires 'Mojo'           => 0.999914;
requires 'MojoX::Session' => 0.15;
requires 'File::Spec';
requires 'Storable';
requires 'FreezeThaw';

test_requires 'Test::More';

WriteAll;
