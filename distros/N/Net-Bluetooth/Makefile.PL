use ExtUtils::MakeMaker;
use Config qw(%Config);
require 5.008;
my $win_include = '"-IC:\\PROGRAM FILES\\MICROSOFT PLATFORM SDK FOR WINDOWS SERVER 2003 R2\\INCLUDE"';
my $lib_path = "";
my $inc_path = "";

print "OS = $Config{osname}\n";

if($Config{osname} =~ /^MSWin/i) {
	print "**ATTENTION!!**\n";
	print "Attempting to build for Windows with the following include path:\n";
	print "$win_include\n";
	print "If this is not the include path for the SP2 SDK, please change the\n";
	print "\$win_include variable in Makefile.PL.\n\n\n";

	$inc_path = $win_include;
	copy_xs("MSWin.xs", "Bluetooth.xs"); 
}

else {
	$lib_path = '-lbluetooth';
	copy_xs("BlueZ.xs", "Bluetooth.xs"); 
}


sub copy_xs {
my $source = shift;
my $dest = shift;

	open(SOURCE, "$source") or die "$! $source\n";
	open(DEST, ">$dest") or die "$! $dest\n";
	@contents = <SOURCE>;
	print DEST @contents;
	close(DEST);
	close(SOURCE);
}

 

WriteMakefile(
    'NAME'	=> 'Net::Bluetooth',
    'VERSION_FROM' => 'Bluetooth.pm', # finds $VERSION
    'LIBS'	=> [$lib_path],   # e.g., '-lm' 
    'DEFINE'	=> $define,     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> $inc_path,     # e.g., '-I/usr/include/other' 
    'clean'     => {FILES => 'Bluetooth.xs'},
    'XSPROTOARG' => '-prototypes' 
);
