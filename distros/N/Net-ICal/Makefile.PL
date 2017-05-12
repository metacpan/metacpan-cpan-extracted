#!/usr/bin/perl
# -*- Mode: perl -*-

print 
"-------------------------------------------------------------------
Thanks for your interest in Net::ICal. You should know that this
is an ALPHA RELEASE. That means that tests *will fail*. We
know this, and in some cases the failing tests are intentional.
If you want to help us out, please make the tests pass, or 
write tests for existing code, and send the patches to our
developers' mailing list. See the README for more information.

- The Reefknot team (http://reefknot.sf.net)
-------------------------------------------------------------------
";

use ExtUtils::MakeMaker;

# run this on "make dist" to build the BUGS file and
# the detailed changelog.
sub MY::postamble {
	package MY;
	"\npredist: all\n" .
# Commented out for the release of 0.14, since the script that
# generates our BUGS list isn't working. 
#	"\tperl -w ../tools/createBUGS.pl>BUGS\n" .
    "\t../tools/cvs2cl -f ChangeLog.detailed\n" .
	"\t\$(MAKE) tardist\n"
}


WriteMakefile(
		'MAKEFILE'=> 'Makefile',
		'VERSION_FROM' => 'lib/Net/ICal.pm',
		'NAME'    => 'Net::ICal', 
		'PREREQ_PM'  => { # e.g., Module::Name => 1.1
			'Class::MethodMapper' => 1.0,
			'Date::ICal'   => '1.27',
			'Date::Calc'   => '4.3',
            'Test::Simple' => '0.10',
		},
            	dist => {
			COMPRESS     =>'gzip',
			SUFFIX       =>'gz',
			DIST_DEFAULT =>'predist',
		},
	      );

open(MANIFEST, "MANIFEST");
foreach my $file (grep /\.pm$/, <MANIFEST>) {
    chomp $file;
    my($module) = $file =~ m|^lib/(.*)\.pm$|;
    $module =~ s|/|-|g;
    system("pod2test $file t/embedded-$module.t");
}
