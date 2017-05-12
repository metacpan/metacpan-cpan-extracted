use strict;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

if (not defined $common::try_libs) {
  $common::try_libs = ' -L/usr/openwin/lib -lX11';
}

my $extra_inc = $common::x ? "-I$common::x/include" : '';

my $loadlibs = $common::loadlibs;
unless (defined $loadlibs) {
  push @INC, '../utils';
  require FindLib;
  $loadlibs = FindLib::findlib( $common::try_libs );
  print "...Found libs: '$loadlibs'\n";
}

unless ($loadlibs =~ /-lX11/) {
  ExtUtils::MakeMaker::WriteEmptyMakefile();
  return;
}

my $cflags = "$common::defines $common::cflags";

# The fix should be in a different place!
$cflags =~ s/-DOS2_IPC\b//;

my $gnuplot_x11_exe = $common::x_exe;

WriteMakefile(
    'NAME'	=> 'Term::Gnuplot::plotx',
    'VERSION_FROM'	=> '../Gnuplot.pm',
    'LIBS'	=> [ $common::try_libs ],
    # ../pm_exec: to include os2/dialogs.h
    'INC'	=> "-I../gnuterm -I../pm_exec -I. $extra_inc",
#    'EXE_FILES'	=> ["$gnuplot_x11_exe\$(EXE_EXT)"],
    'PM'=> {"$gnuplot_x11_exe\$(EXE_EXT)" => "\$(INST_LIBDIR)/$gnuplot_x11_exe\$(EXE_EXT)"},
    'SKIP'	=> [qw( distclean test dist makeaperl xs_o static dynamic_bs
			dynamic_lib linkext manifypods )],
    'DEFINE'	=> $cflags,     # e.g., '-DHAVE_SOMETHING' 
    #'FIXIN'	=> '@$(NOOP)',	# Not a script, an executable...
);

sub MY::postamble {
  my $self = shift;
  my $make_exe = length $Config{exe_ext} ? <<'EOM' : '';
$(GNUPLOT_X11_EXE)$(EXE_EXT): $(GNUPLOT_X11_EXE)

EOM
  $self->{FIXIN} = '@$(NOOP)';	# Does not work...
"GNUPLOT_X11_EXE = $gnuplot_x11_exe" . '

GNUPLOT_X11_OBJECTS = gplt_x11$(OBJ_EXT) getcolor$(OBJ_EXT) stdfn$(OBJ_EXT)

#linkext :: $(LINKTYPE)
linkext ::

manifypods :

test:

static::

' . $make_exe . '

$(GNUPLOT_X11_EXE): $(GNUPLOT_X11_OBJECTS)
	$(CC) $(OPTIMIZE) $(LDFLAGS) -o $@ $(GNUPLOT_X11_OBJECTS) $(LDLOADLIBS)

getcolor$(OBJ_EXT): ../gnuterm/getcolor.c
	$(CCCMD) -DGPLT_X11_MODE $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) -o $@ ../gnuterm/getcolor.c

stdfn$(OBJ_EXT): ../gnuterm/stdfn.c
	$(CCCMD) $(CCCDLFLAGS) -I$(PERL_INC) $(DEFINE) -o $@ ../gnuterm/stdfn.c

';
# The $(CC) business on the link line is not exactly correct...
}
