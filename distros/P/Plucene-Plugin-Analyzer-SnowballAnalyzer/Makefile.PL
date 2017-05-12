use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Plucene::Plugin::Analyzer::SnowballAnalyzer',
    VERSION_FROM      => 'lib/Plucene/Plugin/Analyzer/SnowballAnalyzer.pm',
    PREREQ_PM         => {
	'Lingua::Stem::Snowball' => 0,
	'Lingua::StopWords' => 0,
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Plucene/Plugin/Analyzer/SnowballAnalyzer.pm',
       AUTHOR         => 'Fabien POTENCIER <fabpot@cpan.org>') : ()),
);
