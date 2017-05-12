use inc::Module::Install;

name			'Sub-PatMat';
license			'bsd';
all_from		'lib/Sub/PatMat.pm';

requires		perl => '5.8.2';
requires		'B::Utils';
build_requires	'Test::More' => '0.42';

no_index		directory => 'devel';

WriteAll;
