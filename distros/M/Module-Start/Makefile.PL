use 5.006;
use inc::Module::Install;

name            'Module-Start';
all_from        'lib/Module/Start.pm';

requires        'Term::ReadLine';
requires        'Template';
requires        'IO::All';
requires        'XXX';
requires        'Class::Field' => '0.10';

use_test_base;

install_script  'module-start';

WriteAll;
