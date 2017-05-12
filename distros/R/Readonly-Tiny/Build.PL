use Module::Build;

Module::Build->new(
    module_name		=> "Readonly::Tiny",
    license		=> "bsd",
    configure_requires	=> {
	"Module::Build"	    => "0.38",
    },
    build_requires	=> {
	"Test::More"	    => "0.96",
        "Test::Exception"   => 0,
        "Test::Exports"     => 0,
    },
    meta_merge		=> {
	resources   => {
	    repository => "http://github.com/mauzo/Readonly-Tiny",
	    bugtracker => "https://rt.cpan.org/Public/Dist/" .
		"Display.html?Name=Readonly-Tiny",
	},
    },
)->create_build_script;
