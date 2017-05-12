use ExtUtils::MakeMaker;
WriteMakefile( NAME         => "Music::Audioscrobbler::MPD",
               VERSION_FROM => "lib/Music/Audioscrobbler/MPD.pm",
               ABSTRACT     => 'MPD Audioscrobbler Routines',
               AUTHOR       => 'Edward Allen (ealleniii _at_ cpan _dot_ org)',
			   LICENSE		=> 'perl',
               PREREQ_PM    => {
                              'Music::Audioscrobbler::Submit' => .03,
                              'File::Spec'      => 3,
                              'Digest::MD5'     => 2,
                              'Encode'          => 2,
                              'IO::Socket'      => 1,
                              'IO::File'        => 1,
                              'Config::Options' => 0.01,
                              'Proc::Daemon'    => .03,
                            },
               EXE_FILES => ['bin/musicmpdscrobble'],
             );
