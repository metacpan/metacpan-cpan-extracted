use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $cgiDir = prompt("Where should the wiki.pl CGI be installed?",
    '/var/www/cgi-bin');

WriteMakefile(
    'NAME'		=> 'PurpleWiki',
    'VERSION'	=> '0.94',
    'PREREQ_PRINT' => 1,
    'EXE_FILES' => [
        'wiki.pl',
        ],
    'INSTALLSCRIPT' => $cgiDir,
    'PREREQ_PM'		=> {
        Template => 0,
    	Text::Wrap => 0,
        Text::Diff => 0,
        LWP::UserAgent => 0,
        IO::File => 0,
        Date::Manip => 0,
        DB_File => 0,
        AppConfig => 1.55,
        CGI => 0,
        CGI::Carp => 0,
        CGI::Session => 0,
        Template => 0,
        XML::RSS => 0,
#        XDI::SPIT => 1.11,
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT   => 'WikiWiki with purple numbers',
       AUTHOR     => 'Chris Dent <cdent@blueoxen.org>, Eugene Eric Kim <eekim@blueoxen.org>') : ()),
);
