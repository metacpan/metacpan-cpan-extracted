use PDL::Core::Dev;
use ExtUtils::MakeMaker;
PDL::Core::Dev->import();
require "pdlmaker.plm";

$package = ["color_distance.pp", ColorDistance, PDL::Graphics::ColorDistance];
#%hash = pdlpp_stdargs($package);
%hash = pdlmaker_init($package);
$hash{'OBJECT'} .= ' color_distance$(OBJ_EXT)';
$hash{'clean'}{FILES} .= ' color_distance$(OBJ_EXT)';

WriteMakefile( %hash,
	VERSION_FROM        => 'color_distance.pp',
    AUTHOR              => 'Eric Waters  <ewaters gmail.com>',
	PM => {
		'ColorDistance.pm' => '$(INST_LIBDIR)/ColorDistance.pm',
	},
    CONFIGURE_REQUIRES => {
        'PDL'        => '2.4.4',
    },
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist             => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);

#sub MY::postamble {pdlpp_postamble($package)};
