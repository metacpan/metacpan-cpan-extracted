use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker 7.12;    # XSMULTI
use File::Find qw(find);

# Build the META "provides" map by hand. Module::Metadata does not
# recognise Object::Pad's "class NAME" declarations, so the generated
# map would list those files as package "main"; an explicit map lets
# PAUSE index the dist from META alone.
sub collectProvides {
	my %provides;
	find(
		{
			no_chdir => 1,
			wanted   => sub {
				return unless /\.pm\z/;
				my ( $package, $version ) = readPackageAndVersion($_);
				$provides{$package} = { file => $_, version => $version };
			},
		},
		'lib'
	);
	return \%provides;
}

sub readPackageAndVersion {
	my ($file) = @_;
	open( my $fh, '<', $file ) or die sprintf( "Cannot read %s: %s\n", $file, $! );
	my ( $package, $version );
	while ( my $line = <$fh> ) {
		$package //= $1 if $line =~ /^\s*(?:package|class|role|enum)\s+([\w:]+)/;
		$version //= $1 if $line =~ /^\s*our\s+\$VERSION\s*=\s*'([^']*)'/;
		last if defined $package && defined $version;
	}
	close($fh);
	die sprintf( "No package or class declaration found in %s\n", $file ) unless defined $package;
	die sprintf( "No \$VERSION found in %s\n",                    $file ) unless defined $version;
	return ( $package, $version );
}

WriteMakefile(
	DISTNAME           => 'Term-Fabulous',
	NAME               => 'Term::Fabulous',
	AUTHOR             => 'davenonymous <perl@davenonymous.com>',
	VERSION_FROM       => 'lib/Term/Fabulous.pm',
	ABSTRACT_FROM      => 'lib/Term/Fabulous.pm',
	LICENSE            => 'perl_5',
	MIN_PERL_VERSION   => '5.032001',
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => '7.12',
	},

	# termbox2 is compiled in: src/termbox2.c holds the library (TB_IMPL),
	# lib/Term/Fabulous/Termbox.xs the Perl surface. XSMULTI builds the
	# .xs where it lives and names the .so after it (auto/Term/Fabulous/
	# Termbox/Termbox.so), so the dist's NAME can stay Term::Fabulous.
	XSMULTI => 1,
	XSBUILD => {
		xs => {
			'lib/Term/Fabulous/Termbox' => {
				OBJECT => 'lib/Term/Fabulous/Termbox$(OBJ_EXT) src/termbox2$(OBJ_EXT)',
				INC    => '-I. -Isrc',
			},
		},
	},
	C => ['src/termbox2.c'],
	H => [ 'src/termbox2.h', 'src/tf_termbox.h' ],
	( $Config{gccversion} ? ( CCFLAGS => "$Config{ccflags} -std=c99 -Wall -Wextra" ) : () ),
	TEST_REQUIRES => {
		'Test2::V0' => '0',
	},
	PREREQ_PM => {
		'Clay::UI'                        => '0.06',
		'Clay::XS'                        => '0.05',
		'Encode'                          => '0',
		'Exporter'                        => '0',
		'Feature::Compat::Try'            => '0',
		'I18N::Langinfo'                  => '0',
		'IO::Async'                       => '0',
		'List::Util'                      => '1.33',
		'MIME::Base64'                    => '0',
		'Object::Pad'                     => '0.825',
		'Object::PadX::Enum'              => '0',
		'POSIX'                           => '0',
		'Scalar::Util'                    => '0',
		'Socket'                          => '0',
		'Text::KDL::XS'                   => '0.002',
		'Time::HiRes'                     => '0',
		'Time::Local'                     => '1.30',
		'Unicode::GCString'               => '0',
		'XSLoader'                        => '0',
	},
	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources   => {
			homepage   => 'https://github.com/davenonymous/perl-term-fabulous',
			bugtracker => { web => 'https://github.com/davenonymous/perl-term-fabulous/issues' },
			repository => {
				type => 'git',
				url  => 'https://github.com/davenonymous/perl-term-fabulous.git',
				web  => 'https://github.com/davenonymous/perl-term-fabulous',
			},
		},
		dynamic_config => 0,
		provides       => collectProvides(),

		# The maintainer tools in tools/ (make docs, make docs-check,
		# tools/tidy) and perlcritic.
		prereqs => {

			# Term::Fabulous::Widget::Image draws pictures with Imager
			# and shows a notice in their place without it;
			# Term::Fabulous::Widget::Sixel shows pictures in sixel
			# graphics with Imager::File::SIXEL and a notice without it.
			runtime => {
				recommends => { 'Imager' => '0', 'Imager::File::SIXEL' => '0' },
			},
			develop => {
				requires   => { 'IO::Pty' => '0', 'JSON::PP' => '0', 'Perl::Critic' => '0', 'Perl::Tidy' => '20250214', 'Pod::Markdown' => '0' },
				recommends => { 'Imager'  => '0', 'Imager::File::SIXEL' => '0' },
			},
		},

		# The example programs and the documentation tools contain
		# packages (My::Panel, Term::Fabulous::Screenshot::*) that are
		# not part of the installed distribution.
		no_index => { directory => [qw(examples tools screenshots)] },
	},
	EXE_FILES => ['bin/fabulous-theme-editor'],
	test      => { TESTS => 't/*.t' },
	clean     => { FILES => 'Term-Fabulous-* lib/Term/Fabulous/Termbox.c lib/Term/Fabulous/Termbox.o lib/Term/Fabulous/Termbox.bs src/*.o' },
);

sub MY::postamble {
	return <<'MAKE_FRAG';

# --- termbox2 object --------------------------------------------------
# MakeMaker only knows how to compile C files next to the XS; the
# library lives in src/, so give it the same recipe with -o.

src/%$(OBJ_EXT) : src/%.c src/termbox2.h src/tf_termbox.h
	$(CCCMD) $(CCCDLFLAGS) -I. -Isrc "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) -o $@ $<

lib/Term/Fabulous/Termbox$(OBJ_EXT) : src/termbox2.h src/tf_termbox.h

# --- Markdown pages ---------------------------------------------------
# Usage: make readme
#
# README.md and the pages in docs/ are the pod of every module and pod
# file under lib/ converted with tools/pod2markdown, a Pod::Markdown
# subclass that links the pages to each other's Markdown files, points
# the screenshots to the master branch on GitHub, removes the shared
# indentation of code blocks, fences them with the language set by
# '=for highlighter' and turns tables in 'text' blocks into Markdown
# tables. README.md is shipped and shown on MetaCPAN, docs/ is not (see
# MANIFEST.SKIP). Regenerate them after any pod change.

.PHONY: readme

POD_MARKDOWN_CHECK = $(PERLRUN) -MPod::Markdown -e1 2>/dev/null || { \
	    echo "ERROR: Pod::Markdown is not installed; cpanm Pod::Markdown"; \
	    exit 1; \
	}

readme :
	@$(POD_MARKDOWN_CHECK)
	$(PERLRUN) tools/pod2markdown

# --- Documentation: code blocks and screenshots ----------------------
# Usage: make docs         (after changing an example program)
#        make docs-check   (fails when the documentation is out of date)
#
# tools/update-docs copies the example programs into the POD code blocks
# marked '=for code-from FILE', points the screenshot URLs of the POD to
# the tag of the current $VERSION on GitHub and takes the screenshots
# defined in screenshots/screenshots.kdl again; then README.md and
# docs/ are regenerated. The programs run against blib/, so this
# distribution is built first. See tools/README.md.

.PHONY: docs docs-check

docs : pure_all
	$(FULLPERLRUN) -Mblib tools/update-docs
	$(MAKE) readme

docs-check : pure_all
	$(FULLPERLRUN) -Mblib tools/update-docs --check
	@$(POD_MARKDOWN_CHECK)
	@$(PERLRUN) tools/pod2markdown --check || { \
	    echo "ERROR: the Markdown pages are out of date; run 'make readme' (or 'make docs')."; \
	    exit 1; \
	}

# --- Release target -------------------------------------------------
# Usage: make release
#
# Tests the dist via `make disttest`, builds the tarball via
# `make dist` (disttest alone only creates the unpacked directory),
# then uploads it to CPAN with cpan-upload (from CPAN::Uploader).
# Refuses to run if the git working tree is dirty, if any module's
# $VERSION differs from the one in lib/Term/Fabulous.pm, if a tag
# for the current $(VERSION) already exists, if the documentation's
# code blocks, screenshot URLs, screenshots or Markdown pages are out of
# date (docs-check), or if the GitHub CI run of HEAD has not passed
# (ci-check, which needs gh).
# See RELEASING.md.
#
# disttest and dist run as separate sub-makes on purpose: as
# prerequisites of one target they would share a single distdir
# build, and the tarball would pack the blib/ that disttest left
# behind. PAUSE refuses to index such a tarball.

.PHONY: release release-check ci-check version-check

version-check :
	@perl -ne 'if (/^\s*our \$$VERSION\s*=\s*\x27([^\x27]*)\x27/ && $$1 ne "$(VERSION)") { print "ERROR: $$ARGV has \$$VERSION $$1, expected $(VERSION)\n"; $$failed = 1 } END { exit($$failed ? 1 : 0) }' $$(find lib -name '*.pm')

ci-check :
	@command -v gh >/dev/null 2>&1 || { \
	    echo "ERROR: gh not found in PATH; it reads the CI result of the release commit."; \
	    exit 1; \
	}
	@commit=$$(git rev-parse HEAD) || exit 1; \
	run=$$(gh run list --workflow ci.yml --commit "$$commit" --limit 1 --json status,conclusion --jq '.[] | "\(.status) \(.conclusion)"') || exit 1; \
	case "$$run" in \
	    "completed success") ;; \
	    "") echo "ERROR: no CI run for $$commit; push it and wait for CI first."; exit 1 ;; \
	    "completed "*) echo "ERROR: the CI run for $$commit did not pass ($${run#completed }); see gh run list --commit $$commit."; exit 1 ;; \
	    *) echo "ERROR: the CI run for $$commit has not finished; wait with gh run watch."; exit 1 ;; \
	esac

release-check : version-check docs-check ci-check
	@git diff-index --quiet HEAD -- || { \
	    echo "ERROR: git working tree is dirty; commit or stash first."; \
	    exit 1; \
	}
	@if git rev-parse -q --verify "refs/tags/v$(VERSION)" >/dev/null; then \
	    echo "ERROR: tag v$(VERSION) already exists; bump \$$VERSION in lib/Term/Fabulous.pm and the other modules."; \
	    exit 1; \
	fi
	@command -v cpan-upload >/dev/null 2>&1 || { \
	    echo "ERROR: cpan-upload not found in PATH; cpanm CPAN::Uploader"; \
	    exit 1; \
	}
	@test -r $(HOME)/.pause || { \
	    echo "ERROR: ~/.pause not found; see RELEASING.md for the format."; \
	    exit 1; \
	}

release :: release-check
	$(MAKE) disttest
	$(MAKE) dist
	@test -f $(DISTVNAME).tar.gz || { \
	    echo "ERROR: $(DISTVNAME).tar.gz was not built; refusing to upload."; \
	    exit 1; \
	}
	@if tar tzf $(DISTVNAME).tar.gz | grep -qE '/(blib/|Makefile$$|MYMETA\.|pm_to_blib)'; then \
	    echo "ERROR: $(DISTVNAME).tar.gz contains build artefacts; refusing to upload."; \
	    exit 1; \
	fi
	cpan-upload $(DISTVNAME).tar.gz
	@echo
	@echo "Uploaded $(DISTVNAME).tar.gz to PAUSE."
	@echo "Next:"
	@echo "  git tag -a v$(VERSION) -m 'Release v$(VERSION)'"
	@echo "  git push --follow-tags"
MAKE_FRAG
}
