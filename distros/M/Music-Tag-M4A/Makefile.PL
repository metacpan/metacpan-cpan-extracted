use ExtUtils::MakeMaker;
WriteMakefile( NAME         => 'Music::Tag::M4A',
               VERSION_FROM => 'lib/Music/Tag/M4A.pm',
               ABSTRACT_FROM => 'lib/Music/Tag/M4A.pm',
               AUTHOR       => 'Edward Allen (ealleniii _at_ cpan _dot_ org)',
			   LICENSE		=> 'perl',
               PREREQ_PM => { 'Music::Tag'     			=> 0.4101,
			   				  'Tree::Simple'			=> 0,
                              'Audio::M4P::QuickTime'   => 0.37,
                              'MP4::Info'               => 1.12,
                            },
             );

