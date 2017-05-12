use inc::Module::Install;

RTx('RT-Authen-Federation');

name            ('RT-Authen-Federation');
abstract        ('Allows RT to federation the authentication of RT via Shibboleth, PAPI system');
author          ('Carlos Fuentes <carlos.fuentes@rediris.es>');
version_from    ('lib/RT/Authen/Federation.pm');
license         ('GPL version 2');

requires        ('APR::Table');
requires        ('version');

&WriteAll;
