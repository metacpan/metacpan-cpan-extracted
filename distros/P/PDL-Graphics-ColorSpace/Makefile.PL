use PDL::Core::Dev;
use ExtUtils::MakeMaker;
PDL::Core::Dev->import();

$package = ["color_space.pp",ColorSpace,PDL::Graphics::ColorSpace];
%hash = pdlpp_stdargs($package);
$hash{'OBJECT'} .= ' color_space$(OBJ_EXT)';
$hash{'clean'}{FILES} .= ' color_space$(OBJ_EXT)';

WriteMakefile( %hash,
	VERSION_FROM        => 'color_space.pp',
    AUTHOR              => 'Maggie J. Xiong  <maggiexyz+github gmail.com>',
	PM => {
		'ColorSpace.pm'           => '$(INST_LIBDIR)/ColorSpace.pm',
		'ColorSpace/RGBSpace.pm'  => '$(INST_LIBDIR)/ColorSpace/RGBSpace.pm',
	},
    PREREQ_PM => {
        'Test::More' => 0,
        'PDL'        => '2.4.4',
    },
    dist                          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);

sub MY::postamble {pdlpp_postamble($package)};
