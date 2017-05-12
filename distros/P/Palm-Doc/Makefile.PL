use ExtUtils::MakeMaker;

sub MY::postamble {
	return "ChangeLog:\n\tcvs2cl.pl -r --no-wrap --show-dead -S --utc\n\n";
}

WriteMakefile(
	'NAME'              => 'Palm::Doc',
	'VERSION_FROM'      => 'Doc.pm',
	'DISTNAME'          => 'Palm-Doc',
	'INSTALLDIRS'       => 'site',
	'AUTHOR' => 'Christophe Beauregard <cpb@cpan.org>',
	'ABSTRACT' => 'Module for processing PalmDoc databases',
	'PREREQ_PM' => {
		'Palm::PDB' => 1.0,
		'Palm::Raw' => 1.0,
		'HTML::TreeBuilder' => 0,
		'HTML::FormatText' => 0,
		'Getopt::Std' => 0,
		'Encode' => 0,
		'HTML::Entities' => 0,
		'Test::More' => 0.46,
	},
	'EXE_FILES' => [ 'makepalmdoc', 'mobisucks', 'htmltopalmdoc' ],
	'clean' => { FILES => 'ChangeLog' },
	'depend' => { 'distdir' => 'ChangeLog' },
);
