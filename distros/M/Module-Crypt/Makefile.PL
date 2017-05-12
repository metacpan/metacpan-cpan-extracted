use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
	AUTHOR			=> 'Alessandro Ranellucci <aar@cpan.org>',
	NAME      		=> 'Module::Crypt',
    ABSTRACT		=> 'Encrypt your Perl code and compile it into XS',
	VERSION_FROM 	=> 'Crypt.pm',
    'PREREQ_PM'		=> {
    	Carp			        => 0,
    	File::Copy              => 0,
    	File::Path		        => 0,
    	File::Find		        => 0,
    	File::Spec		        => 0,
    	File::Temp		        => 0,
    	ExtUtils::CBuilder		=> 0,
    	ExtUtils::ParseXS 		=> 0,
    	ExtUtils::Mkbootstrap 	=> 0,
        Crypt::RC4              => 0,
    },
    'dist'         	=> { COMPRESS => 'gzip', SUFFIX => 'gz' }
);
