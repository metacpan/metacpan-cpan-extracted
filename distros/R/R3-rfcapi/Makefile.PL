use ExtUtils::MakeMaker;

# change next line if RFCSDK is installed somewhere else on Linux/UNIX
$rfcsdk_dir='/usr/sap/rfcsdk';

# change next line if RFCSDK is installed somewhere else on Windows NT
$rfcsdk_nt='C:\usr\sap\rfcsdk';

# libs depending on UNIX platform
$ljbs='-lrfc';
$ljbs='-lrfc' if $^O eq 'aix';
$ljbs='-lrfc -lsocket -lnsl -ldl -lm -lw' if $^O eq 'solaris';
$ljbs='-lrfc -lsocket -lnsl -ldl -lm -lw' if $^O eq 'sunos';
$ljbs='-lrfc -lcl -ldld' if $^O eq 'hpux';
$ljbs="-lrfc -ldl -lm -lpthread" if $^O eq "linux";

# fix for Linux with rfcsdk 40B
if ($^O eq 'linux' && ! -e "$rfcsdk_dir/lib/librfc.so")
{
	$ljbs="-ldl -lm -lpthread" if $^O eq "linux";
	$xljbs=" $rfcsdk_dir/lib/librfc.a" if $^O eq "linux";
}

if ($^O ne "MSWin32") # Makefile for UNIX
{
	if (-e $rfcsdk_dir)
	{
		$myobj = 'rfcapi.o r3rfc.o r3conn.o ' .
			'r3func.o r3itab.o r3errh.o',
		WriteMakefile(
		'NAME'	=> 'R3::rfcapi',
		'VERSION_FROM' => 'rfcapi.pm', # finds $VERSION
		'LIBS'	=> [$ljbs],
		'LINKTYPE' => 'static',
		'DEFINE' => '',  
		'OBJECT' => $myobj,
		'INC'	=> "-I$rfcsdk_dir/include", 
		'XSOPT' => '-prototypes',
		'MYEXTLIB' => $xljbs,
		);
	}
	else
	{
		print "RFCSDK not found at $rfcsdk_dir.\n";
		print "Install RFCSDK or change Makefile.PL!\n";
	}
}
else # Makefile for Windows NT
{
	if (-e $rfcsdk_nt)
	{
		WriteMakefile(
		'NAME'	=> 'R3::rfcapi',
		'VERSION_FROM' => 'rfcapi.pm', # finds $VERSION
		'DEFINE'	=> '',  
		'OBJECT' => 'rfcapi.o r3rfc.o r3conn.o r3func.o ' .
			'r3itab.o r3errh.o ' .
			$rfcsdk_nt . '\lib\librfc32.lib',
		'INC'	=> "/I$rfcsdk_nt\\include", 
		'XSOPT' => '-prototypes',
		);
	}
	else
	{
		print "RFCSDK not found at $rfcsdk_nt.\n";
		print "Install RFCSDK or change Makefile.PL!\n";
	}
}



