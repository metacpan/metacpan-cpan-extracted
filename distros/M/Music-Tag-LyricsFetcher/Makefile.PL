use ExtUtils::MakeMaker;
WriteMakefile( NAME         => "Music::Tag::LyricsFetcher",
               VERSION_FROM => "lib/Music/Tag/LyricsFetcher.pm",
               ABSTRACT_FROM => "lib/Music/Tag/LyricsFetcher.pm",
               AUTHOR       => 'Edward Allen <ealleniii@cpan _dot_ org>',
			   LICENSE		=> 'perl',
               PREREQ_PM => { 'Music::Tag'     => .4101,
							  'Lyrics::Fetcher'	=> 0.005,
							  'Lyrics::Fetcher::LyricWiki' => 0.01,
                            },
             );
