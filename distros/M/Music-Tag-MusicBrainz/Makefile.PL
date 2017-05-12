use ExtUtils::MakeMaker;
WriteMakefile( NAME         => "Music::Tag::MusicBrainz",
               VERSION_FROM => "lib/Music/Tag/MusicBrainz.pm",
               ABSTRACT_FROM => "lib/Music/Tag/MusicBrainz.pm",
               AUTHOR       => 'Edward Allen (ealleniii _at_ cpan _dot_ org)',
			   LICENSE		=> 'perl',
               PREREQ_PM => { 'Music::Tag'     => .4101,
                              'WebService::MusicBrainz' => 0.07,
                              'Text::Levenshtein' => 0,
                              'Cache::FileCache' => 0,
                              
                            },
             );

