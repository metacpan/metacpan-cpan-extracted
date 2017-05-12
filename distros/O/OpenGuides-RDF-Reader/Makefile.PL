use strict;
use warnings;
use ExtUtils::MakeMaker;

my %prereq = (
             'Test::Simple' => 0.44,
		     'XML::Simple' => 0,
	     );

my @exe = ();

eval "require OpenGuides";

if ($@) {
    print <<END
The install of the og_mirror script will be skipped as
you don't have a guide installed on your system.

END
}
else {
    print <<END;
You have OpenGuides.pm installed. The script og_mirror will be installed 
into your bin directory, and its prerequisite modules will be added to the list.

END
    push @exe, "scripts/og_mirror";
    $prereq{'WWW::Mechanize'} = 0;
    $prereq{'Pod::Usage'} = 0;
    $prereq{'XML::RSS'} = 0;
    $prereq{'CGI::Wiki::Plugin::Locator::UTM'} = 0.04;
}
    
WriteMakefile(
    NAME         => 'OpenGuides::RDF::Reader',
    VERSION_FROM => 'lib/OpenGuides/RDF/Reader.pm', # finds \$VERSION
    AUTHOR       => 'Ivor Williams (ivorw-openguides@xemaps.com)',
    ABSTRACT     => 'Reader for OpenGuides RDF',
    PREREQ_PM    => \%prereq,
    EXE_FILES	 => \@exe,
);
