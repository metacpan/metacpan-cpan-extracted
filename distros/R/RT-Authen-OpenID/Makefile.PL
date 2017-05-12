use inc::Module::Install;

RTx('RT-Authen-OpenID');

name            ('RT-Authen-OpenID');
abstract        ('Allows RT to do authentication via a service which supports the OpenID API');
author          ('Artur Bergman <abergman@sixapart.com>');
version_from    ('lib/RT/Authen/OpenID.pm');
license         ('GPL version 2');

requires        ('Net::OpenID::Consumer');

&WriteAll;
