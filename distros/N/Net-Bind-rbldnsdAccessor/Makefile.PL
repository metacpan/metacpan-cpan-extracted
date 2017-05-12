use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

require './scripts/functions.pl';

my $CAT	= findpath('cat');
my $CD	= 'cd';
my $AR	= findpath('ar');
my $RANLIB = findpath('ranlib');

my $zlib = do 'scripts/get_rbldnsd.pl';
if ($@) {
  print $@;
  exit 0;
}
my $extralibs = ($zlib) ? '' : '-lz';

my $library = 'librbldnsdaccessor.a';
my $libobjects = 'rbldnsdf.o rblf_case.o rblf_name.o';

WriteMakefile(
    'NAME'		=> 'Net::Bind::rbldnsdAccessor',
    'VERSION_FROM'	=> 'rbldnsdAccessor.pm', # finds $VERSION
    'LIBS'		=> [$extralibs],
    'INC'		=> '-Irblndsd',
    'OBJECT'		=> 'rbldnsdAccessor.o '. $library,
    'PREREQ_PM'		=> {
			     'Net::DNS::Codes'	 => '0.09',
			     'Net::DNS::ToolKit' => '0.41',
			   },
    'depend'		=> {
			     'rbldnsdAccessor.o' => 'rbldnsdaccessor.h rbldnsdaccessor.c',
			   },
    'clean'		=> { FILES	=> "*.bs *.o *~ tmp* *.tmp rbldnsdaccessor.h"},
);

sub MY::constants {
  package MY;
  my $inherited = shift->SUPER::constants(@_);
  $inherited .= qq|
AR = $AR
CAT = $CAT
CD = $CD
RANLIB = $RANLIB
SED = $SED
|;
}

sub MY::top_targets {
  package MY;   # add dependencies for .pm and xs files
  my $inherited = shift->SUPER::top_targets(@_);

  $inherited .= q|

rbldnsd/Makefile	: rbldnsd/config.h
	$(NOOP)

rbldnsd/config.h	:
	$(CD) rbldnsd; $(SHELL) configure --without-master-dump --without-stats |. $zlib .q#

#. $library . q|	: |. $libobjects .q| rbldnsd/rbldnsd.a
	-rm -f $@
	$(CP) rbldnsd/rbldnsd.a $@
	$(AR) rv $@ |. $libobjects .q|
	$(RANLIB) $@

rbldnsd/rbldnsd.a : rbldnsd/Makefile rbldnsd/rblf_mem.h
	$(CD) rbldnsd; $(MAKE) rbldnsd.a

rbldnsdf.o	: rbldnsd/Makefile rbldnsdf.c rbldnsdf.h rblf_base.h rblf_isc_result.h rblf_defines.h rbldnsd_import.h
	$(CC) -c $(INC) $(CCFLAGS) $(OPTIMIZE) rbldnsdf.c

rblf_case.o	: rblf_case.c rblf_base.h rblf_name.h
	$(CC) -c $(INC) $(CCFLAGS) $(OPTIMIZE) rblf_case.c

rblf_name.o	: rblf_name.c
	$(CC) -c $(INC) $(CCFLAGS) $(OPTIMIZE) rblf_name.c

rbldnsd/rblf_mem.h	: rblf_mem.h.in
	$(CP) rblf_mem.h.in $@

rbldnsdaccessor.h : rbldnsdaccessor.h.in rblf_mem.h.in
	$(CAT) rbldnsdaccessor.h.in rblf_mem.h.in >> $@

|;
}
