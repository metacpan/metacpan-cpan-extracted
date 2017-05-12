use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Spreadsheet::Perl',
    'VERSION_FROM'	=> 'Perl.pm', # finds $VERSION
    #'DIR'               => ['Perl'],
    'PREREQ_PM'		=>
    	{
	Term::Size::Any        => 0.001,
	Spreadsheet::ConvertAA => 0.02,
        Data::TreeDumper       => 0.12,
        Data::Table => 1.50,
	Text::ASCIITable       => 0.12
	},

    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Perl.pm', # retrieve abstract from module
       AUTHOR     => '<Khemir Nadim ibn Hamouda. <nadim@khemir.net>') : ()),
);
