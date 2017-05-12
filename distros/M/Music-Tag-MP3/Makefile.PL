use ExtUtils::MakeMaker;
WriteMakefile( NAME         => 'Music::Tag::MP3',
               VERSION_FROM => 'lib/Music/Tag/MP3.pm',
               ABSTRACT_FROM => 'lib/Music/Tag/MP3.pm',
               AUTHOR       => 'Edward Allen (ealleniii _at_ cpan _dot_ org)',
			   LICENSE		=> 'perl',
               PREREQ_PM => { 'Music::Tag'			    => 0.4101, 
                              'Data::Dumper'            => 2.0,
                              'Encode'                  => 2.12,
                              'File::Spec'              => 3.24,
                              'IO::File'                => 1.13,
                              'MP3::Info'               => 1.23,
                              'MP3::Tag'                => 1.13,
							  'Test::More'				=> 0,
							  'File::Copy'				=> 0,
                            },
             );

