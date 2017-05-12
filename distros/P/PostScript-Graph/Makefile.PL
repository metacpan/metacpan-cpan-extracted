use ExtUtils::MakeMaker;
use 5.6.1;
my $abstract = <<END;
=head1 NAME

PostScript::Graph - Adding graphs to PostScript files
END

WriteMakefile(
    NAME	  => 'PostScript::Graph',
    VERSION	  => '1.02',
    ABSTRACT      => $abstract,
    PREREQ_PM	  => { 
	'Exporter' => 0,
	'Carp' => 0,
	'Test::More' => 0,
	'Text::CSV_XS' => 0,
	'PostScript::File'  => 1.01,
		   },
    PM	=> {
	'Graph/Bar.pm'   => '$(INST_LIBDIR)/Graph/Bar.pm',
	'Graph/Key.pm'   => '$(INST_LIBDIR)/Graph/Key.pm',
	'Graph/Paper.pm' => '$(INST_LIBDIR)/Graph/Paper.pm',
	'Graph/Style.pm' => '$(INST_LIBDIR)/Graph/Style.pm',
	'Graph/XY.pm'    => '$(INST_LIBDIR)/Graph/XY.pm',
    },
    AUTHOR => 'Christopher Willmot <chris@willmot.org.uk>',
);
