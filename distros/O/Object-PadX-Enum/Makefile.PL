use strict;
use warnings;
use ExtUtils::MakeMaker;
use Object::Pad::ExtensionBuilder;
use XS::Parse::Keyword::Builder;

# Both builders only contribute `-I<sharedir>/include` flags via
# extra_compiler_flags. Capture them once at `perl Makefile.PL` time and
# feed them to EUMM through INC.
my $inc = join ' ',
    Object::Pad::ExtensionBuilder->extra_compiler_flags,
    XS::Parse::Keyword::Builder->extra_compiler_flags;

WriteMakefile(
    DISTNAME         => 'Object-PadX-Enum',
    NAME             => 'Object::PadX::Enum',
    VERSION_FROM     => 'lib/Object/PadX/Enum.pm',
    ABSTRACT         => 'syntactic sugar for enum-like singleton-bearing Object::Pad classes',
    AUTHOR           => 'Davenonymous <perl@davenonymous.com>',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.022',

    XSMULTI => 1,
    INC     => $inc,

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'           => '7.12',
        'Object::Pad::ExtensionBuilder' => '0',
        'XS::Parse::Keyword::Builder'   => '0.48',
    },
    BUILD_REQUIRES => {
        'Object::Pad::ExtensionBuilder' => '0',
        'XS::Parse::Keyword::Builder'   => '0.48',
    },
    PREREQ_PM => {
        'Object::Pad'        => '0.825',
        'XS::Parse::Keyword' => '0.48',
        'XSLoader'           => '0',
    },
    TEST_REQUIRES => {
        'Test2::V0' => '0',
    },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            homepage   => 'https://github.com/davenonymous/perl-object-padx-enum',
            bugtracker => { web => 'https://github.com/davenonymous/perl-object-padx-enum/issues' },
            repository => {
                type => 'git',
                url  => 'https://github.com/davenonymous/perl-object-padx-enum.git',
                web  => 'https://github.com/davenonymous/perl-object-padx-enum',
            },
        },
        dynamic_config => 1,
    },
);

sub MY::postamble {
    return <<'MAKE_FRAG';

# --- Release target -------------------------------------------------
# Usage: make release
#
# Builds and tests the dist tarball via `make disttest`, then uploads
# it to CPAN with cpan-upload (from CPAN::Uploader). Refuses to run
# if the git working tree is dirty or if a tag for the current
# $(VERSION) already exists. See RELEASING.md.

.PHONY: release release-check

release-check :
	@git diff-index --quiet HEAD -- || { \
	    echo "ERROR: git working tree is dirty; commit or stash first."; \
	    exit 1; \
	}
	@if git rev-parse -q --verify "refs/tags/v$(VERSION)" >/dev/null; then \
	    echo "ERROR: tag v$(VERSION) already exists; bump \$$VERSION in lib/Object/PadX/Enum.pm."; \
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

release :: release-check disttest
	cpan-upload $(DISTVNAME).tar.gz
	@echo
	@echo "Uploaded $(DISTVNAME).tar.gz to PAUSE."
	@echo "Next:"
	@echo "  git commit -am 'Release v$(VERSION)'"
	@echo "  git tag v$(VERSION)"
	@echo "  git push --follow-tags"
MAKE_FRAG
}
