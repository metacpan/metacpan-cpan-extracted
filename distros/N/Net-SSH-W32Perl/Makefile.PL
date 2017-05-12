use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Net::SSH::W32Perl',
    DISTNAME => 'Net-SSH-W32Perl',
    VERSION_FROM => 'lib/Net/SSH/W32Perl.pm',
    PREREQ_PM => { 
    	Net::SSH::Perl => 1.23,
    	IO::String => 1.01,
    	IO::Select::Trap => 0.02,
    	# The following prereqs force installation of
    	# some 'optional' packages that are used
    	# by Net::SSH::Perl
    	Convert::ASCII::Armour => 1.4,
    	Data::Buffer => 0.04,
    	Digest::BubbleBabble => 0.01
    },
    AUTHOR     => 'Scott Scecina <scotts@inmind.com>',
    ABSTRACT => 'Win32 (ActivePerl) Compatibility Layer for Net::SSH::Perl',
);
