

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME					=> 'P',
    VERSION_FROM	=> 'lib/P.pm', # finds \$VERSION
		AUTHOR				=> 'LA Walsh <LAWALSH@cpan.org>',
    ABSTRACT			=> 'safer+easier [s]print[f], & say all-in-1',
    BUILD_REQUIRES => { 
											'ExtUtils::MakeMaker' => '6.82', 
											'perl' => '5.8.5', 
											'PerlIO' => '1.03', },
    CONFIGURE_REQUIRES => { 'version' => '0.77' },
		LICENSE				=> 'perl',
		PERM_DIR			=> '0775',
		PERM_RW				=> '0664',
		PERM_RWX			=> '0775',
    PREREQ_PM    	=> {
										 'mem'			=> '0.4.5', 		'Types::Core' => '0.1.8',
										 'Xporter'	=>	'0.1.2',
                    },
		TEST_REQUIRES=> {
                     'Test::Simple' => '0.44',	'Types::Core' => '0.1.8',
										 'mem'	=> '0.4.3',					'version'			=> '0.77',
										 'Xporter'			=> '0.1.2',
									 },
		dist				=> { TAR=> 'ptar' , TARFLAGS=> "-cvf" },
);
