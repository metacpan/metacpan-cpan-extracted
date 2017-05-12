use inc::Module::Install;

name             'POD-Credentials';
author_from      'lib/POD/Credentials.pm';
license          'Fermitools';
version          '0.02';
perl_version     '5.0061';
all_from 	 'lib/';

requires        'Test::More' => 0; 
requires 	'POSIX' => 0; 
requires 	'version' => 0;
requires        'fields' => 0; 

requires         'Class::Accessor::Fast'=> 0;
requires 	 'Class::Fields'=> 0;
 
 
no_index directory  => 't';

auto_install;
WriteAll;
