# -*- cperl -*-
use 5.006;
use ExtUtils::MakeMaker;

my $is_devel_host = defined $ENV{USER} && $ENV{USER} eq 'eserte' && $^O =~ /bsd/i && -f "../../perl.release.mk";
my $eumm_recent_enough = $ExtUtils::MakeMaker::VERSION >= 6.54;

if (!$eumm_recent_enough) {
    *MY::dist_core = sub {
	<<'EOF';
dist :
	$(NOECHO) $(ECHO) "Sorry, use a newer EUMM!"

EOF
    };
}

WriteMakefile(NAME => 'Parse::CPAN::Packages::Fast',
	      VERSION_FROM => 'lib/Parse/CPAN/Packages/Fast.pm',
	      PREREQ_PM => { 'CPAN::Version'      => 0,
			     'CPAN::DistnameInfo' => 0,
			     'IO::Uncompress::Gunzip' => 0,
			   },
	      ($eumm_recent_enough ?
	       (META_ADD => { resources => { repository => 'git://github.com/eserte/parse-cpan-packages-fast.git' } }) : ()),
	     );

sub MY::postamble {
    my $postamble = '';

    $postamble .= <<'EOF';
authdisttest : distdir
	cd $(DISTVNAME) && $(ABSPERLRUN) Makefile.PL 
	cd $(DISTVNAME) && $(MAKE) $(PASTHRU)
	cd $(DISTVNAME) && env PERL_AUTHOR_TEST=1 $(MAKE) test $(PASTHRU)

EOF

    if ($is_devel_host) {
        $postamble .= <<'EOF';

.include "../../perl.release.mk"
.include "../../perl.git.mk"

EOF
    }

    $postamble;
}
