#!/usr/bin/env perl

use inc::Module::Install;
name          ('PAR-Dist-InstallPPD-GUI');
author        ('Steffen Mueller (smueller@cpan.org)');
abstract      ('GUI frontend for PAR::Dist::InstallPPD');
version_from  ('lib/PAR/Dist/InstallPPD/GUI.pm');
license       ('perl');
install_script('bin/parinstallppdgui');

requires      'PAR::Dist::InstallPPD' => '0.01';
requires      'perl' => '5.006';
requires      'Tk' => '0';
requires      'Tk::Dialog' => '0';
requires      'Tk::ROText' => '0';
requires      'IO::Dir' => '0';
requires      'IPC::Run' => '0.80';
requires      'File::UserConfig' => '0';
requires      'Config::IniFiles' => '0';
requires      'PAR::Dist::FromPPD' => '0.02';
requires      'ExtUtils::Install' => '0';

# generate default config from module:
use File::Spec;
mkdir('config');
open my $fh, '<', File::Spec->catfile(qw/lib PAR Dist InstallPPD GUI.pm/)
  or die "Could not read module source code: $!";
open my $oh, '>', File::Spec->catfile(qw/config config.ini/);
while (<$fh>) {
    last if /^__DATA__\s*$/;
}
while (<$fh>) {
    print $oh $_;
}
close $fh;
close $oh;

install_share 'config';

&WriteAll     ( );

