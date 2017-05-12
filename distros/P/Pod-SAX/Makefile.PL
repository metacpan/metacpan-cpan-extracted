use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME' => 'Pod::SAX',
    'VERSION_FROM' => 'lib/Pod/SAX.pm',
    'PREREQ_PM' => {
       XML::SAX => 0.10,
       XML::SAX::Writer => 0.39,
       Pod::Parser => 0,
    },
    'ABSTRACT_FROM' => 'lib/Pod/SAX.pm',
    'AUTHOR' => 'Matt Sergeant <matt@sergeant.org>',
    'MAN3PODS' => {"lib/Pod/SAX.pm" => '$(INST_MAN3DIR)/Pod::SAX.$(MAN3EXT)',
                   "pod2axpoint.xsl" => '$(INST_MAN3DIR)/pod2axpoint.xsl.$(MAN3EXT)',
                  },
);

sub MY::postamble {
  q{

pdf: pod2axpoint.pdf
	acroread pod2axpoint.pdf

pod2axpoint.pdf: pod2axpoint.axp
	axpoint pod2axpoint.axp pod2axpoint.pdf

pod2axpoint.axp: pod2axpoint.xsl pod2axpoint.pod.xml
	xsltproc pod2axpoint.xsl pod2axpoint.pod.xml > $@

pod2axpoint.pod.xml: pod2axpoint.xsl
	perl -Mblib -e 'use XML::SAX::Writer;use Pod::SAX;' \\
		-e 'my $$source = shift(@ARGV) or die;' \\
		-e 'my $$output = shift (@ARGV) || \*STDOUT;' \\
		-e 'my $$p = Pod::SAX->new({Handler => XML::SAX::Writer->new()});' \\
		-e '$$p->parse_uri($$source);' pod2axpoint.xsl > $@
};
}
