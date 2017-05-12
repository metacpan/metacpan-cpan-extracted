# -*- perl -*-

use strict;
use vars qw($DBI_INC_DIR);
require ExtUtils::MakeMaker;

eval { require 5.008 } or die << 'EOD';
#######################################
#	This module requires a minimum Perl version of 5.8.0
#	Please upgrade!
#######################################
EOD

print "\nConfiguring SQL::Preproc ...\n\n";

my %prereq;
my %opts =
    (
    	NAME => 'SQL::Preproc',
     	VERSION_FROM => 'Preproc.pm',
     	dist => { 
	 		DIST_DEFAULT => 'all tardist',
     		SUFFIX => 'gz',
	 		COMPRESS => 'gzip -9vf' 
	 	}
     );

    $opts{AUTHOR} = 'Dean Arnold, Presicient Corp. (darnold@presicient.com)';
    $opts{ABSTRACT} = 'SQL Preprocessor Filter module';
    $opts{PREREQ_PM} = {
    	DBI => 0,
    	'Filter::Simple' => 0
    	};

my $ok = 1;
$ok &&= CheckModule('DBI', '1.42');
$ok &&= CheckModule('Filter::Simple', '0.78');
$ok &&= CheckModule('Text::Balanced', '1.65');

print "DBD::CSV is required to run the test modules;
please install prior to running 'make test'.\n"
	unless CheckModule('DBD::CSV');

print "DBIx::Chart 0.02 and DBD::Chart 0.81 are required to run subclassing tests;
those tests will be skipped.\n"
	unless CheckModule('DBIx::Chart', '0.02') && CheckModule('DBD::Chart', '0.81');

print "DBD::Teradata and SQL::Preproc::Teradata are required to run 
syntax extension tests; those tests will be skipped.\n"
	unless CheckModule('DBD::Teradata') && CheckModule('SQL::Preproc::Teradata');

if (!$ok) {
    print("\n",
	  "Missing modules are available from CPAN:\n",
	  "\thttp://search.cpan.org\n",
	  "\n");
}

ExtUtils::MakeMaker::WriteMakefile(%opts);

sub CheckModule ($$;$) {
    my($module, $version, $package) = @_;
    $package ||= $module;
    $prereq{$module} = $version || 0;
    if ($version) {
		print "Checking for $package, $version or later ... ";
		eval "use $module $version";
		if ($@) {
		    print("\nYou don't have the $package package",
			  " version $version or later, installed.\n");
		    return 0;
		}
    } else {
		print "Checking for $package ... ";
		eval "use $module";
		if ($@) {
		    print("\nYou don't have the $package package installed.\n");
		    return 0;
		}
    }
    print "ok\n";
    return 1;
}

package MY;

sub postamble {
}

sub libscan {
    my($self, $path) = @_;
    ($path =~ /\~$/) ? undef : $path;
}
