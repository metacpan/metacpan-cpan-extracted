use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
BEGIN{push @INC, "./lib"}
WriteMakefile(
    NAME              => 'Perlwikipedia::Plugin::ImageTester',
    VERSION_FROM      => 'lib/Perlwikipedia/Plugin/ImageTester.pm', # finds $VERSION
    PREREQ_PM         => { WWW::Mechanize => '1.30',
			   HTML::Entities => 1.35,
			   URI::Escape    => 3.28,
			   XML::Simple    => 2.16,
			   Carp 	       => 0,
			   Perlwikipedia  => 1.5.2},
	 ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
	 (ABSTRACT_FROM    => 'lib/Perlwikipedia/Plugin/ImageTester.pm', # retrieve abstract from module
    AUTHOR            => 'Dan Collins (ST47)') : () ),
    LICENSE           => 'gpl',
);
