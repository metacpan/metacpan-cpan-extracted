use inc::Module::Install;
    
name            'PDF-API2-Simple';
all_from        'lib/PDF/API2/Simple.pm';
author          'Red Tree Systems, LLC';
license         'public domain';

no_index directory => 'examples';
    
requires 'Carp' => 0;
requires 'PDF::API2' => 0;
    
auto_install;
WriteAll;
