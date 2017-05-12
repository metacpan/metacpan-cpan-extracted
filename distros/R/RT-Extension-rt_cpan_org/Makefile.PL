use inc::Module::Install;

RTx('RT-Extension-rt_cpan_org');
license         ('GPL version 2');
# RTx auto-gen abstract when we want it from file
abstract_from   ('lib/RT/Extension/rt_cpan_org.pm');
all_from        ('lib/RT/Extension/rt_cpan_org.pm');

requires        'Hook::LexWrap';

WriteAll();
