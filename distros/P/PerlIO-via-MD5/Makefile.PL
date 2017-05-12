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
 NAME		=> "PerlIO::via::MD5",
 AUTHOR		=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
 ABSTRACT	=> 'PerlIO Layer for MD5 Digests',
 VERSION_FROM	=> 'lib/PerlIO/via/MD5.pm',
 PREREQ_PM	=> {
                    'Digest::MD5' => 0,
                   },
);
