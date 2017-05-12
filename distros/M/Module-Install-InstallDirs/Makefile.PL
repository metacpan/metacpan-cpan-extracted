# -*- perl -*-

use inc::Module::Install;

name		('Module-Install-InstallDirs');
abstract	('Module::Install extension to detect INSTALLDIR settings');
author		('Graham Barr <gbarr@pobox.com>');
version_from	('lib/Module/Install/InstallDirs.pm');
license		('perl');
requires        ('Module::Install' => 0);

WriteAll();
