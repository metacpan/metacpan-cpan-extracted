use 5.008;
use lib 'inc';
use ExtUtils::MakeMaker;
use Devel::CheckLib;

# Check for the dependencies we need to build
check_lib_or_exit( lib => 'pcap', header => 'pcap.h' );
check_lib_or_exit( lib => 'nids', header => 'nids.h' );

# The Debian/Ubuntu/Red Hat packages link libnids to these, so
# assume that we need to as well.  This is not the best way
# to build the module, the ideal fix would be to inspect the 
# linking of libnids.so (e.g. using ldd) and only link to the following
# libs if libnids itself is.
check_lib_or_exit( lib => 'gthread-2.0' );
check_lib_or_exit( lib => 'net' );

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
#
# TODO: If libnids is linked against gthread-2.0, we need to link against
#       it here.  If not, we shouldn't.  The next Devel::CheckLib will
#       have check_lib to accomplish this
WriteMakefile(
    'NAME'		=> 'Net::LibNIDS',
    'ABSTRACT'		=> 'Use the libnids library from Perl',
    'VERSION_FROM'	=> 'LibNIDS.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'MIN_PERL_VERSION'  => '5.008',
    'AUTHOR'     => [ 'Arthur Bergman <abergman@fotango.com>', 'David Cannings <david@edeca.net>' ],
    'LIBS'		=> ['-lnids -lpcap -lgthread-2.0 -lnet'],
    'DEFINE'		=> '', # e.g., '-DHAVE_SOMETHING'
    'INC'		=> '-I.', # e.g., '-I. -I/usr/include/other'
    'LICENSE'		=> 'perl',
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw(NIDS_CLOSE NIDS_DATA NIDS_EXITING NIDS_JUST_EST NIDS_MAJOR
		 NIDS_MINOR NIDS_RESET NIDS_TIMED_OUT));
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Lib::nids',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}
