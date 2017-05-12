use ExtUtils::MakeMaker;
#
my %opts = (
	    'NAME'	   => 'SVG::Metadata',
	    'VERSION_FROM' => "lib/SVG/Metadata.pm",
	    'EXE_FILES' => [ qw( 
				 scripts/cleanup_clipart
				 scripts/package_clipart
				 scripts/retrieve_clipart
				 scripts/svg_annotate
				 scripts/svg_validate
				 scripts/unpack_clipart
				 ) ],
	    'PREREQ_PM' => { 
		'Pod::Usage'     => 1.14,
		'Getopt::Long'   => 2.25,
		'File::Spec'     => 0.82,
		'File::Copy'     => 2.03,
		'File::Find'     => 1.04,
		'File::Path'     => 1.0404,
		'File::Basename' => 2.6,
		'XML::Twig'      => 3.15,  # Tested on 3.09: didn't work.
	    },
	    'EXE_FILES' => [ qw( scripts/svg_validate
				 scripts/svg_annotate ) ],
	    );

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{AUTHOR}   = 'Bryce Harrington <bryce@bryceharrington.org>';
    $opts{ABSTRACT} = 'Parsing and validating RDF metadata in SVG files';
}
 
WriteMakefile( %opts )

