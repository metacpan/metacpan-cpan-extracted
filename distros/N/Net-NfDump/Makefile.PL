#use 5.010001;
use 5.000001;
use ExtUtils::MakeMaker;
use POSIX;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::NfDump',
    VERSION_FROM      => 'lib/Net/NfDump.pm', # finds $VERSION
	# require Match::Int64 on 32b. systems
	# require Socket6 on perl older than 5.14.0 
	PREREQ_PM         => { 
			strict => 0, 
			($] < 5.014000 ?  ( Socket6 => 0.15 ) : () ), 
			(ULONG_MAX == 0xFFFFFFFF ? ( Math::Int64 => 0.09 ) : () ),
	},
	# for testing Net::LPM is required (used by nfasnupd)
#	TEST_REQUIRES => { Net::LPM => 1.09 },
    LICENSE           => 'perl',
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Net/NfDump.pm', # retrieve abstract from module
       AUTHOR         => 'Tomas Podermanski <tpoder@cis.vutbr.cz>') : ()
	),
    LIBS              => [ '-lresolv', '-lpthead' ], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I. -I libnf/include', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    OBJECT            => '$(O_FILES)', # link all the C files too
    MYEXTLIB          => 'libnf_perl/libnf_perl$(LIB_EXT)',
    NORECURS          => 0,
	EXE_FILES         => ['bin/nfasnupd'],
	PREOP             => 'make dist-preop',
    clean             => {FILES => "t/*.tmp" },
    realclean         => {FILES => "libnf Net-NfDump-* libnf-*.tar.gz"},
);
if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw());
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Net::NfDump',
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

sub MY::postamble {
'
.NOTPARALLEL:

libnf/configure: 
		# if there is github checkout preffer direct 
		# connection to the libnf source in github via submodule
		if [ -d libnf/nfdump ] ; then (cd libnf && ./prepare-nfdump.sh && cd ..) ; fi 
		# else decompress libnf tar and link 
		(tar xzf libnf-$(VERSION).tar.gz && ln -s libnf-$(VERSION) libnf) || exit 0;
		$(RM_F) libnf/nfdump/bin/nfdump  

#libnf/configure: libnf/prepare-nfdump.sh
#		(cd libnf && ./prepare-nfdump.sh && cd ..) 

libnf/Makefile: libnf/configure 
		(cd libnf && ./configure && cd ..) 

libnf/nfdump/bin/nfdump: 
		@echo "trying to build nfdump..."
		(cd libnf/nfdump && (./bootstrap ; ./configure --enable-nsel) && make && cd ../..) >nfdump.log 2>&1 || exit 0

$(MYEXTLIB): libnf/Makefile libnf_perl/Makefile libnf/nfdump/bin/nfdump
		cd libnf && $(MAKE)
		cd libnf_perl && $(MAKE) $(PASSTHRU)

dist-preop:
		(cd libnf && make dist) 
		cp libnf/ChangeLog Changes
		cp libnf/libnf-*.tar.gz .
		perl -pi -w -e \'s/(libnf-).*(.tar.gz)/libnf-\'$(VERSION)\'.tar.gz/g;\' MANIFEST
';

}

