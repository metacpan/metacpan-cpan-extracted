use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

# now write Makefile
WriteMakefile(
    NAME              => 'Search::Estraier',
    VERSION_FROM      => 'lib/Search/Estraier.pm', # finds $VERSION
    PREREQ_PM         => {
		'Carp' => 0,
		'Test::Simple' => 0,
		'Test::Exception' => 0,
		'URI' => 0,
		'LWP::UserAgent' => 0,
		'MIME::Base64' => 0,
		'URI::Escape' => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Search/Estraier.pm', # retrieve abstract from module
       AUTHOR         => 'Dobrica Pavlinusic <dpavlin@rot13.org>') : ()),
       clean	=> { FILES => "Makefile Makefile.old pod2html" },
);

sub MY::postamble {
	return <<'MAKE_MORE';

HTML_DIR=pod2html

html: $(TO_INST_PM)
	test -e $(HTML_DIR) || mkdir $(HTML_DIR)
	ls $(MAN1PODS) $(MAN3PODS) | xargs -i sh -c 'pod2xhtml.pl < {} > pod2html/`basename {} | cut -d. -f1`.html'
	rm -f pod2htm?.tmp
	test ! -z "`which svn2html.pl`" && svn update && svn2html.pl > $(HTML_DIR)/Changes.html

changelog:
	svk log -v > Changes

tags:
	ctags *.p?

cpan:
	make clean
	rm -f Search-Estraier-*.tar.gz
	perl Makefile.PL
	make changelog
	make dist
	make disttest
	sudo /etc/init.d/hyperestraier stop
	make disttest
	sudo /etc/init.d/hyperestraier start
	@echo
	@echo -n "Upload" Search-Estraier-*.tar.gz "to CPAN? [y/N]:"
	@read upload && test "$$upload" == "y" && cpan-upload -verbose Search-Estraier-*.tar.gz

cover:
	cover -delete
	HARNESS_PERL_SWITCHES=-MDevel::Cover make test
	cover

MAKE_MORE
}
