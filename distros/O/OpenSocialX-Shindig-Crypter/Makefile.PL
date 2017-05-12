
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'OpenSocialX-Shindig-Crypter',
  NAME      => 'OpenSocialX::Shindig::Crypter',
  AUTHOR    => 'Fayland\ Lam\ \<fayland\@gmail\.com\>',
  ABSTRACT  => 'OpenSocial\ Shindig\ Crypter',
  VERSION   => '0.03',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "Crypt::CBC" => '2.30',
    "URI::Escape" => '0',
    "MIME::Base64" => '0',
    "Digest::SHA" => '5.47',
    "Crypt::Rijndael" => '1.07',
  },
);
