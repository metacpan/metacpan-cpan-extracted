use ExtUtils::MakeMaker;

WriteMakefile(
	NAME            => 'TVGuide::NL',
	VERSION_FROM    => 'lib/TVGuide/NL.pm',
	clean			=> { FILES => 'blib/lib/TVGuide/NL/Names.pm' },
	depend			=> { 'pm_to_blib' => 'blib/lib/TVGuide/NL/Names.pm' },
	PREREQ_PM		=> {
        'Carp' =>                   0,
        'File::Spec' =>             0,
        'Storable' =>               0,
        'Time::Local' =>            0,
        'HTML::Entities' =>         0,
        'LWP::UserAgent' =>         0,
        'HTML::TreeBuilder' =>      0,
        'HTML::TokeParser' =>       0,
        'Encode' =>                 0,
        'Data::Dumper' =>           0,
	}
);

sub MY::postamble
{
	return <<'EOF';
blib/lib/TVGuide/NL/Names.pm: utils/maketables.pl
	$(NOECHO) echo Fetching station information from http://gids.omroep.nl/
	$(NOECHO)test -d blib/lib/TVGuide/NL || mkdir -p blib/lib/TVGuide/NL/
	$(NOECHO) $(PERLRUN) utils/maketables.pl > $@
EOF
}
