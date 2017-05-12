use ExtUtils::MakeMaker;

# Compile and install template library.
sub MY::postamble {
	return <<'EOF';
all :: templates_compile

install :: templates_install

clean :: templates_delete_compiled

# This should be a shell loop, but I don't know how portable these Makefiles
# are supposed to be. What it does is find all templates without a
# corresponding .compiled template, and compile them.
templates_compile:
	@echo Compiling templates...
	@$(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" build_scripts/compile_templates.pl
	@echo Done.
	@touch templates_compile

templates_delete_compiled:
	$(RM) templates_compile templates/*.compiled

templates_remove_old:
	$(RM) $(PREFIX)/share/tjava/*

templates_install: templates_remove_old
	@$(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" build_scripts/chmod_templates.pl
	@$(MOD_INSTALL) \
		templates	$(PREFIX)/share/tjava
	@echo ---------------------------------------------------------------------------
	@echo You will want to export TEMPLATEPATH=$(PREFIX)/share/tjava.
	@echo ---------------------------------------------------------------------------
EOF
}

my %opts = (
	NAME		=> 'Template::Plugin::Java',
	VERSION_FROM	=> 'lib/Template/Plugin/Java.pm', # finds $VERSION
	EXE_FILES	=> [ qw( bin/tjava ) ],
	PREREQ_PM	=> {Template => 0, XML::Simple => 0},
	dist		=> {
		COMPRESS => 'gzip -9f',
		SUFFIX   => 'gz'
	},
);

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{ AUTHOR }   = 'Rafael Kitover (caelum@debian.org)';
    $opts{ ABSTRACT } = 
	'Gen Java source from XML and table schemas using templates';
}

WriteMakefile( %opts );
