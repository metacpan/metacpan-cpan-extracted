#!/usr/bin/env perl

use inc::Module::Install;
name          ('PAR-Dist-InstallPPD');
author        ('Steffen Mueller (smueller@cpan.org)');
abstract      ('Installs PPM packages the PAR way');
version_from  ('lib/PAR/Dist/InstallPPD.pm');
license       ('perl');
install_script('bin/parinstallppd');

requires      'PAR::Dist::FromPPD' => '0.01';
requires      'PAR::Dist' => '0.20';
requires      'File::Path' => '0';
requires      'File::Spec' => '0';
requires      'Getopt::Long' => '0';
requires      'Cwd' => '0';
requires      'File::Temp' => '0';
requires      'perl' => '5.006';

&WriteAll     ( );

