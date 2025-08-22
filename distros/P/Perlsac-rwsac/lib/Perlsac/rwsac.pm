package Perlsac::rwsac ; 

use strict ;
use warnings ;

our $VERSION = 0.06 ;

our @map ;
$map[0] = "delta" ;
$map[1] = "depmin" ;
$map[2] = "depmax" ;
$map[3] = "unused" ;
$map[4] = "odelta" ;
$map[5] = "b" ;
$map[6] = "e" ;
$map[7] = "o" ;
$map[8] = "a" ;
$map[9] = "internal" ;
$map[10] = "t0" ;
$map[11] = "t1" ;
$map[12] = "t2" ;
$map[13] = "t3" ;
$map[14] = "t4" ;
$map[15] = "t5" ;
$map[16] = "t6" ;
$map[17] = "t7" ;
$map[18] = "t8" ;
$map[19] = "t9" ;
$map[20] = "f" ;
$map[21] = "resp0" ;
$map[22] = "resp1" ;
$map[23] = "resp2" ;
$map[24] = "resp3" ;
$map[25] = "resp4" ;
$map[26] = "resp5" ;
$map[27] = "resp6" ;
$map[28] = "resp7" ;
$map[29] = "resp8" ;
$map[30] = "resp9" ;
$map[31] = "stla" ;
$map[32] = "stlo" ;
$map[33] = "stel" ;
$map[34] = "stdp" ;
$map[35] = "evla" ;
$map[36] = "evlo" ;
$map[37] = "evel" ;
$map[38] = "evdp" ;
$map[39] = "mag" ;
$map[40] = "user0" ;
$map[41] = "user1" ;
$map[42] = "user2" ;
$map[43] = "user3" ;
$map[44] = "user4" ;
$map[45] = "user5" ;
$map[46] = "user6" ;
$map[47] = "user7" ;
$map[48] = "user8" ;
$map[49] = "user9" ;
$map[50] = "dist" ;
$map[51] = "az" ;
$map[52] = "baz" ;
$map[53] = "gcarc" ;
$map[54] = "sb" ;
$map[55] = "sdelta" ;
$map[56] = "depmen" ;
$map[57] = "cmpaz" ;
$map[58] = "cmpinc" ;
$map[59] = "xminimum" ;
$map[60] = "xmaximum" ;
$map[61] = "yminimum" ;
$map[62] = "ymaximum" ;
$map[63] = "adjtm" ;
$map[64] = "unused" ;
$map[65] = "unused" ;
$map[66] = "unused" ;
$map[67] = "unused" ;
$map[68] = "unused" ;
$map[69] = "unused" ;
$map[70] = "nzyear" ;
$map[71] = "nzjday" ;
$map[72] = "nzhour" ;
$map[73] = "nzmin" ;
$map[74] = "nzsec" ;
$map[75] = "nzmsec" ;
$map[76] = "nvhdr" ;
$map[77] = "norid" ;
$map[78] = "nevid" ;
$map[79] = "npts" ;
$map[80] = "nsnpts" ;
$map[81] = "nwfid" ;
$map[82] = "nxsize" ;
$map[83] = "nysize" ;
$map[84] = "unused" ;
$map[85] = "iftype" ;
$map[86] = "idep" ;
$map[87] = "iztype" ;
$map[88] = "unused" ;
$map[89] = "iinst" ;
$map[90] = "istreg" ;
$map[91] = "ievreg" ;
$map[92] = "ievtyp" ;
$map[93] = "iqual" ;
$map[94] = "isynth" ;
$map[95] = "imagtyp" ;
$map[96] = "imagsrc" ;
$map[97] = "ibody" ;
$map[98] = "unused" ;
$map[99] = "unused" ;
$map[100] = "unused" ;
$map[101] = "unused" ;
$map[102] = "unused" ;
$map[103] = "unused" ;
$map[104] = "unused" ;
$map[105] = "leven" ;
$map[106] = "lpspol" ;
$map[107] = "lovrok" ;
$map[108] = "lcalda" ;
$map[109] = "unused" ;
$map[110] = "kstnm" ;
$map[111] = "kevnm" ;
$map[112] = "khole" ;
$map[113] = "ko" ;
$map[114] = "ka" ;
$map[115] = "kt0" ;
$map[116] = "kt1" ;
$map[117] = "kt2" ;
$map[118] = "kt3" ;
$map[119] = "kt4" ;
$map[120] = "kt5" ;
$map[121] = "kt6" ;
$map[122] = "kt7" ;
$map[123] = "kt8" ;
$map[124] = "kt9" ;
$map[125] = "kf" ;
$map[126] = "kuser0" ;
$map[127] = "kuser1" ;
$map[128] = "kuser2" ;
$map[129] = "kcmpnm" ;
$map[130] = "knetwk" ;
$map[131] = "kdatrd" ;
$map[132] = "kinst" ;

sub init {
	my ($b,$npts,$delta)=@_ ;
	my %h ;
	my $n = -1 ;
	my $hname ;
	for (1..70){
		$n++ ;
		$hname = $map[$n] ;
		#print $f pack("f",$h{$hname}) ;
		$h{$hname} = -12345.0 ;
	}
	for (1..40){
		$n++ ;
		$hname = $map[$n] ;
		#print $f pack("i",$h{$hname}) ;
		$h{$hname} = -12345 ;
	}
	for (1..1){
		$n++ ;
		$hname = $map[$n] ;
		#print $f pack("a8",$h{$hname}) ;
		$h{$hname} = "-12345  " ;
	}
	for (1..1){
		$n++ ;
		$hname = $map[$n] ;
		#print $f pack("a16",$h{$hname}) ;
		$h{$hname} = "-12345          " ;
	}
	for (1..21){
		$n++ ;
		$hname = $map[$n] ;
		#print $f pack("a8",$h{$hname}) ;
		$h{$hname} = "-12345  " ;
	}
	#required
	$h{npts} = $npts ;
	$h{nvhdr} = 6 ; #does not work when it is 7. Not sure about the reason.
	$h{b} = $b ;
	$h{e} = $b+$delta*$npts ;
	$h{iftype} = 1 ;
	$h{leven} = 1 ;
	$h{delta} = $delta ;
	for(my $i=0; $i<$npts; $i++){
		$h{d}[$i] = 0.0 ;
	}
	$h{depmax} = 0.0 ;
	$h{depmin} = 0.0 ;
	return %h ;
}

sub rsac {
	my ($fname)=@_ ;
	my $b ;
	open(my $f,"<$fname") or die "cannot open file: $fname\n" ;
	binmode($f) ;
	read($f,$b,158*4) ;
	my @h ;
	#@h = unpack("f70i40a8a16(a8)21",$b) ;
	@h = unpack("f70i40Z8Z16(Z8)21",$b) ;
	my %h ;
	for (my $n=0; $n<=132; $n++){
		$h{$map[$n]} = $h[$n] ;
	}
	read($f,$b,$h{npts}*4) ;
	my @d1 = unpack("f$h{npts}",$b) ;
	my @d2 ;
	my @d3 ; 
	if (2 <= $h{iftype} and $h{iftype} <= 4){
		#1 ITIME {Time series file}
		#2 IRLIM {Spectral file---real and imaginary}
		#3 IAMPH {Spectral file---amplitude and phase}
		#4 IXY {General x versus y data}
		#5 IXYZ {General XYZ (3-D) file}
		read($f,$b,$h{npts}*4) ;
		@d2 = unpack("f$h{npts}",$b) ;
	}
	if ($h{iftype} == 5){
		read($f,$b,$h{npts}*4) ;
		@d3 = unpack("f$h{npts}",$b) ;
	}
	close($f) ;
	$h{d} = [@d1] ;
	$h{d2} = [@d2] ;
	$h{d3} = [@d3] ;
	#my @t ;
	#for (my $n=0; $n<=$h{npts}; $n++){
	#	$t[$n] = $h{b}+$n*$h{delta} ;
	#}
	#$h{t} = [@t] ;
	$h{t} = &calt($h{b},$h{npts},$h{delta}) ;
	return %h ;
}

sub calt {
	my ($b,$npts,$delta)=@_ ;
	my @t ;
	for (my $n=0; $n<$npts; $n++){
		$t[$n] = $b+$n*$delta ;
	}
	return @t ;
}

sub wsac {
	my ($fname,%h)=@_ ;
	my $b ;
	open(my $f,">$fname") or die "cannot open file: $fname\n" ;
	binmode($f) ;
	my $n = -1 ;
	my $hname ;
	for (1..70){
		$n++ ;
		$hname = $map[$n] ;
		print $f pack("f",$h{$hname}) ;
	}
	for (1..40){
		$n++ ;
		$hname = $map[$n] ;
		print $f pack("i",$h{$hname}) ;
	}
	for (1..1){
		$n++ ;
		$hname = $map[$n] ;
		print $f pack("a8",$h{$hname}) ;
	}
	for (1..1){
		$n++ ;
		$hname = $map[$n] ;
		print $f pack("a16",$h{$hname}) ;
	}
	for (1..21){
		$n++ ;
		$hname = $map[$n] ;
		print $f pack("a8",$h{$hname}) ;
	}
	for (1..$h{npts}){
		print $f pack("f",$h{d}[$_-1]) ;
	}
	if (2 <= $h{iftype} and $h{iftype} <= 4){
		for (1..$h{npts}){
			print $f pack("f",$h{d2}[$_-1]) ;
		}
	}
	if ($h{iftype} == 5){
		for (1..$h{npts}){
			print $f pack("f",$h{d3}[$_-1]) ;
		}
	}
	close($f) ;
	return 1 ;
}


=head1 NAME

Perlsac::rwsac - a module to read and write SAC file.

=head1 DESCRIPTION

This is the module for reading and writing the sac file, defined 
at 'http://ds.iris.edu/files/sac-manual/manual/file_format.html'

=head1 AUTHOR

Hobin Lim

=head1 LICENSE

MIT

=head1 INSTALLATION

Using C<cpan>:

    cpan install Perlsac::rwsac

Manual install:

    perl Makefile.PL
    make
    make install

=head1 TUTORIALS

1. Printing out time and data.

    #!/usr/bin/env perl
    
    use strict ;
    use warnings ;
    use Perlsac::rwsac ;
    
    my %h = Perlsac::rwsac::rsac("example.sac") ;

		my $b = $h{b} ;
		my $npts = $h{npts} ;
		my $delta = $h{delta} ;

		my @t = Perlsac::rwsac::calt($b,$npts,$delta) ;
   
    for (my $n=0; $n<$h{npts}; $n++){
        print "$t[$n] $h{d}[$n]\n" ;
    }

2. Dividing data by 'depmax' in headers and writing a new sac file.

    #!/usr/bin/env perl
    
    use strict ;
    use warnings ;
    use Perlsac::rwsac ;
    
    my %h = Perlsac::rwsac::rsac("example.sac") ;
    
    for (my $n=0; $n<$h{npts}; $n++){
        $h{d}[$n] /= $h{depmax} ;
    }
    
    &Perlsac::rwsac::wsac("example.sac.div",%h) ;

3. Making a synthetic triangle-shaped waveform.

    #!/usr/bin/env perl
    
    use strict ;
    use warnings ;
    use Perlsac::rwsac ;

    my $b = 0.0 ;
    my $npts = 20 ;
    my $delta = 0.1 ;

    my %h = Perlsac::rwsac::init($b, $npts, $delta) ; #b, npts, delta
    #$h{d} are zero-padded.

    my @ys = (
      0,0,0,0,0,
      1,2,3,4,5,
      4,3,2,1,0,
      0,0,0,0,0) ;

    $h{d} = [@ys] ;
   
    &Perlsac::rwsac::wsac('triangle.sac',%h) ;

=head1 Limitations
1. Type of files (IFTYPE and LEVEN) are not be well addressed yet.



=cut

1 ;
