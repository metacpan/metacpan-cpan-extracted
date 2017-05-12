require 5.008;
use Config;
use ExtUtils::MakeMaker;

if (!$Config{useperlio}) {
    warn <<WHOA
*** WHOA THERE!!! ***
This is not a perlio-enabled perl !

This module will not function with this perl !
WHOA
}

WriteMakefile(
    NAME	    => 'PerlIO::via::StripHTML',
    VERSION_FROM    => 'lib/PerlIO/via/StripHTML.pm',
    PREREQ_PM	    => {
	'HTML::Parser' => 3.00,
    },
);
