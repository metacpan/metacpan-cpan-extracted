use strict;
use ExtUtils::MakeMaker;
use Config;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

unless ($^O =~ 'os2') {
  ExtUtils::MakeMaker::WriteEmptyMakefile();
  return;
}

if (not defined $common::try_libs) {
  $common::try_libs = ' -L/usr/openwin/lib -lX11';
}

BEGIN {
  push @INC, '../utils';
}
use FindLib;

my $cflags = $common::defines;
$cflags .= ' -DPROTOTYPES';
$cflags .= $common::cflags;

my $gnuplot_pm_exe = $common::pm_exe;

my $ldflags = $Config{ldflags};
$ldflags =~ s/-Zexe\b//;		# not compatible with resources

WriteMakefile(
    'NAME'	=> 'Term::Gnuplot::plotpm',
    'VERSION_FROM'	=> '../Gnuplot.pm',
    'LIBS'	=> [ $common::try_libs ],
		# -I../gnuterm/term to enable ../gpexecute.inc to be included
    'INC'	=> "-I../gnuterm/term -I../gnuterm -Ios2 -I.",     # e.g., '-Idir' 
#    'EXE_FILES'	=> ["$gnuplot_pm_exe.exe"],
    'PM'=> {"$gnuplot_pm_exe.exe" => "\$(INST_LIBDIR)/$gnuplot_pm_exe.exe"},
    'SKIP'	=> [qw( distclean test dist makeaperl xs_o static dynamic_bs
			dynamic_lib linkext manifypods )],
    'DEFINE'	=> $cflags,     # e.g., '-DHAVE_SOMETHING' 
    'LDFLAGS'	=> $ldflags,    # 
    #'FIXIN'	=> '@$(NOOP)',	# Not a script, an executable...
);

sub MY::postamble {
  my $self = shift;
  $self->{FIXIN} = '@$(NOOP)';	# Does not work...
"GNUPLOT_PM_EXE = $gnuplot_pm_exe
" .
'GNUPLOT_PM_OBJ = gclient$(OBJ_EXT) dialogs$(OBJ_EXT) print$(OBJ_EXT) gnupmdrv$(OBJ_EXT) gpexecute$(OBJ_EXT) gnupmdrv.def gnupmdrv.res' .
'

.SUFFIXES: .rc .res

#linkext :: $(LINKTYPE)
linkext ::

manifypods :

test:

static::

# $(GNUPLOT_PM_EXE): $(GNUPLOT_PM_EXE).exe

$(GNUPLOT_PM_EXE).exe: $(GNUPLOT_PM_OBJ)
	$(CC) $(OPTIMIZE) $(LDFLAGS) -o $@ $(GNUPLOT_PM_OBJ) $(LDLOADLIBS) || ( rm $@ && false )

.rc.res: dialogs.h gnuplot.ico
	rc -i os2 -r $*.rc

';
}
