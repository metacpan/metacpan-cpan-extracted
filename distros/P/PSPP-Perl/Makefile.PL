use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.


do 'pspp-module-config' || do {
    my $build = prompt ("Enter the location of the build directory of the configured pspp source:", "" );
    my $src = $top_srcdir;

    %Locations = (SourceDir => "$src", BuildDir => "$build");
};

WriteMakefile(
    FULLPERL          => "PSPP_TEST_CMD=\"$Locations{BuildDir}/src/ui/terminal/pspp -B $Locations{SourceDir}/config\" \$(PERL)",
    NAME              => 'PSPP',
    DISTNAME          => 'PSPP-Perl',
    VERSION_FROM      => "$Locations{BuildDir}/src/libpspp/version.c", 
    PREREQ_PM         => {POSIX=>0}, 
    PM                => {"lib/PSPP.pm", "\$(INST_LIBDIR)/PSPP.pm"},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/PSPP.pm', # retrieve abstract from module
       AUTHOR         => 'John Darrington <john@darrington.wattle.id.au>') : ()),
    INC       => "-I $Locations{SourceDir}  -I $Locations{SourceDir}/src -I $Locations{SourceDir}/gl -I $Locations{BuildDir}/gl -I $Locations{BuildDir}", 
    MYEXTLIB  => "$Locations{BuildDir}/src/.libs/libpspp-core.\$(DLEXT)",
    MAN3PODS  => {"lib/PSPP.pm", "\$(INST_MAN3DIR)/PSPP.3pm",
	    "Examples.pod", "\$(INST_MAN3DIR)/PSPP::Examples.3pm"}
);

if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw());
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'PSPP',
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
