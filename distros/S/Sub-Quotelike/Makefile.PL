use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'Sub::Quotelike',
    'VERSION_FROM'	=> 'lib/Sub/Quotelike.pm', # finds $VERSION
    'PREREQ_PM'		=>
	{
	    'Filter::Simple' => 0.61,
	    'Text::Balanced' => 1.83,
	},
);
