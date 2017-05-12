use ExtUtils::MakeMaker;
use ExtUtils::F77;

use PDL::LiteF;
use PDL::Core::Dev;

( my $NCARG_ROOT = $ENV{NCARG_ROOT} )
or die "
Please set the environment variable NCARG_ROOT to the installation path of 
your NCAR distribution, and rerun perl Makefile.PL.

";

open AUTO_INCLUDE, ">pdl_auto_include.h";
print AUTO_INCLUDE &PDL_AUTO_INCLUDE;
close AUTO_INCLUDE;

open BOOT, ">pdl_boot.xsh";
print BOOT "BOOT:\n";
print BOOT &PDL_BOOT;
close BOOT;


my @NCARLIBS = qw( cgm ncarg ncarg_c ncarg_gks ncarg_ras ngmath );

WriteMakefile(
    'ABSTRACT'          => 'XS interface to NCAR graphics libraries',
    'AUTHOR'            => 'Philippe Marguinaud pmarguinaud@hotmail.com',
    'NAME'		=> 'NCAR',
    'VERSION_FROM'	=> 'NCAR.pm',
    'PREREQ_PM'		=> { PDL => '2.3.4' },
    'DEFINE'		=> 'ExtUtils::F77'->trail_()
                         ? '' 
                         : '-DNO_TRAILING_USCORE',
    'INC'		=> join( ' ', 
                             &PDL_INCLUDE,
                             '-I.',
                           ), 
    'TYPEMAPS'          => [ &PDL_TYPEMAP ],
    'LIBS'		=> [
                             join( ' ',
                               "-L$NCARG_ROOT/lib",
                               '-L/usr/X11R6/lib',
                               map( { "-l$_" } @NCARLIBS ),
                               '-lXext',
                               '-lm',
                               'ExtUtils::F77'->runtime(),
                             ),
                           ],
    'OBJECT'            => join( ' ',
                             'NCAR.o', 
                             map( { "$NCARG_ROOT/lib/lib$_.a" } @NCARLIBS ),
                           ),
    'test'              => { TESTS => 'test/*.t' },
    'MYEXTLIB'          => 'user/libuser.a',
);

sub MY::postamble {
'
$(MYEXTLIB): user/Makefile
	cd user && $(MAKE) $(PASSTHRU)
';
}


