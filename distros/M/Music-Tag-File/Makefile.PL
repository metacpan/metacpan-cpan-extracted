use ExtUtils::MakeMaker;
WriteMakefile( NAME         => "Music::Tag::File",
               VERSION_FROM => "lib/Music/Tag/File.pm",
               ABSTRACT_FROM => 'lib/Music/Tag/File.pm',
               AUTHOR       => 'Edward Allen (ealleniii _at_ cpan _dot_ org)',
			   LICENSE		=> 'perl',
               PREREQ_PM => { 'Music::Tag'				=> 0.4101,
                              'File::Spec'              => 3.24,
							  'Test::More'				=> 0,
							  'File::Copy'				=> 0,
                            },
             );

