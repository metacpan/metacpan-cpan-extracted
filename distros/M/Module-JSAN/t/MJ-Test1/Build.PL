use inc::Module::JSAN;


name            'Digest.MD5';
	
version         '0.01';
	
author          'SamuraiJack <root@symbie.org>';
abstract        'JavaScript implementation of MD5 hashing algorithm';
	
license         'perl';
	
requires        'Cool.JS.Lib' => '1.1';
requires        'Another.Cool.JS.Lib' => '1.2';


build_requires  'Building.JS.Lib' => '1.1';
build_requires  'Another.Building.JS.Lib' => '1.2';

create_makefile_pl  'passthrough';

static_dir      'assets';

WriteAll;