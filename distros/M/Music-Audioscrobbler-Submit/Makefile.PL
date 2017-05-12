use ExtUtils::MakeMaker;
WriteMakefile( NAME         => "Music::Audioscrobbler::Submit",
               VERSION_FROM => "lib/Music/Audioscrobbler/Submit.pm",
               ABSTRACT_FROM => "lib/Music/Audioscrobbler/Submit.pm", 
               AUTHOR       => 'Edward Allen (ealleniii _at_ cpan _dot_ org)',
			   LICENSE		=> 'perl',
               PREREQ_PM    => {
                              'File::Spec'      => 3,
                              'Digest::MD5'     => 2,
                              'Encode'          => 2,
                              'IO::File'        => 1,
                              'Config::Options' => 0.01,
                              'LWP::UserAgent'  => 2,
                              'Tie::Hash'       => 1,
                            },
             );
