# -*- perl -*-

require 5.008;

use strict;
require ExtUtils::MakeMaker;

eval { require 5.008; } or die << 'EOD';
#######################################
#
#	This module requires a minimum Perl version of 5.8.0
#	Please upgrade!
#
#######################################
EOD

use Config;
my @executables = ();
foreach my $src ('pod2classdocs', 'mkprojdocs') {
	open  SCRIPT,       ">$src.pl" or die "Can't create $src.pl: $!";
	open  SOURCE,        "bin/$src" or die "Missing bin/$src";
	chmod 0755,          "$src.pl";
	push @executables, "$src.pl";
	print SCRIPT "$Config{startperl}\n";
	print SCRIPT $_
		while (<SOURCE>);

	close SCRIPT;
	close SOURCE;
}

print '

****

	PPI::HTML::CodeFolder is required if syntax highlighted, code folded
	source code is to be included in the output project documentation.
	If PPI::HTML::CodeFolder is not available, links to source
	code will not be included in any generated project documentation.

****
'
	unless CheckModule('PPI::HTML::CodeFolder', '1.01');

my %opts = (
	NAME => 'Pod::Classdoc',
	VERSION_FROM => 'lib/Pod/Classdoc.pm',
	dist         => {
	 	'DIST_DEFAULT' => 'all tardist',
     	'SUFFIX'       => 'gz',
	 	'COMPRESS'     => 'gzip -9vf'
    },
    EXE_FILES    => \@executables,
    PREREQ_PM     => {
    	'HTML::ListToTree' => '0.10',
    	'Pod::ProjectDocs'  => '0.31',
    	'PPI' => '1.199'
    	},
	AUTHOR       => 'Dean Arnold, Presicient Corp. (darnold@presicient.com)',
	ABSTRACT     => 'javadoc-like class and project documention rendering for Perl',
);

ExtUtils::MakeMaker::WriteMakefile(%opts);

sub CheckModule ($$;$) {
    my($module, $version, $package) = @_;
    $package ||= $module;
    if ($version) {
		print "Checking for $package, $version or later ... ";
		eval "use $module $version";
	    print "\nYou don't have the $package package version $version or later, installed.\n" and
	    return 0
			if $@;
    }
    else {
		print "Checking for $package ... ";
		eval "use $module";
		print "\nYou don't have the $package package installed.\n" and
		return 0
			if $@;
    }
    print "ok\n";
    return 1;
}

