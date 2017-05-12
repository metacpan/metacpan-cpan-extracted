use 5.10.0;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'RDF::Redland::DIG',
    VERSION_FROM      => 'lib/RDF/Redland/DIG.pm', # finds $VERSION
    PREREQ_PM         => {
	'Test::More'                => 0.47,
	'XML::LibXML'               => 1.59,
	'XML::LibXSLT'              => 1.59,
	'RDF::Redland'              => 1.000401,
	'LWP'                       => 5.805,
	'XML::LibXML::XPathContext' => 1.66,
	'Test::Pod'                 => 1.00,
	'Test::Pod::Coverage'       => 1.08,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/RDF/Redland/DIG.pm', # retrieve abstract from module
       AUTHOR         => 'Lara Spendier <lara@apple.com>') : ()),
);

package MY;

sub depend {
    return <<MAKE

dependencies:
	scandeps.pl `grep .pm MANIFEST` `grep bin/ MANIFEST`| grep -v undef

manifesto:
	find lib/ -iname '*.pm' | sort
	find t    -iname '*.t'  | sort

upload:
	cpan-upload-http RDF-Redland-DIG-\$(VERSION).tar.gz

MAKE
}
