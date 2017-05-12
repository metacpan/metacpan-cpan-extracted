use 5.000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'SGML::DTDParse',
    ABSTRACT	      => 'Parse SGML and XML DTDs',
    VERSION_FROM      => 'lib/SGML/DTDParse.pm',
    PREREQ_PM         => {
	Text::DelimMatch => 1.05,
	XML::Parser      => 2.25,
	XML::DOM         => 1.43,
	Getopt::Long	 => 0,
    },
    EXE_FILES	      => [qw(
	bin/dtddiff
	bin/dtddiff2html
	bin/dtdflatten
	bin/dtdformat
	bin/dtdparse
    )],
    PMLIBDIRS	      => [ 'lib' ],

    'dist'	      => {
	COMPRESS => 'gzip -9f',
	SUFFIX => 'gz',
    },
);

package MY;

# Add removal of HTML docs to clean target
sub clean {
    my $inherited = shift->SUPER::clean(@_);
    $inherited .= "\t".'$(RM_RF) doc/pod2htm* doc/html example'."\n";
    $inherited;
}

# Create htmldoc target
sub postamble {
    return <<EOT;
MKPATH=\$(PERL) -MExtUtils::Command -e mkpath

htmldoc: _FORCE
	\@echo "Generating HTML docs in docs/html..."
	-\$(MKPATH) doc/html
	\$(PERL) etc/gen-html-doc.pl \\
	    --inroot . \\
	    --outroot doc/html \\
	    --cachedir doc \\
	    --poddir bin \\
	    --poddir lib

example: _FORCE
	-\$(MKPATH) example/dtdparse-dtd \\
	            example/dtdparse-dtd/html \\
	            example/dtdparse-dtd/refentry
	PERL5LIB=lib \$(PERL) bin/dtdparse \\
	    --public-id "-//Norman Walsh//DTD DTDParse V2.0//EN" \\
	    --system-id dtd.dtd \\
	    --title "DTDParse XML DTD" \\
	    --xml \\
	    --output example/dtdparse-dtd/dtd.xml \\
	    etc/dtd.dtd
	PERL5LIB=lib \$(PERL) bin/dtdformat \\
	    --base-dir example/dtdparse-dtd/html \\
	    --html \\
	    example/dtdparse-dtd/dtd.xml
	PERL5LIB=lib \$(PERL) bin/dtdformat \\
	    --base-dir example/dtdparse-dtd/refentry \\
	    --refentry \\
	    example/dtdparse-dtd/dtd.xml

_FORCE:

EOT
}
