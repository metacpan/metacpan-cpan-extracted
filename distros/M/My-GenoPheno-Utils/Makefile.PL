use strict;
use warnings;

use ExtUtils::MakeMaker;


WriteMakefile(
    NAME         => 'My::GenoPheno::Utils',
    VERSION_FROM => 'lib/My/GenoPheno/Utils.pm',
    ABSTRACT     => 'Utility functions for GenoPheno SNP processing',
    AUTHOR       => 'Samira Ghareh Gozlou <samira.grgzlo@gmail.com>',
    LICENSE      => 'perl',

    
	PREREQ_PM => {
			'JSON' => 0,
	},
);
