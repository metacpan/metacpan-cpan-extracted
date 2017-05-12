use inc::Module::Install;

RTx('RT-Extension-ExtractSubjectTagOnTransaction');

name            ('RT-Extension-ExtractSubjectTagOnTransaction');
abstract        ("On transaction, adds the tags in the transaction subject to the ticket's subject.");
author          ('Robert Spier <robert@bestpractical.com>');
version_from    ('lib/RT/Extension/ExtractSubjectTagOnTransaction.pm');
license         ('GPL version 2');

&WriteAll;
