use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Plucene::Plugin::Analyzer::MetaphoneAnalyzer',
    VERSION_FROM      => 'lib/Plucene/Plugin/Analyzer/MetaphoneAnalyzer.pm',
    PREREQ_PM         => {
	'Text::Metaphone' => 0,
	'IO::Scalar' => 0,
	'Plucene::Analysis::Analyzer' => 0,
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Plucene/Plugin/Analyzer/MetaphoneAnalyzer.pm',
       AUTHOR         => 'Alan Schwartz <alansz@uic.edu>') : ()),
);
