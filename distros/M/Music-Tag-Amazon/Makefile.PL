use ExtUtils::MakeMaker;
WriteMakefile( NAME         => "Music::Tag::Amazon",
               VERSION_FROM => "lib/Music/Tag/Amazon.pm",
               ABSTRACT_FROM => "lib/Music/Tag/Amazon.pm", 
               AUTHOR       => 'Edward Allen (ealleniii _at_ cpan _dot_ org)',
			   LICENSE		=> 'perl',
               PREREQ_PM => { 'Music::Tag'			    => 0.4101,
                              'Cache::Cache'            => 1.05,
                              'Data::Dumper'            => 2.0,
                              'Digest::SHA1'            => 2.11,
                              'LWP'                     => 5.805,
                              'Net::Amazon'             => 0.59,
							  'Test::More'				=> 0,
							  'File::Copy'				=> 0,
                            },
             );

