use strict;
use warnings;
use ExtUtils::MakeMaker;
use PDL::Core::Dev;

my $libs = $ENV{TALIB_LIBS};
my $cflags = $ENV{TALIB_CFLAGS};

eval { require Alien::TALib };
if ( !$@ ) {
  warn "Using ta-lib via Alien::TALib\n";
  my $alien = Alien::TALib->new;
  $libs   = $alien->libs   if !defined $libs;
  $cflags = $alien->cflags if !defined $cflags;
}
else {
  warn "Alien::TALib not found, trying ta-lib-config\n";
  if (!defined $libs) {
    $libs = `ta-lib-config --libs`;
    $libs =~ s/[\s\n\r]*$//;
    #XXX-HACK fixing broken ta-lib-config output
    $libs .= " -lta_lib" if $libs && $libs !~ /-lta_lib/;
  }

  if (!defined $cflags) {
   $cflags = `ta-lib-config --cflags`;
   $cflags =~ s/[\s\n\r]*$//;
  }
}

unless ($libs) {
  warn "\nERROR: ta-lib not found on your system!\n\n";
  exit 0;
}

warn "Gonna use\n",
     " cflags: '$cflags'\n",
     " libs:   '$libs'\n";

my $package = [qw/TA.pd TA PDL::Finance::TA/];
my %eumm_args = pdlpp_stdargs($package);
$eumm_args{INC} .= " $cflags";
push @{$eumm_args{LIBS}}, $libs;

WriteMakefile(
  %eumm_args,
  VERSION_FROM  => 'TA.pd',
  AUTHOR        => 'KMX <kmx@cpan.org>',
  ABSTRACT      => 'PDL interface to ta-lib library',
  LICENSE       => 'perl',
  PREREQ_PM     => {
        'PDL' => 2.006,
        'Alien::TALib' => 0.06,
  },
  BUILD_REQUIRES     => {
        'PDL' => 2.006,
        'Test::More' => 0,
        'Test::Number::Delta' => 0,
        'Alien::TALib' => 0.06,
  },
  CONFIGURE_REQUIRES => {
        'PDL' => 2.006,
        'Alien::TALib' => 0.06,
  },
  META_MERGE   => {
      resources    => {
          repository   => 'https://github.com/kmx/pdl-finance-ta',
      },
  },
  dist => {
      ($^O eq 'MSWin32' ? (TAR => 'ptar', TARFLAGS => '-c -C -f') : ()),
      PREOP => '$(MKPATH) $(DISTVNAME)/GENERATED'
               . ' && $(PERL) "-MPDL::PP qw[PDL::Finance::TA PDL::Finance::TA $(DISTVNAME)/GENERATED/TA]" TA.pd'
               . ' && $(RM_F) $(DISTVNAME)/GENERATED/*.xs'
               . ' && pod2text $(DISTVNAME)/GENERATED/TA.pm > README'
      },
);

sub MY::postamble {
        pdlpp_postamble($package) . <<'END'

mypod:
	$(PERL) "-MPDL::PP qw/PDL::Finance::TA PDL::Finance::TA TMP/" TA.pd
	perldoc -u TMP.pm > README.pod
	$(RM_F) TMP.pm TMP.xs

END
}
