use strict;
use warnings;
use ExtUtils::MakeMaker;

my @podpms = map { $_.".pod", '$(INST_LIBDIR)/' . $_ .".pod"} qw/pdla2/;

# Make sure we have the PDLA CONFIG hash loaded, and try to load it
# from perldl.conf if not.
use File::Spec;
unless (%PDLA::Config) {
	our %PDLA_CONFIG;
	do File::Spec->catfile('..', 'perldl.conf') ;
	%PDLA::Config = %PDLA_CONFIG;
}

# Extra build target to build the doc database
undef &MY::postamble; # suppress warning
*MY::postamble = sub {
   my  $text = '';

   $text .= << "EOPS" ;

pdla2.pod : pdla2
\t\$(PERLRUN) -MPod::Select -e "podselect('pdla2');" > pdla2.pod

EOPS

   return $text;

};

if (!defined $PDLA::Config{WITH_DEVEL_REPL}) {
   if (eval 'require Devel::REPL;') {
      # Only generate Makefile if we have Devel::REPL
      WriteMakefile(
         'NAME' => 'PDLA::Perldl2',
         'VERSION' => '2.000',
         'EXE_FILES' => [ 'pdla2' ],
         'DIR' => [ qw(Profile Plugin) ],
         'PM' => { 'Script.pm' => '$(INST_LIBDIR)/Perldl2/Script.pm', @podpms },
	  (eval ($ExtUtils::MakeMaker::VERSION) >= 6.57_02 ? ('NO_MYMETA' => 1) : ()),
      );
   } else {
      # Devel::REPL was not found
      $PDLA::Config{WITH_DEVEL_REPL} = 0;
      my $msg = "Devel::REPL is not installed, will not build Perldl2 shell";
      write_dummy_make($msg);
   }
}
elsif ($PDLA::Config{WITH_DEVEL_REPL}) {
  # They want it, so make it
  WriteMakefile(
	 'NAME' => 'PDLA::Perldl2',
	 'VERSION' => '2.000',
	 'EXE_FILES' => [ 'pdla2' ],
	 'DIR' => [ qw(Profile Plugin) ],
         'PM' => { 'Script.pm' => '$(INST_LIBDIR)/Perldl2/Script.pm', @podpms },
         clean => { FILES => 'pdla2.pod' },
         (eval ($ExtUtils::MakeMaker::VERSION) >= 6.57_02 ? ('NO_MYMETA' => 1) : ()),
  );
}
else {
	# they don't want it, so generate a dummy
	write_dummy_make('Not making or installing Perldl2 shell, per configuration');
}
