#!/sig/local/bin/perl5 -w

use ExtUtils::MakeMaker;
BEGIN {
  eval {
    require ExtUtils::MM_PRCS;
    import ExtUtils::MM_PRCS;
  };
  if ($@ and $@ =~ /Can\'t locate/) {
    print STDERR 'Ignore "Not a known parameter name" warnings.';
  } elsif ($@) {
    die;
  }
}

WriteMakefile(
# $Format: " PRCS_PROJECT => '$Project$', VERSION => '$ProjectRelease$',"$
 PRCS_PROJECT => 'fam-perl', VERSION => '1.002',
              PREREQ_PM => {
			    File::PathConvert => 0,
			    Pod::Usage => 1,
			    MD5 => 1.7,
			    Getopt::Mixed => 0,
			    File::Basename => 2.5,
#			    VC::Rcs::File => 1.003, # VC-Rcs-1.003
			    IO::File => 0,
			    Data::Dumper => 2.07,
			    autouse => 0
			   },
	      LIBS => [q[-lfam -lC]],
	      NAME => q(SGI::FAM),
	      EXE_FILES => [qw(monitor magicrcs)]
	     );
