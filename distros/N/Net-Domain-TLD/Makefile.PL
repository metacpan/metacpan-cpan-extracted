use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Net::Domain::TLD',
    VERSION_FROM => 'lib/Net/Domain/TLD.pm', # finds $VERSION
    AUTHOR       => 'Alex Pavlovic (alex.pavlovic@devradius.com)',
    ABSTRACT     => 'Net::Domain::TLD - Work with TLD names',
    PREREQ_PM   => {
	'Carp'	=> '0', 
	'Storable' => '0'
    }
);
