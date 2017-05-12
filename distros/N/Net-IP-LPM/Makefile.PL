use 5.000000;
use ExtUtils::MakeMaker;
use POSIX;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::IP::LPM',
    VERSION_FROM      => 'lib/Net/IP/LPM.pm', # finds $VERSION
	LICENSE			  => 'perl',
	PREREQ_PM         => {
            strict => 0,
            ($] < 5.014000 ?  ( Socket6 => 0.15 ) : () ),
    },
    PREREQ_PM         => { Socket6 => 0.15 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/IP/LPM.pm', # retrieve abstract from module
       AUTHOR         => 'Tomas Podermanski <tpoder@cis.vutbr.cz>') : ()),

    LIBS              => [ ], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
    # Un-comment this if you add C files to link with later:
    OBJECT            => '$(O_FILES)', # link all the C files too
    #OBJECT            => 'lpm_lib.o', # link all the C files too
    #MYEXTLIB          => 'libnf/libnf$(LIB_EXT)',
    NORECURS          => 0,
    #CCFLAGS			  => '-std=c99 -Wall -pedantic -O3'
    OPTIMIZE		  => '-O3'
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw());
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Net::IP:LPM',
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

