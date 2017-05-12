use ExtUtils::MakeMaker;
WriteMakefile( NAME         => "Music::Tag::FLAC",
               VERSION_FROM => "lib/Music/Tag/FLAC.pm",
               ABSTRACT_FROM  => "lib/Music/Tag/FLAC.pm",
               AUTHOR       => 'Edward Allen (ealleniii _at_ cpan _dot_ org)',
			   LICENSE		=> 'perl',
               PREREQ_PM => { 'Music::Tag'			    => 0.4101, 
			   				  'Audio::FLAC::Header'     => 1.7,
                            },
             );

