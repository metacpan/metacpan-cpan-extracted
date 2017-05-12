use inc::Module::Install;

RTx('RT-Extension-AttributeWalker');
license('perl');
abstract_from('lib/RT/Extension/AttributeWalker.pm');
all_from('lib/RT/Extension/AttributeWalker.pm');
requires('Test::More');
requires('RT');

&WriteAll;
