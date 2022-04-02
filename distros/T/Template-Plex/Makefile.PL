use ExtUtils::MakeMaker;
WriteMakefile(
	NAME			=> 'Template::Plex',
	VERSION_FROM		=> 'lib/Template/Plex.pm', 
	PREREQ_PM		=> {
					enum=>0,
					"String::Util"=>0

				}, 
	ABSTRACT_FROM		=> 'lib/Template/Plex.pod', # retrieve abstract from module
	AUTHOR			=> 'Ruben Westerberg <drclaw@mac.com>',
	LICENSE			=> 'mit',

	MIN_PERL_VERSION	=> '5.24.0',		#for ref aliasing
	TEST_REQUIRES		=> { "Test::More" => 0},
	CONFIGURE_REQUIRES 	=> {"ExtUtils::MakeMaker"=>0},


	META_ADD => {
		"meta-spec" => {
			version => 2
		},
		resources=> {
			repository =>{
				type => "git",
				url => "git://github.com/drclaw1394/perl-template-plex.git",
				web => "http://github.com/drclaw1394/perl-template-plex",
			}
		}
	}

);
