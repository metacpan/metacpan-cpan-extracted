use ExtUtils::MakeMaker;
use ExtUtils::F77;
$Verbose = 1;
$ranlib = 'ranlib';
#$fopt = '-fno-strict-aliasing -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -O2 -Wall -fpic -ggdb';
$fopt = '-D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -O2 -Wall -fpic -ggdb';

@incdirs = ('/usr/include');
@dist = ('EXP',#     Exponential distribution
	 'GAM',#     Gamma distribution
	 'GEV',#     Generalized extreme-value distribution
	 'GLO',#     Generalized logistic distribution
	 'GNO',#     Generalized Normal (lognormal) distribution
	 'GPA',#     Generalized Pareto distribution
	 'GUM',#     Gumbel distribution
	 'KAP',#     Kappa distribution
	 'NOR',#     Normal distribution
	 'PE3',#     Pearson type III distribution
	 'WAK' #     Wakeby distribution
	 );
foreach (@dist) {
    $_ = lc($_);
}
@f_files = ('samlmr.f','samlmu.f','sampwm.f');
foreach (@dist) {
    push @f_files,"cdf$_.f";
    push @f_files,"qua$_.f";
    push @f_files,"lmr$_.f";
    push @f_files,"pel$_.f";
}
%param = ('samlmr','double *x, int n, double *xmom, int nmom, double a, double b',
	  'samlmu','double *x, int n, double *xmom, int nmom',
	  'sampwm','double *x, int n, double *xmom, int nmom, double a, double b, int kind',
	  'cdf','double *x, double *para',
	  'qua','double *f, double *para',
	  'lmr','double *para, double *xmom, int nmom',
	  'pel','double *xmom, double *para');
$make_h = 0;
if ($make_h) {
    foreach (@f_files) {
	$_ =~ s/\.f//;
	$three = substr($_,0,3);
	$three = $_ if $three eq 'sam';
	print "void c$_($param{$three});\n";
	print "extern void $_" . "_();\n\n";
    }
    foreach (@f_files) {
	$_ =~ s/\.f//;
	$three = substr($_,0,3);
	$three = $_ if $three eq 'sam';
	@p = split /,/,$param{$three};
	my @x;
	foreach (@p) {
	    $_ =~ s/^\s+//;
	    my $p = $_;
	    $p =~ s/^double (\*)*//;
	    $p =~ s/^int //;
	    push @x, $p;
	}
	print "void\nc$_(",join(', ',@x),")\n";
	foreach (@p) {
	    print "\t$_\n";
	}
	print "\n";
    }
    # create lmoments.c
    foreach (@f_files) {
	$_ =~ s/\.f//;
	$three = substr($_,0,3);
	$three = $_ if $three eq 'sam';
	print "void c$_($param{$three})\n{\n";
	@p = split /,/,$param{$three};
	my @x;
	foreach (@p) {
	    $_ =~ s/^\s+//;
	    my $p = $_;
	    $p =~ s/^double (\*)*//;
	    $p =~ s/^int //;
	    $p = "&" . $p unless $_ =~ /\*/;
	    push @x, $p;
	}
	print "\t$_","_","(",join(', ',@x),");\n}\n\n";
    }
    exit;
}
@c_files = ('lmoments.c');

$incs = '';
foreach (@incdirs) {
    $incs .= " -I$_";
}
push @f_files,('digamd.f','quastn.f','gamind.f','dlgama.f');
$f77 = ExtUtils::F77->compiler;
$fo_files = $f_files = join(' ',@f_files);
$co_files = $c_files = join(' ',@c_files);
$fo_files =~ s/\.f/.o/g;
$co_files =~ s/\.c/.o/g;

WriteMakefile(
	      NAME      => 'Statistics::Lmoments::lmoments',
	      INC	=> $incs,
	      DEFINE    => '-ggdb -Wall',
	      clean     => {'FILES' => 'libclmoments$(LIB_EXT) liblmoments$(LIB_EXT)'},
	      );

sub MY::top_targets {
'
pure_all ::

all :: static

static :: libclmoments$(LIB_EXT) liblmoments$(LIB_EXT)

%.o : %.f
	' . $f77 . ' -c ' . ' ' . $inc  . ' ' . $fopt . ' $< -o $@

liblmoments$(LIB_EXT): ' . $f_files . ' ' . $fo_files . '
	$(AR) cr liblmoments$(LIB_EXT) ' . $fo_files . '
	' . $ranlib . ' liblmoments$(LIB_EXT)

libclmoments$(LIB_EXT): ' . $c_files . ' ' . $co_files . '
	$(AR) cr libclmoments$(LIB_EXT) ' . $co_files . '
	' . $ranlib . ' libclmoments$(LIB_EXT)
';
}
