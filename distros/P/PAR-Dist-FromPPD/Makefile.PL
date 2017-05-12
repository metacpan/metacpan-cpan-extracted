#!/usr/bin/env perl

use inc::Module::Install;
name          ('PAR-Dist-FromPPD');
author        ('Steffen Mueller (smueller@cpan.org)');
abstract      ('Create PAR distributions from PPDs');
version_from  ('lib/PAR/Dist/FromPPD.pm');
license       ('perl');
install_script('bin/ppd2par');

requires      'PAR::Dist' => '0.20';
requires      'File::Copy' => '0';
requires      'File::Path' => '0';
requires      'File::Spec' => '0';
requires      'Getopt::Long' => '0';
requires      'Cwd' => '0';
requires      'XML::Parser' => '0';
requires      'LWP::Simple' => '0';
requires      'Archive::Tar' => '0';
requires      'File::Temp' => '0';
requires      'perl' => '5.006';

&WriteAll     ( );

