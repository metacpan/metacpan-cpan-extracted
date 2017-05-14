package OLE::Storage::Std;
no strict;
my $VERSION=do{my@R=('$Revision: 1.2 $'=~/\d+/g);sprintf"%d."."%d"x$#R,@R};

#
# I decided to put read_* functions here and not in package Storage::Io
# to bind them close to get_* etc. functions...
#

use Exporter;
@ISA = (Exporter);
@EXPORT = qw(
   packpar  basename
   byte     nbyte    get_byte    get_nbyte     read_byte    read_nbyte
   word     nword    get_word    get_nword     read_word    read_nword
   long     nlong    get_long    get_nlong     read_long    read_nlong
   struct            get_struct                             
                     get_str                                
                     get_zstr                               
   wstr     nwstr                                           
                     get_zwstr                              
                     get_rzwstr                              
   real     nreal    get_real    get_nreal     read_real    read_nreal
   double   ndouble  get_double  get_ndouble   read_double  read_ndouble
);

sub B () { "C" }  sub BS () { 1 }
sub W () { "v" }  sub WS () { 2 }
sub L () { "V" }  sub LS () { 4 }
sub R () { "f" }  sub RS () { 4 }
sub D () { "d" }  sub DS () { 8 }

##
## EXPORT functions, will be exported by default.
##

# thing ($number)
sub byte   { pack (B, $_[0]) }
sub word   { pack (W, $_[0]) }
sub long   { pack (L, $_[0]) }
sub real   { pack (R, $_[0]) }
sub double { pack (D, $_[0]) }

# nthing (\@list)
sub nbyte   { pack (B.($#{$_[0]}+1), @{$_[0]}) }
sub nword   { pack (W.($#{$_[0]}+1), @{$_[0]}) }
sub nlong   { pack (L.($#{$_[0]}+1), @{$_[0]}) }
sub nreal   { pack (R.($#{$_[0]}+1), @{$_[0]}) }
sub ndouble { pack (D.($#{$_[0]}+1), @{$_[0]}) }

# struct ($struct, \@list)
sub struct { pack ((packpar($_[0]))[0], @{$_[1]}) }

# $wstr = wstr(perlstr)
sub wstr  { join("\0",split(//, $_[0]))."\0" }		
sub nwstr { map (wstr($_), @_) }

sub packpar {
#
# ($packstr, $varsize) = packpar ($str)
#
   my $str = shift;
   my $F; my $len = 0;
   $F = B(); $len += ($str =~ s/B/$F/g) * BS;
   $F = W(); $len += ($str =~ s/W/$F/g) * WS;
   $F = L(); $len += ($str =~ s/L/$F/g) * LS;
   $F = R(); $len += ($str =~ s/R/$F/g) * RS;
   $F = D(); $len += ($str =~ s/D/$F/g) * DS;
   ($str, $len);
}

# get_thing (\$buf, $offset);
sub get_byte   { get_nbyte(1, @_) }
sub get_word   { get_nword(1, @_) }
sub get_long   { get_nlong(1, @_) }
sub get_real   { get_nreal(1, @_) }
sub get_double { get_ndouble(1, @_) }

# get_nthing ($n, \$buf, $o||\$o);
sub get_nbyte { 
   if (ref($_[2])) {
      ${$_[2]}+=$_[0]*BS; 
      unpack (B."$_[0]", substr(${$_[1]}, ${$_[2]}-$_[0]*BS, $_[0]*BS))
   } else {
      unpack (B."$_[0]", substr(${$_[1]}, $_[2],             $_[0]*BS)) 
   }
}
sub get_nword { 
   if (ref($_[2])) {
      ${$_[2]}+=$_[0]*WS; 
      unpack (W."$_[0]", substr(${$_[1]}, ${$_[2]}-$_[0]*WS, $_[0]*WS)) 
   } else {
      unpack (W."$_[0]", substr(${$_[1]}, $_[2],             $_[0]*WS)) 
   }
}
sub get_nlong { 
   if (ref($_[2])) {
      ${$_[2]}+=$_[0]*LS; 
      unpack (L."$_[0]", substr(${$_[1]}, ${$_[2]}-$_[0]*LS, $_[0]*LS)) 
   } else {
      unpack (L."$_[0]", substr(${$_[1]}, $_[2],             $_[0]*LS)) 
   }
}
sub get_nreal { 
   if (ref($_[2])) {
      ${$_[2]}+=$_[0]*RS; 
      unpack (R."$_[0]", substr(${$_[1]}, ${$_[2]}-$_[0]*RS, $_[0]*RS)) 
   } else {
      unpack (R."$_[0]", substr(${$_[1]}, $_[2],             $_[0]*RS)) 
   }
}
sub get_ndouble { 
   if (ref($_[2])) {
      ${$_[2]}+=$_[0]*DS; 
      unpack (D."$_[0]", substr(${$_[1]}, ${$_[2]}-$_[0]*DS, $_[0]*DS)) 
   } else {
      unpack (D."$_[0]", substr(${$_[1]}, $_[2],             $_[0]*DS)) 
   }
}

# get_struct ($struct, \$buf, $o||\$o)
sub get_struct {
   my @PV = packpar(shift);
   if (ref($_[1])) {
      ${$_[1]} += $PV[1];
      unpack ($PV[0], substr(${$_[0]}, ${$_[1]}-$PV[1], $PV[1]));
   } else {
      unpack ($PV[0], substr(${$_[0]}, $_[1], $PV[1]));
   }
}

# get_str (\$buf, $o||\$o, $len)
sub get_str  { 
   if (ref($_[1])) {
      ${$_[1]}+=$_[2]; 
      substr(${$_[0]}, ${$_[1]}-$_[2], $_[2]) 
   } else {
      substr(${$_[0]}, $_[1],          $_[2]) 
   }
}
sub get_zstr { 
   return "" if !$_[2];
   if (ref($_[1])) {
      ${$_[1]}+=$_[2]; 
      substr(${$_[0]}, ${$_[1]}-$_[2], $_[2]-1)
   } else {
      substr(${$_[0]}, $_[1],          $_[2]-1)
   }
}
sub get_zwstr { 
   return "" if !$_[2];
   if (ref($_[1])) {
      ${$_[1]}+=$_[2]; 
      substr(${$_[0]}, ${$_[1]}-$_[2], $_[2]-2);
   } else {
      substr(${$_[0]}, $_[1],          $_[2]-2);
   }
}
sub get_rzwstr {
   my $tmp = get_zwstr(@_);
   reverse_unicode Unicode::Map ($tmp);
   $tmp;
}

# read_thing ($Io, $offset);
sub read_byte   { read_nbyte(1, @_) }
sub read_word   { read_nword(1, @_) }
sub read_long   { read_nlong(1, @_) }
sub read_real   { read_nreal(1, @_) }
sub read_double { read_ndouble(1, @_) }

# read_thing ($n, $Io, $offset);
sub read_nbyte { 
   my $l=shift; my $b=""; $_[0]->read($_[1], $l*BS, \$b); unpack (B."$l", $b) 
}
sub read_nword { 
   my $l=shift; my $b=""; $_[0]->read($_[1], $l*WS, \$b); unpack (W."$l", $b) 
}
sub read_nlong { 
   my $l=shift; my $b=""; $_[0]->read($_[1], $l*LS, \$b); unpack (L."$l", $b) 
}
sub read_nreal { 
   my $l=shift; my $b=""; $_[0]->read($_[1], $l*RS, \$b); unpack (R."$l", $b) 
}
sub read_ndouble { 
   my $l=shift; my $b=""; $_[0]->read($_[1], $l*DS, \$b); unpack (D."$l", $b) 
}

sub basename {
#
# $basename = basename($filepath)
#
   (substr($_[0], rindex($_[0],'/')+1) =~ /(^[^.]*)/) && $1;
}

"Atomkraft? Nein, danke!"

