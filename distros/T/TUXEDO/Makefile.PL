use ExtUtils::MakeMaker;

my $os = $^O;

my %opts = (
    NAME         => 'TUXEDO',
    VERSION_FROM => 'TUXEDO.pm',
    'C'          => [ 'TuxedoConstants.c' ],
    'OBJECT'     => 'TuxedoConstants.o TUXEDO.o',
    'INC'        => "-I $ENV{TUXDIR}/include"
);

# --- How shall we link with Tuxedo?
if ( $os eq 'MSWin32' )
{
    $opts{LIBS} = [ "-L$ENV{TUXDIR}/lib -llibtux -llibbuft -llibfml -llibfml32 -llibengine -lwsock32 -lkernel32 -ladvapi32 -luser32 -lgdi32 -lcomdlg32 -lwinspool" ];
    $opts{DEFINE} = "-D__TURBOC__";
}

# -- unix variants..tested on solaris
else
{
    $buildclient_cmd = `buildclient -v 2>/dev/null`;
    @buildclient_options = split( / /, $buildclient_cmd ); 
    @lib_options = grep /-[LlR]/, @buildclient_options;
    $libs = join " ", @lib_options;
    $libs =~ s/\${TUXDIR}/$ENV{TUXDIR}/;
    #print "libs = $libs\n";
    $opts{LIBS} = [ "$libs" ];
}

WriteMakefile( %opts );

=comment
package MY;

sub c_o
{
	".c\$(OBJ_EXT):\n\tbuildclient -w -o \$@ -f \"\$(CCCDLFLAGS) -I\$(PERL_INC) \$(DEFINE) -c \$*.c\"";
}

sub dynamic_lib
{
	my $text;
	$text .= "ARMAYBE = :\n";
	$text .= "OTHERLDFLAGS =\n";
	$text .= "INST_DYNAMIC_DEP =\n";
	$text .= "\n";
	$text .= "\$(INST_DYNAMIC): \$(OBJECT) \$(MYEXTLIB) \$(BOOTSTRAP) \$(INST_ARCHAUTODIR)/.exists \$(EXPORT_LIST) \$(PERL_ARCHIVE) \$(INST_DYNAMIC_DEP)\n";
	$text .= "\tbuildclient -w -o \$@ -f \"\$(LDDLFLAGS) \$(LDFROM) \$(OTHERLDFLAGS) \$(MYEXTLIB) \$(PERL_ARCHIVE) \$(LDLOADLIBS) \$(EXPORT_LIST)\"\n";
	$text .= "\t\$(CHMOD) \$(PERM_RWX) \$@\n";
	$text;
}
=cut

