use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'AUTHOR'		=> 'Tsukui Akihiro (milano@cpan.org)',
    'NAME'		=> 'SVGGraph::Pie',
    'VERSION_FROM'	=> 'lib/SVGGraph/Pie.pm', # finds $VERSION
    'PREREQ_PM'		=> {
	Test::More => 0.32,
	SVG        => 0,
	}
);
