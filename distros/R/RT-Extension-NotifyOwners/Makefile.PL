use inc::Module::Install;

abstract    'Owner notifications for RT';
RTx         'RT-Extension-NotifyOwners';
license     'perl';

all_from    'lib/RT/Extension/NotifyOwners.pm';
WriteAll();
