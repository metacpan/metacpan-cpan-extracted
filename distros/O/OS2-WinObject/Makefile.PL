use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

$def = '-I. -DINCL_BASE -DINCL_PM';
$def .= ' -DnewSVuv=newSViv_uv' if $] < 5.006;

WriteMakefile(
    'NAME'	=> 'OS2::WinObject',
    'VERSION_FROM' => 'WinObject.pm', # finds $VERSION
    'LIBS'	=> [''],   # e.g., '-lm' 
    'DEFINE'	=> $def,     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
);
