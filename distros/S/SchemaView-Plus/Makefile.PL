# BEGIN { $^W = 1 }
BEGIN { require 5.003 }

use ExtUtils::MakeMaker;
use strict;

use FindBin;

# Some MakeMaker's forged some FileHandle methods
require FileHandle unless defined(&FileHandle::new);

eval 'use DBI';
if ($@) {
	print <<EOF;
You do not seem to have DBI installed, so you will not be able to use
retrieve and update database functions for SchemaView.
EOF
} elsif (eval ' $DBI::VERSION < 1.12 ') {
	print <<EOF;
You have the DBI module, but it's the old version. Upgrade to at least 1.12
to use this with SchemaView.
EOF
}

eval 'use Tk';
if ($@) {
	print <<EOF;
You do not seem to have Tk installed, so you will not be able to use this
software. Install Perl/Tk at least 800.014 version.
EOF
} elsif (eval ' $Tk::VERSION < 800.014 ') {
	print <<EOF;
You have the Tk module, but it's the old version. Upgrade to at least 800.014
to use this with SchemaView.
EOF
}

eval 'use XML::Dumper';
if ($@) {
	print <<EOF;
You do not seem to have XML::Dumper installed, so you will not be able to use
open and save functions of this software. Install XML::Dumper at least 0.4
version.
EOF
} elsif (eval ' $XML::Dumper::VERSION < 0.4 ') {
	print <<EOF;
You have the XML::Dumper module, but it's the old version. Upgrade to at
least 0.4 to use this with SchemaView.
EOF
}

my %opts = (
	NAME => 'SchemaView-Plus',
	DISTNAME => 'SchemaView-Plus',
	VERSION_FROM => 'bin/svplus',
	EXE_FILES => [ "bin/svplus" ],
	dist => { DIST_DEFAULT => 'tardist',
		  COMPRESS => 'gzip -9vf', SUFFIX => 'gz',
		  POSTOP => 'mv $(DISTNAME)-$(VERSION).tar.gz ../',
		},
);

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
	$opts{AUTHOR} = 'Milan Sorm (sorm@milansorm.cz)';
	$opts{ABSTRACT} = 'Retrieve, drawing and printing database schema';
	$opts{PREREQ_PM} = { DBI => '1.12', Tk => 800.014, 'XML::Parser' => 0,
		'XML::Dumper' => '0.4', FindBin => 0, 'Tk::MListbox' => 0,
		'Tk::ProgressBar' => 0, 'Tk::FontDialog' => 0, 'Data::CompactDump' => 0,
		'Math::Project' => 0 };
}

ExtUtils::MakeMaker::WriteMakefile(%opts);

print <<EOF;
+----------------------------------------+
| For using and documentation please run |
|                                        |
|               svplus                   |
|                                        |
| and try use Help -> Hints.             |
+----------------------------------------+
EOF

exit 0;

package MY;

__END__

