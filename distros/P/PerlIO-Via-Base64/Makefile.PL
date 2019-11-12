require 5.008;
use Config;
use ExtUtils::MakeMaker;

warn <<EOD unless $Config{useperlio};
    *** WHOA THERE!!! ***
    This is not a perlio-enabled perl !

    This module will not function with this perl !
EOD

WriteMakefile (
 NAME		=> "PerlIO::Via::Base64",
 ($[ >= 5.005) ?
 (AUTHOR	=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
  ABSTRACT	=> 'PerlIO Layer for quoted-printable encoding') : (),
 VERSION_FROM	=> 'lib/PerlIO/Via/Base64.pm',
 PREREQ_PM	=> {
                    'MIME::Base64' => 0,
                   },
);
