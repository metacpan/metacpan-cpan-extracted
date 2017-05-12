use inc::Module::Install;

name ('RT-Extension-Converter');
abstract('Convert RT1 installations to RT3');
all_from('lib/RT/Extension/Converter.pm');
requires('Test::More');
requires('Class::Accessor::Fast');
requires('RT' => '3.6');
requires('Date::Format');
requires('MIME::Parser');

&WriteAll;
