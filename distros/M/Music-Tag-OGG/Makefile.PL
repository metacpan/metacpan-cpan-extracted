use ExtUtils::MakeMaker;
WriteMakefile( NAME         => "Music::Tag::OGG",
               VERSION_FROM => "lib/Music/Tag/OGG.pm",
               ABSTRACT_FROM => "lib/Music/Tag/OGG.pm",
               AUTHOR       => 'Edward Allen (ealleniii _at_ cpan _dot_ org)',
			   LICENSE		=> 'perl',
               PREREQ_PM => { 'Music::Tag'				=> 0.4101,
							  'Ogg::Vorbis::Header::PurePerl'		=> 1,
                            },
             );
