use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Reaper',
    'VERSION_FROM'	=> 'Reaper.pm',

    'PM' => { 'Reaper.pm' => '$(INST_LIBDIR)/Reaper.pm',
	      'reaper.pm' => '$(INST_LIBDIR)/reaper.pm' },


    ABSTRACT => 'handler for reaping child process to prevent zombies',
    AUTHOR => 'Jeremy Slade <jeremy@jkslade.net>',
);
