use strict;
use ExtUtils::MakeMaker;

my @exe_files = qw(bin/perldocs);
my %opts = (
            NAME => 'Pod::Perldocs',
            VERSION_FROM => 'lib/Pod/Perldocs.pm',
            EXE_FILES => \@exe_files,
            PL_FILES => {},
	    dist   => {
			 SUFFIX   => 'gz',
			 COMPRESS => 'gzip -9f',
			},
	   );

my $eu_version = $ExtUtils::MakeMaker::VERSION;
if ($eu_version >= 5.43) {
  $opts{ABSTRACT_FROM} = q{lib/Pod/Perldocs.pm};
  $opts{AUTHOR} = 'Randy Kobes <r.kobes@uwinnipeg.ca>';
}
if ($eu_version > 6.11 ) {
  $opts{NO_META} = 1;
}

my %prereqs = ('Pod::Perldoc' => 0,
               'LWP' => 0,
	       );

WriteMakefile( %opts, PREREQ_PM => \%prereqs);

print <<'END';

The supplied test just verifies that the module loads OK.

END
