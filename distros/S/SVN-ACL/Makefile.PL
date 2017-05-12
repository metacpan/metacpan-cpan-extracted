#!/usr/local/bin/perl

use inc::Module::Install;

name        ('SVN-ACL');
author      ('Hsin-Chan Chien <hcchien@hcchien.org>');
abstract    ('a simple frondend for manager the svnserve.conf, authz and passwd for subversion');
license     ('perl');
version_from('lib/SVN/ACL.pm');
requires    ('YAML');
WriteAll    ( sign => 1 );

