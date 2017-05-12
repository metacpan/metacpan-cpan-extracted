use inc::Module::Install;

RTx('RT-Authen-Bitcard');

abstract_from   ('lib/RT/Authen/Bitcard.pm');
license         ('GPL2');
all_from        ('lib/RT/Authen/Bitcard.pm');

requires        ('Authen::Bitcard' => '0.86'); # we need register_url method
requires        ('Encode');

WriteAll();
