use strict;
use warnings;
use inc::Module::Install;
  
name         'Nes';
perl_version '5.008';
all_from     'lib/Nes.pm';
  
requires     'Crypt::CBC'            => '2.29';
requires     'Crypt::Blowfish'       => '2.10';
requires     'IO::String'            => '1.08';
requires     'IO::File'              => '1.13';
recommends   'ExtUtils::Manifest'    => '1.52';
recommends   'File::Copy::Recursive' => '0';
recommends   'File::ShareDir'        => '1.01';
recommends   'Env::C'                => '0.08';
recommends   'IPC::Run'              => '0.84';
recommends   'DBI'                   => '1.601';
recommends   'DBD::mysql'            => '4.006';
recommends   'DBD::Pg'               => '2.5.0';

no_index     'directory' => 'share';
#no_index      package    => 'DB';

install_script 'set_nes_site';
install_share  'share';
  
WriteAll;
