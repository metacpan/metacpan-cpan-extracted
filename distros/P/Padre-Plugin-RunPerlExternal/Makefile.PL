use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Padre::Plugin::RunPerlExternal',
    AUTHOR              => q{Matthias Ries <riesm@cpan.org>},
    
    VERSION_FROM        => 'lib/Padre/Plugin/RunPerlExternal.pm',
    ABSTRACT_FROM	=> 'lib/Padre/Plugin/RunPerlExternal.pm', 
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    BUILD_REQUIRES => {
	'Test::More' => 0,
    },
    PREREQ_PM => {
        'Test::More' => 0,
	'Padre' => '0.57',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Padre-Plugin-RunPerlExternal-*' },
    META_MERGE		=> {
                        "resources" => {
			    "repository" => {  "url" => "https://github.com/matthiasries/Padre-Plugin-RunPerlExternal"  }
			},
			"x_screenshots" => 
			[
                          "http://www.imagebanana.com/view/3tndocxg/Padre_018.png",
                          "http://www.imagebanana.com/view/xiglvtu7/Auswahl_021.png" 
                        ]
	},
);
