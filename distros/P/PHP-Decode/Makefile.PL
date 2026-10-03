use strict;
use warnings;

use 5.016;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME             => 'PHP::Decode',
	AUTHOR           => 'Barnim Dzwillo @ Strato AG',
	VERSION_FROM     => 'lib/PHP/Decode.pm',
	ABSTRACT_FROM    => 'lib/PHP/Decode.pm',
	MIN_PERL_VERSION => "5.016",
	LICENSE          => 'perl',
	META_MERGE       => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => 'https://github.com/bdzwillo/php_decode.git',
				web  => 'https://github.com/bdzwillo/php_decode',
			},
		},
	},
	PREREQ_PM => {
		'Tie::IxHash' => 1,
		'Compress::Zlib' => 1,
		'Digest::MD5' => 1,
		'Digest::SHA' => 1,
		'MIME::Base64' => 1,
		'URI::Escape' => 1,
		'HTML::Entities' => 1,
	},
	EXE_FILES        => [ 'php_decode' ],
	TEST_REQUIRES    => {
		'Test::More' => 1, # should be in core but is seperately packaged by RH
	},
);

# create rpm via 'make rpm'
#
sub MY::postamble {
return <<'MAKE_DOCS';
rpm:
	$(RM_F) $(DISTVNAME).tar$(SUFFIX)
	$(MAKE) dist
	rpmbuild -ta $(DISTVNAME).tar$(SUFFIX)

# keep rpm spec version in sync with $VERSION
create_distdir: specversion

.PHONY: specversion
specversion:
	$(PERL) -i -pe 's/^(Version:\s*).*/$${1}$(VERSION)/' perl-PHP-Decode.spec

MARKDOWNPAGES = $(foreach manpage, ${MAN3PODS},docs/$(subst /,::,$(patsubst lib/%.pm,%,${manpage})).md)

docs/%.md:
	pod2markdown lib/$(subst ::,/,$*).pm $@

.PHONY: docs
docs:
	-rm -f $(MARKDOWNPAGES)
	make $(MARKDOWNPAGES)
MAKE_DOCS
}
