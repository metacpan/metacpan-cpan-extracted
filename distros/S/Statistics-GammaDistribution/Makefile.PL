use ExtUtils::MakeMaker;
use strict;

my $PACKAGE = 'Statistics::GammaDistribution';
(my $PACKAGE_FILE = $PACKAGE) =~ s|::|/|g;
my $LAST_API_CHANGE = 0.01;
my $CURR_VERSION;
eval "require $PACKAGE;\n\$CURR_VERSION = \$$PACKAGE"."::VERSION;";

unless ($@) { # Make sure we did find the module.
    if( $CURR_VERSION < $LAST_API_CHANGE ) {
        print "-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-\n".
	    "NOTE: There have been API changes between this version and any older\n".
	    "      than version $LAST_API_CHANGE! It seems that you have a copy\n".
	    "      of this software installed with a version number of $CURR_VERSION.\n".
	    "      Please read the CHANGES file if you have been building software\n".
	    "      that relies on a previous version of this software.\n".
	    "-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-!-\n";
        sleep 5;
    }
}

WriteMakefile(
	      NAME            => $PACKAGE,
	      VERSION_FROM    => "lib/$PACKAGE_FILE.pm", # finds $VERSION
	      PREREQ_PM       => {
		  },
	      AUTHOR          => 'Nigel Wetters Gourlay <nwetters@cpan.org>',
	      ABSTRACT_FROM   => "lib/$PACKAGE_FILE.pm"
	      );

