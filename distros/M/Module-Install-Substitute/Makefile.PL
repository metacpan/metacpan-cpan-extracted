use inc::Module::Install;

name		('Module-Install-Substitute');
license		('perl');
all_from	('lib/Module/Install/Substitute.pm');

requires('File::Spec');
requires('File::Temp');
requires('Cwd');

build_requires('Test::More');
build_requires('Test::File::Contents');

WriteAll();
