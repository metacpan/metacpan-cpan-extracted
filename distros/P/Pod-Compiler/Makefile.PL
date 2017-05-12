# The -*- perl -*- script writes the Makefile for Pod::Compiler

use 5.005;
use ExtUtils::MakeMaker;

# Package details
$AUTHOR       = 'Marek Rouchal <marekr@cpan.org>';
$NAME         = 'Pod::Compiler';
$DISTNAME     = 'Pod-Compiler';
$VERSION_FROM = 'lib/Pod/Compiler.pm';
$ABSTRACT     = 'Converts Perl Pod documentation to object tree, contains podlint and podchecker2';

# executable scripts in this distribution
my %PL_FILES = map { ($a = $_) =~ s/\.PL// ? ($_,$a) : () } glob('scripts/*.PL');

# prerequite modules
my %PREREQ_PM = (
    'Pod::Parser'       => 1.12,
    'Test::Simple'      => 0.44,
    'Tree::DAG_Node'    => 1,
    'Storable'          => 0
);

# Check for required modules
my $missing = 0;
$| = 1;

sub check_module {
  my ($module,$version) = @_;
  print substr("$module ............................",0,30)," ";
  my $file = $module;
  $file =~ s#::#/#g;
  unless(require "$file.pm") {
    print "** FAILED **\n";
	return 0;
  }
  $ver = eval "\$${module}::VERSION";
  #$module->VERSION($version) if defined $version;
  #1;
  unless($ver >= $version) {
    print "** VERSION MISMATCH **\n";
	print "  need at least version $version, have version $ver\n";
	return 0;
  }
  print "ok\n";
  1;
}

print "\nChecking for installed modules\n\n";

for(keys %PREREQ_PM) {
  check_module($_,$PREREQ_PM{$_}) or $missing++;
}

print "\n";
die <<"EDQ" if $missing;
****************************************************************************
You are missing some modules (or particular versions) that are required
for the modules in $NAME
to work correctly. Read the above messages and download any required
modules from http://www.perl.com/CPAN
****************************************************************************

EDQ

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'ABSTRACT'     => $ABSTRACT,
    'AUTHOR'       => $AUTHOR,
    'NAME'         => $NAME,
    'DISTNAME'     => $DISTNAME,
    'PL_FILES'     => \%PL_FILES,
    'EXE_FILES'    => [ values %PL_FILES ],
    'PREREQ_PM'    => \%PREREQ_PM,
    'VERSION_FROM' => $VERSION_FROM, # finds $VERSION
    'clean'        => {FILES => join(' ',values %PL_FILES,'lint.out','lint2.out') },
);

#sub MY::postamble {
#<<"EDQ";
#
#test_full :
#	\$(MAKE) \$(TEST_TYPE) TEST_FILES=t/xtra/*.t
#
#EDQ
#}

