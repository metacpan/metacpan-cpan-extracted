use inc::Module::Install;

name            'PMIR';
all_from        'lib/PMIR.pm';

install_script  'pmir';

WriteAll;
