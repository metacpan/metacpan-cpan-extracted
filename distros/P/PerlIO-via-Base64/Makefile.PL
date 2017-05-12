require 5.008;
use Config;
use ExtUtils::MakeMaker;
eval "use Devel::Required";

warn <<EOD unless $Config{useperlio};
    *** WHOA THERE!!! ***
    This is not a perlio-enabled perl !

    This module will not function with this perl !
EOD

WriteMakefile (
 NAME		=> "PerlIO::via::Base64",
 AUTHOR		=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
 ABSTRACT	=> 'PerlIO Layer for Base64 (MIME) encoding',
 VERSION_FROM	=> 'lib/PerlIO/via/Base64.pm',
 PREREQ_PM	=> {
                    'MIME::Base64' => 0,
                   },
);
