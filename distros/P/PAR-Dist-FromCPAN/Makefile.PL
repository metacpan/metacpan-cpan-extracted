#!/usr/bin/env perl

use inc::Module::Install;
name          ('PAR-Dist-FromCPAN');
author        ('Steffen Mueller (smueller@cpan.org)');
abstract      ('Create PAR distributions from CPAN');
version_from  ('lib/PAR/Dist/FromCPAN.pm');
license       ('perl');
install_script('bin/cpan2par');

requires      'CPAN' => '1.84';
requires      'PAR::Dist' => '0.31';
requires      'File::Copy' => '0';
requires      'File::Path' => '0';
requires      'File::Spec' => '0';
requires      'File::Find' => '0';
requires      'Cwd' => '0';
requires      'Module::CoreList' => '0';
requires      'Archive::Zip' => '0';
requires      'perl' => '5.006';

&WriteAll     ();

