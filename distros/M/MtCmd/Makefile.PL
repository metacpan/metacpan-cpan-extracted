##########################################################################
#                                                                        #
# © Copyright IBM Corporation 2001, 2006. All rights reserved.           #
#                                                                        #
# This program and the accompanying materials are made available under   #
# the terms of the Common Public License v1.0 which accompanies this     #
# distribution, and is also available at http://www.opensource.org       #
# Contributors:                                                          #
#                                                                        #
# William Spurlin - Initial version and framework                        #
#                                                                        #
# Xue-Dong Chen - Maintenance and defect fixes                           #
#                                                                        #
##########################################################################

use ExtUtils::MakeMaker;
use Config;

# To override ExtUtils::MM_Unix methods:
# Win32C_O (for MY::c_o).  Including these subs inline
# results in their evaluation at compile time and prohibits platform-selective
# overriding of these methods.
# "use" will not work here as it has an implicit "BEGIN".

my $archlib=$Config{archlib};
my $name=ClearCase::MtCmd;
my $inst_lib=$archlib.'/auto/'.$name;
my $ATRIA_ROOT=$ENV{ATRIA_ROOT}?$ENV{ATRIA_ROOT}:"/usr/atria"; 
my $cleartool = $ATRIA_ROOT.'/bin/cleartool';
my $osver;

$os=$Config{osname};  #why not $^O ?

my %opts = (
	    'NAME'	=> $name,
	    'VERSION_FROM' => 'MtCmd.pm', # finds $VERSION
	    'LIBS' =>' -L. -L'.$ATRIA_ROOT.'/shlib -latriacmdsyn  -latriacmd -latriasumcmd -latriasum -latriamsadm -latriamntrpc -latriacm -latriavob -latriaview -latriacm -latriadbrpc -latriatirpc -latriaxdr -latriamvfs -latriatbs -latriaadm -latriasplit -latriacredmap -latriaks  -lezrpc  -lrpcsvc  -latriaccfs -latriasquidad  -latriasquidcore -latriams_cmdsyn -latriams_cmd'
	    );


if ($os =~ /solaris/){
	my($esp_str,$esp_ver,$flag_rd);
	my $default_compiler = $Config{cc};	
    if( $default_compiler =~ /gcc/ || $ENV{CC_MtCmd_GCC}){
	$default_compiler = "gcc";
	$opts{CC} = $default_compiler;
	$opts{LD} = $default_compiler;
	$opts{OPTIMIZE} = '-O';
	$esp_str="gcc version";
	$esp_ver=2.7;
	$flag_rd = ' -v 2>&1';
    }elsif($default_compiler =~ /cc/){
	$esp_str=/"WorkShop Compilers"|Sun/;
	$esp_ver=4.2;
	$flag_rd = ' -V 2>&1';
    }else{
	die 'No default compiler';
    }
    if(-e '/usr/lib/libCrun.so.1'){
       if(!-e 'libCrun.so'){
	   if (!symlink('/usr/lib/libCrun.so.1','libCrun.so')){
	       die "/usr/lib/libCrun.so.1: $!";
	   }
       }
    }else{
	die 'No libCrun.so.1 exist on the lib path';
    }
    die 'Cannot find  '.$default_compiler.' -> Sun Workshop Compilers 5.0 or gcc'  
	unless CheckVer($esp_str,
			$esp_ver,
			$default_compiler.$flag_rd
			);
    die "Cannot find ClearCase 7.0 or higher or cannot find $cleartool" 
	unless $ctver = CheckVer('ClearCase version',
			7.0,
			$cleartool.' -ver',
			1
			);
    die "MtCmd requires Solaris 2.8 or higher"
	unless CheckVer("SunOS",
			5.8,
			'uname -sr'
			);
    $opts{LDDLFLAGS} = ' -L. -G -L/usr/lib -L/usr/ccs/lib ';
    $opts{LIBS} ="-L/usr/lib ". $opts{LIBS}.'  -lc  -lw -lCrun'." -R$ATRIA_ROOT/shlib";
    $opts{DEFINE}	= $opts{DEFINE}.'-DSVR4';
    $opts{INC}	= '-I. ';
    $opts{dynamic_lib} = { OTHERLDFLAGS => '-Lblib/arch/auto/ClearCase/MtCmd -t -ucmdsyn_proc_table  -R$(ATRIA_ROOT)/shlib  -R$(INSTALLSITEARCH)/auto/$(FULLEXT)  -R$(INSTALLSITELIB)/auto/$(FULLEXT) -R$(INST_ARCHLIB)/auto/$(FULLEXT) '} ;
}elsif ($os =~ /linux/){
    $opts{LD} = "ld";
    die 'Cannot find  '.$Config{cc}  
	unless CheckVer('version',
			2.7,
			$Config{cc}.' -v 2>&1'
			) ||
	       CheckVer('version egcs-',
			2.7,$Config{cc}.' -v 2>&1'
		       );
    die "Cannot find ClearCase 7.0 or higher or cannot find $cleartool" 
	unless $ctver = CheckVer('ClearCase version',
			7.0,
			$cleartool.' -ver',1
			);
    $opts{DEFINE}= $opts{DEFINE}.'-DATRIA_LINUX';
    $opts{INC}='-I. ';
    $opts{LIBS} ="-L/usr/lib ". $opts{LIBS}.' -lc -lcurses'; 
    if ($Config{perl} =~ /ratlperl/) {
    $opts{dynamic_lib}={ OTHERLDFLAGS => 
			     ' -ucmdsyn_proc_table -Wl,-rpath,'.
			      $ATRIA_ROOT.
			      '/shlib:.:'.
			       $inst_lib
		       };
    } else {
    $opts{dynamic_lib}={ OTHERLDFLAGS => 
                             ' -ucmdsyn_proc_table -rpath '.
                              $ATRIA_ROOT.
                              '/shlib:.:'.
                               $inst_lib
                       };
    }

}elsif  ($os =~ /hpux/){

    $ctver = CheckVer(
				       'ClearCase version',
				       7.0,
				       $cleartool.' -ver',
				       1
				       );
    die "Cannot find ClearCase 7.0 or higher or cannot find $cleartool" 
	unless $ctver;
    $osver = `uname -r`;chomp $osver;
    $osver =~ s/^[A-Z]\.//;print "OSVER $osver\n";
    $opts{LIBS} ="-L/usr/lib ". $opts{LIBS}.' -lperl -lperlDynaLoader ' if $ctver < 5;
    if ($osver == 10.20){
	print "HPUX-10.20\n";
	$opts{LIBS} =  $opts{LIBS}.'-lcurses -lM -lezrpc  -lrpcsvc -lsec -lstd -lstream -lcl -lc   -ldld ';
	$opts{DEFINE}= $opts{DEFINE}.'-DATRIA_HPUX10';
	$opts{dynamic_lib}={ OTHERLDFLAGS => ' +b: -E -lCsup'};
    }elsif(11 <= $osver ){
	print "HPUX-11\n";
        if ($Config{perl} =~ /ratlperl/) {
            $opts{LIBS} = "-L/usr/lib ". $opts{LIBS}.'-lcurses -lrpcsvc -lHcurses ';
        }else{
        $opts{LIBS} =  $opts{LIBS}.'-lcurses -lrpcsvc -lHcurses ';
        $opts{dynamic_lib}={ OTHERLDFLAGS => ' +b: -E -l:libcl.0  -l:libc.0 '};
        }
    }else{
    }    

}elsif  ($os =~ /MSWin32/ || $os =~ /Windows/){
    die 
	'Cannot find  '
	.$Config{cc}.
	' -> Microsoft (R) 32-bit C/C++ Optimizing Compiler Version 12'  
		unless CheckVer('Version',12,$Config{cc}.' 2>&1' );
    die 
	"Cannot find ClearCase 4.2 or higher or cannot find cleartool in PATH" 
	    unless $ctver = CheckVer(
			    'ClearCase version',
			    4.2,
			    'cleartool -ver',
			    1
			    );
    $opts{CCFLAGS} = $Config{ccflags}.' -DATRIA_WIN32_COMMON';
    $opts{LIBS}='/defaultlib:cmdsyn.lib /defaultlib:ks.lib /defaultlib:vob.lib  "/defaultlib:WS2_32.LIB"';
    $opts{MYEXTLIB}='cmdsyn.lib ks.lib vob.lib';
    $opts{LDDLFLAGS}=$Config{lddlflags};
    $opts{LDDLFLAGS} =~ s/-nodefaultlib//;
    require 'Win32C_O';
}elsif ($os =~ /AIX/i){
    die "Cannot find ClearCase 7.0 or higher or cannot find $cleartool" 
	unless $ctver = CheckVer(
			'ClearCase version',
			7.0,
			$cleartool.
			' -ver',
			1
			);
    $opts{LIBS} = "-L/usr/lib ". $opts{LIBS};
    if ($Config{perl} =~ /ratlperl/) {
    $opts{LDDLFLAGS} = $Config{lddlflags};
    $opts{LDDLFLAGS} =~ s/blibpath:/blibpath:$ATRIA_ROOT\/shlib:/;
    }
}else{print "Unsupported Platform\n"}

$opts{LIBS} .= ' -latriamsadm -latriamsinfobase -latriamsinfovob' if $ctver >= 6;

WriteMakefile(%opts);

sub CheckVer{
    my $expected_string = shift;
    my $level = shift;
    my $prog_output = shift;
    my $trailing = shift;
    $prog_output = `$prog_output`;
    $prog_output =~ /$expected_string\s*(\d+\.\d+\.?\d*)/i;
    $found_level = $1;
    @minversion = split('\.',$level);
    $minversize = @minversion;    
#
# The output of the cleartool -ver command has changed.
# An earlier version looks like 2003.06.00 while a later version
# looks like 7.0.0.   We need to be able to handle both styles. 
# The trailing flag means that the version trails the year so we
# need to remove the year.  That is no longer always true so we
# need to test to see if the year is first, if it is not the we
# have to turn off the trailing flag. 
    if($trailing){
    if($found_level !~ /200/) {
    $trailing = 0;
    }
    }

    if($trailing){
	$found_level =~ s/\d+\.(\d+\.\d+)/$1/;
    }else{
	$found_level =~ s/(\d+\.\d+)\.\d+/$1/;
    }
    @foundversion = split('\.',$found_level);
    $foundversionsize = @foundversion;
    my $ans = Found;
    $ans = 'Not Found' unless $1;
    print "Looking for $expected_string\t$level\t$ans\t$found_level\n";

    if ($minversize >= $foundversionsize){
       $numcompare=$foundversionsize;
    }else{
        $numcompare = $minversize;
    }

    for ($i = 0; $i < $numcompare; $i++)
        {
           if ($foundversion[$i] > $minversion[$i]){
                return  $found_level;
           }else{   
                if ($foundversion[$i] < $minversion[$i]){ 
                   return 0;
                }
           }
     }
     return  $found_level;
}


