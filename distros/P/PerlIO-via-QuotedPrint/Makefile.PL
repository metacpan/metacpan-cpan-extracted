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
 NAME		=> "PerlIO::via::QuotedPrint",
 AUTHOR		=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
 ABSTRACT	=> 'PerlIO Layer for quoted-printable encoding',
 VERSION_FROM	=> 'lib/PerlIO/via/QuotedPrint.pm',
 PREREQ_PM	=> {
                    'MIME::QuotedPrint' => 0,
                   },
);
