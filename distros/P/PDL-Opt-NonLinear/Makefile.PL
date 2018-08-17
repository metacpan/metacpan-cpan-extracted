

use ExtUtils::MakeMaker;
use PDL::Core::Dev;
PDL::Core::Dev->import();
$abort = 0;
BEGIN {

   eval "use ExtUtils::F77";
   if ($@ ne "") {
     warn "\n\tExtUtils::F77 module not found. Will not build PDL::Opt::NonLinear\n\n" ;
     exit(1);
   }
   else {
     $f77 = 'ExtUtils::F77';
   }

   $compiler_available = $f77->testcompiler;

   if (!$compiler_available) {
     warn "\n\n\tNo fortran compiler found. Will not build PDL::Opt::NonLinear on this system\n\n";
     exit(1);
   } 
}

return if $abort;

@pack = (["nonlinear.pd",NonLinear,PDL::Opt::NonLinear]);
@opti_libfiles = map {s/^opti_lib\///; s/\.f$//; $_} glob("opti_lib/*.f");

%hash = pdlpp_stdargs(@::pack);
$hash{INC} .= " -Iopti_lib";  # uncomment as required
$hash{OBJECT} .= " opti_lib/hooke.o opti_lib/asa.o opti_lib/asa_usr.o opti_lib/dhc.o opti_lib/de36.o ";
$fobj = join '', map {" opti_lib/$_.o "} @opti_libfiles;
$hash{OBJECT} .= $fobj; 
$hash{LDFROM} .= " hooke.o asa.o asa_usr.o dhc.o de36.o ".$fobj."NonLinear.o";
$hash{LIBS}[0] .= $f77->runtime ;
$hash{LIBS}[0] .= ' -L/usr/local/lib -lport -lblas' ;
$hash{clean}{FILES} .= " f77_underscore" .
  join '', map {" opti_lib/$_.o "} @opti_libfiles;
$hash{clean}{FILES} .= " hooke.o ";

# Handle multiple compilers

$f2cbased = ($f77->runtime =~ /-lf2c/);
$g2cbased = ($f77->runtime =~ /-lg2c/) unless $f2cbased;
$trail = $f77->trail_;

# Create flag file according to whether or not to use
# underscores (pretty hacky)

unlink("f77_underscore") if -e "f77_underscore";
if ($trail) {
   open OUT, ">f77_underscore" or die "unable to write scratch file";
   close OUT;
}

WriteMakefile(
 %hash,
        'ABSTRACT' => 'Non linear optimization routines for PDL',
        'AUTHOR' => [ 'Gregory Vanuxem <gvanuxem.perl@gmail.com>' ],
        'LICENSE' => 'artistic_2',
 	'VERSION_FROM' => "",   # This is overridden by VERSION_FROM in %hash 
	'CONFIGURE_REQUIRES' =>  { "PDL" => 0, "ExtUtils::F77" => 0,},
	'BUILD_REQUIRES' =>  { "PDL" => 0, "PDL::LinearAlgebra" => 0,},
	'VERSION' => "0.05",
	'PREREQ_PM' => {
	  'PDL' => 0, 
	  'PDL::LinearAlgebra' => 0,
	  }

);

sub MY::postamble {
        $mycompiler     = $f77->compiler();
        $mycflags       = $f77->cflags();#." -ff2c ";
	my $orig = pdlpp_postamble(@::pack);
	$orig =~ s/:\s*nonlinear\.pd/: nonlinear.pd/;
	$orig .join "\n",map {
("
opti_lib/$_\$(OBJ_EXT): opti_lib/$_.f 
	$mycompiler -c -o opti_lib/$_\$(OBJ_EXT) $mycflags -O3 -fPIC opti_lib/$_.f
" )} @opti_libfiles;
 
}
