# version  : 1.00 - September 2020
# author   : Thierry LE GALL 
# contact  : facila@gmx.fr

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

package Net::Kalk;

use 5.006;
use strict;
use warnings;

our $VERSION = '1.00';

my @mask = qw ( 0.0.0.0
128.0.0.0       192.0.0.0       224.0.0.0       240.0.0.0       248.0.0.0       252.0.0.0       254.0.0.0       255.0.0.0
255.128.0.0     255.192.0.0     255.224.0.0     255.240.0.0     255.248.0.0     255.252.0.0     255.254.0.0     255.255.0.0
255.255.128.0   255.255.192.0   255.255.224.0   255.255.240.0   255.255.248.0   255.255.252.0   255.255.254.0   255.255.255.0
255.255.255.128 255.255.255.192 255.255.255.224 255.255.255.240 255.255.255.248 255.255.255.252 255.255.255.254 255.255.255.255 );

my $r_format = "%-15s %-15s %-15s %3s %-15s %10s\n";
my $s_format = " %s%-3s  %-15s %-15s   %10s %10s\n";

sub error {
    return 1 if $#_ != 1;
    my ($fct,$x) = @_;
    return 1 if ! defined($x);

    if    ($fct eq 'ip'     ) { return 0 if $x =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/ && $1 < 256 && $2 < 256 && $3 < 256 && $4 < 256 }
    elsif ($fct eq 'mask'   ) { foreach(0..32) { return 0 if $mask[$_] eq $x } }
    elsif ($fct eq 'cidr'   ) { return 0 if $x !~ /\D/ && $x < 33 }
    elsif ($fct eq 'x12'    ) { return 0 if $x =~ /^(\d{3})(\d{3})(\d{3})(\d{3})$/ && $1 < 256 && $2 < 256 && $3 < 256 && $4 < 256 }
    elsif ($fct eq 'decimal') { return 0 if $x !~ /\D/ && $x < 4294967296 }
    elsif ($fct eq 'hexa'   ) { return 0 if $x =~ /^[[:xdigit:]]{2}\.[[:xdigit:]]{2}\.[[:xdigit:]]{2}\.[[:xdigit:]]{2}$/ }
    elsif ($fct eq 'binary' ) { return 0 if $x =~ /^[01]{8}\.[01]{8}\.[01]{8}\.[01]{8}$/ }

    return 1 }

sub plus  { &local_oper('plus' ,@_) }
sub minus { &local_oper('minus',@_) }

sub local_oper {
    return if $#_ != 2;
    my ($fct,$x,$ip) = @_;
    return if $x =~ /\D/;
    return if &error('ip',$ip);

    $ip = &decimal('ip',$ip);
    if    ($fct eq 'plus' ) { $ip += $x }
    elsif ($fct eq 'minus') { $ip -= $x }
    $ip = &ip('decimal',$ip); 
    return $ip if ! &error('ip',$ip) }

sub invers {
    return if $#_ != 0;
    my ($ip) = @_;
    return if &error('ip',$ip);

    my ($a,$b,$c,$d) = split /\./,$ip;
    $a=255-$a; $b=255-$b; $c=255-$c; $d=255-$d; 
    return "$a.$b.$c.$d";
    }

sub mask {
    return if $#_ != 0;
    my ($x) = @_;
    foreach(0..32) {
       return $mask[$_] if $x eq $_;
       return $_        if $x eq $mask[$_] } } 

sub x12     { &local_dst_no_ip('x12'    ,@_) }
sub decimal { &local_dst_no_ip('decimal',@_) }
sub hexa    { &local_dst_no_ip('hexa'   ,@_) }
sub binary  { &local_dst_no_ip('binary' ,@_) }

sub local_dst_no_ip {
    return if $#_ != 2;
    my ($dst,$src,$ip) = @_;

    $ip = &ip($src,$ip) if $src ne 'ip' ;
    return if &error('ip',$ip);

    my ($a,$b,$c,$d) = split /\./,$ip;
    if    ( $dst eq 'hexa'    ) { return sprintf "%02X.%02X.%02X.%02X" ,$a,$b,$c,$d }
    elsif ( $dst eq 'binary'  ) { return sprintf "%.8b.%.8b.%.8b.%.8b" ,$a,$b,$c,$d }
    elsif ( $dst eq 'x12'     ) { return sprintf "%03d%03d%03d%03d"    ,$a,$b,$c,$d }
    elsif ( $dst eq 'decimal' ) { return $a*2**24 + $b*2**16 + $c*2**8 + $d } }

sub ip {
    return if $#_ != 1;
    my ($src,$add) = @_;

    return if $src eq 'ip';
    return if &error($src,$add);

    my ($ip,$a,$b,$c,$d);
    ($a,$b,$c,$d) = split /\./,$add if $src =~ /hexa|binary/; 
    if    ( $src eq 'x12'     ) { $ip = sprintf "%d.%d.%d.%d" ,$1,$2,$3,$4 if $add =~ /^(\d\d\d)(\d\d\d)(\d\d\d)(\d\d\d)$/ }
    elsif ( $src eq 'hexa'    ) { $ip = sprintf "%d.%d.%d.%d" ,oct("0x$a"),oct("0x$b"),oct("0x$c"),oct("0x$d") }
    elsif ( $src eq 'binary'  ) { $ip = sprintf "%d.%d.%d.%d" ,oct("0b$a"),oct("0b$b"),oct("0b$c"),oct("0b$d") }
    elsif ( $src eq 'decimal' ) {
       my($a1,$b1,$c1);
       $a1 = $add;
       $a = int($a1/2**24) ; $b1 = $a1%2**24;
       $b = int($b1/2**16) ; $c1 = $b1%2**16;
       $c = int($c1/2** 8) ; $d  = $c1%2** 8;
       $ip = "$a.$b.$c.$d" }

    return $ip }

sub network   { &local_net('network'  ,@_) }
sub broadcast { &local_net('broadcast',@_) }
sub nb_add    { &local_net('nb_add'   ,@_) }
sub nb_net    { &local_net('nb_net'   ,@_) }
sub net_all   { &local_net('net_all'  ,@_) }

sub local_net {
    return if $#_ != 2;
    my ($fct,$ip,$mask) = @_;

    return if &error('ip'  ,$ip  );
    return if &error('mask',$mask);

    my ($a1,$a2,$a3,$a4) = split /\./,$ip;
    my ($m1,$m2,$m3,$m4) = split /\./,$mask;

    my $network   = sprintf "%d.%d.%d.%d" , int $m1 & $a1 , int $m2 & $a2 , int $m3 & $a3 , int $m4 & $a4;
    my $broadcast = sprintf "%d.%d.%d.%d" , 255^$m1 | $a1 , 255^$m2 | $a2 , 255^$m3 | $a3 , 255^$m4 | $a4;

    my $nb_add = my $nb_net = 0;
    if ( $fct =~ /all|nb/ ) {
       $nb_add = &decimal('ip',$broadcast) - &decimal('ip',$network) + 1;
       $nb_net = 256**4 / $nb_add }

    if    ( $fct eq 'network'   ) { return $network   }
    elsif ( $fct eq 'broadcast' ) { return $broadcast }
    elsif ( $fct eq 'nb_add'    ) { return $nb_add    }
    elsif ( $fct eq 'nb_net'    ) { return $nb_net    }
    elsif ( $fct eq 'net_all'   ) { return "$network $broadcast $nb_add $nb_net" } }

sub range {
    return if $#_ != 1;
    my ($start,$end) = @_;
    return if &error('ip',$start);
    return if &error('ip',$end  );

    my $tmp;

    # particular case
    if ( $start eq '0.0.0.0' && $end eq '255.255.255.255' ) {
       return sprintf $r_format , $start , $end , $start , '/0' , $start , &local_net('nb_add',$start,$start) }
    elsif ( $start eq $end ) {
       return sprintf $r_format , $start , $end , '255.255.255.255' , '/32' , '0.0.0.0' , '1' }

    my $x12_start = &x12('ip',$start);
    my $x12_end   = &x12('ip',$end  ); # x12_ AAABBBCCCDDD format for comparisons
    if ( $x12_start > $x12_end ) {
       $tmp = $start     ; $start     = $end     ; $end     = $tmp;
       $tmp = $x12_start ; $x12_start = $x12_end ; $x12_end = $tmp }

    my($network,$broadcast,$x12_network,$x12_broadcast) = '';
    my($nb_add,$mask,$wildcard,$result,$m,$ok,$n) = '';

    while (1) {
       # if start = end or start is odd, the address is inevitably in /32
       if ( $start eq $end || $x12_start % 2 ) { $ok = 32 }
       else {
          # otherwise the value of the mask is varied by dicothomy
          # - 5 tests to be done by sub-network in all cases to arrive at the final result
          # - the last included network found will be the result, m between 1 and 31
          $m  = 16; # value of the mask for the first search, format /mask
          $ok = 0;
          for $n (3,2,1,0,9) {
              # values to be tested for $m
              ($network,$broadcast) = (split / /,&local_net('net_all',$start,&mask($m)))[0,1];
              $x12_network   = &x12('ip' ,$network  );
              $x12_broadcast = &x12('ip' ,$broadcast);

              # if the tested subnet is included in the range
              $ok = $m if $x12_network >= $x12_start && $x12_broadcast <= $x12_end;

              if ( $n != 9 ) {
                 # calculation of the following mask by dichotomy
                 if ( $ok == $m ) { $m = $m-2 ** $n }
                 else             { $m = $m+2 ** $n } } } }

       # result found for 1 subnet with m = ok
       $mask     = &mask($ok);
       $wildcard = &invers($mask);

       ($broadcast,$nb_add) = (split / /,&local_net('net_all',$start,$mask))[1,2];

       $result .= sprintf $r_format , $start , $broadcast , $mask , "/$ok" , $wildcard , $nb_add;
       return $result if $broadcast eq $end; # last subnet possible so end

       # reinitialization for the next search from broadcast + 1
       $start     = &plus('1',$broadcast);
       $x12_start = &x12 ('ip',$start) } }

sub sort {
    return if $#_ != 0;
    my ($list) = @_;
    my $result;
    my %list; 

    foreach ( split/;/,$list ) {
       return if &error('ip',$_);
       $list{sprintf "%03d%03d%03d%03d", split/\./} = $_ }
    foreach ( sort { $a <=> $b } keys %list ) { $result .= "$list{$_} - $_ -\n" }
    return $result }
  
sub summary {
    return if $#_ != 0 && $#_ != 1;
    my $list   = $_[0];
    my $detail = $_[1] if $_[1];

    my @list_1;
    my(%list_2,%list_3,%list_4);
    my($result,$text_1,$text_2,$text_3,$text_4,$text_5);

    return if &local_list_1(\$list  ,\@list_1,\$text_1) == 99 ;   # 1 : List of networks to summarize
              &local_list_2(\@list_1,\%list_2,\$text_2);          # 2 : List format start end : ip + decimal
              &local_list_3(\%list_2,\%list_3,\$text_3);          # 3 : List after deleting included ranges and sorting
              &local_list_4(\%list_3,\%list_4,\$text_4);          # 4 : List after grouping ranges that follow or overlap 
              &local_list_5(\%list_4,\$result,\$text_5);          # 5 : Summary

    $result .= "\n$text_1\n$text_2\n$text_3\n$text_4\n$text_5" if $detail && $detail eq 'd';
    return $result }

sub included {
    return if $#_ != 0 && $#_ != 1;
    my $list   = $_[0];
    my $detail = $_[1] if $_[1];

    my @list_1;
    my %list_2;
    my($start,$end,$result,$text_1,$text_2,$text_3,$text_4);

    return if &local_list_1 (\$list  ,\@list_1,\$text_1) == 99 ;   # 1 : List of networks to summarize
              &local_list_2 (\@list_1,\%list_2,\$text_2);          # 2 : List format start end : ip + decimal
              &local_range_1(\%list_2,\$start,\$end,\$text_3);     # 3 : Range start end to include
              &local_range_2(\$start,\$end,\$result,\$text_4);     # 4 : Network that includes the range

    $result .= "\n$text_1\n$text_2\n$text_3\n$text_4" if $detail && $detail eq 'd';
    return $result }

sub local_list_1 {
    # List of networks to summarize
    my($ref_in,$ref_out,$ref_text) = @_;
    my($i,$ip,$mask);
    $i = 0;
    foreach ( split/;/,$$ref_in ) {
       $ip = $mask = '';
       if    ( /(.+)\/(.+)/ ) { $ip = $1 ; $mask = "/$2"; return 99 if &error('cidr',$2) }
       elsif ( /(.+) (.+)/  ) { $ip = $1 ; $mask = $2 }
       elsif ( /(.+)/       ) { $ip = $1 ; $mask = '' }
       else                   { next }
       $ip   =~ tr/ //d; return 99 if &error('ip',$ip);
       $mask =~ tr/ //d;
       push @$ref_out , "$ip $mask";
       $$ref_text .= sprintf $s_format , '1.' , ++$i , $ip , $mask , '' , '' }
    return 99 if $i < 2 }

sub local_list_2 {
    # List format start end : ip + decimal
    my($ref_in,$ref_out,$ref_text) = @_;
    my $i = 0;
    foreach ( @$ref_in ) {
       my ($ip,$mask) = split;
       my $invers = &invers($mask); 

       if    ( ! $mask                  ) { $mask = '255.255.255.255' }
       elsif (   $mask =~ /\/(.+)/      ) { $mask = &mask($1) }
       elsif ( ! &error('mask',$invers) ) { $mask = $invers }
       elsif (   &error('mask',$mask  ) ) { return }

       my $start   = &local_net('network'  ,$ip,$mask);
       my $end     = &local_net('broadcast',$ip,$mask);
       my $x_start = &decimal('ip',$start);
       my $x_end   = &decimal('ip',$end);
       $$ref_text .= sprintf $s_format , '2.' , ++$i , $start , $end , $x_start , $x_end;

       $$ref_out{"$x_start $x_end"} = "$start $end" } }

sub local_list_3 {
    # List after deleting included ranges and sorting
    my($ref_in,$ref_out,$ref_text) = @_;

    # remove the included ranges and create a list out on x_start to be able to sort it
    foreach my $x1 ( keys %$ref_in ) {
       my ( $x1_start , $x1_end ) = split / / , $x1;
       my $ok = 1;
       foreach my $x2 ( keys %$ref_in ) {
          my ( $x2_start , $x2_end ) = split / / , $x2;
          if ( $x1_start == $x2_start && $x1_end == $x2_end ) { next }
          if ( $x1_start >= $x2_start && $x1_end <= $x2_end ) { $ok = 0; last } }
       if ( $ok ) { $$ref_out{$x1_start} = "$x1_end $$ref_in{$x1}" } }

    my $i = 0;
    foreach my $x_start ( sort { $a <=> $b } keys %$ref_out ) {
       my ( $x_end , $start , $end ) = split / / , $$ref_out{$x_start};
       $$ref_text .= sprintf $s_format , '3.' , ++$i , $start , $end , $x_start , $x_end } }

sub local_list_4 {
    # List after grouping ranges that follow or overlap
    my($ref_in,$ref_out,$ref_text) = @_;
    my($x_start,$x_end,$start,$end); 
    my($new_start , $x_new_start);
    my($new_end   , $x_new_end  );
    my $first = 1;
    my $i = 0;
    foreach ( sort { $a <=> $b } keys %$ref_in ) {
       if   ( $first ) {
            $first   = 0;
            $x_start = $_;
            ( $x_end , $start , $end ) = split / / , $$ref_in{$_} }
       else {
            $x_new_start = $_;
            ( $x_new_end , $new_start , $new_end ) = split / / , $$ref_in{$_};

            if   ( $x_new_start <= $x_end + 1 ) {
                 $x_end = $x_new_end;
                 $end   = $new_end  }
            else {
                 $$ref_out{$x_start} = "$start;$end";
                 $$ref_text .= sprintf $s_format , '4.' , ++$i , $start , $end , $x_start , $x_end; 

                 $x_start = $x_new_start;
                 $x_end   = $x_new_end  ;
                 $start   = $new_start  ;
                 $end     = $new_end    } } }

    $$ref_out{$x_start} = "$start;$end";
    $$ref_text .= sprintf $s_format , '4.' , ++$i , $start , $end , $x_start , $x_end }

sub local_list_5 {
    # Summary
    my($ref_in,$ref_result,$ref_text) = @_;
    my $i = 0;
    foreach ( sort { $a <=> $b } keys %$ref_in ) {
       my ( $start , $end ) = split /;/,$$ref_in{$_};
       foreach ( split /\n/,&range($start,$end) ) {
          $$ref_result .= "$_\n";
          ( $start , $end ) = (split /\s+/)[0,1];
          my $x_start = &decimal('ip',$start);
          my $x_end   = &decimal('ip',$end);
          $$ref_text .= sprintf $s_format , '5.' , ++$i , $start , $end , $x_start , $x_end } } }

sub local_range_1 {
    # Range start end to include
    my($ref_list,$ref_start,$ref_end,$ref_text) = @_;  

    my($start,$end,$x_start,$x_end);
    my($min  ,$max,$x_min  ,$x_max);
    $x_min = -1;

    foreach ( keys %$ref_list ) {
       ( $x_start , $x_end ) = split / /;
       ( $start   , $end   ) = split / / , $$ref_list{$_};
       if ( $x_min == -1 ) {
	  $min   = $start;
	  $max   = $end;
	  $x_min = $x_start;
	  $x_max = $x_end }
       else {
	  if ( $x_start < $x_min ) { $min = $start ; $x_min = $x_start }
	  if ( $x_end   > $x_max ) { $max = $end   ; $x_max = $x_end   } } }

    $$ref_start = $min;
    $$ref_end   = $max;
    $$ref_text  = sprintf $s_format , '3.' , '1' , $min , $max , $x_min , $x_max }

sub local_range_2 {
    # Network that includes the range
    my($ref_start,$ref_end,$ref_result,$ref_text) = @_;

    my($cidr,$mask,$broadcast,$decimal_broadcast,$decimal_end);
    my($start,$end,$nb_add,$x_start,$x_end);

    if ( $$ref_start eq $$ref_end ) {
       $cidr = 32 }
    else {
       $decimal_end = &decimal('ip',$$ref_end);

       for(1..32) {
          $cidr = $_;
          $mask = &mask($cidr);
          $broadcast = &local_net('broadcast',$$ref_start,$mask);
          $decimal_broadcast = &decimal('ip',$broadcast);
          last if $decimal_broadcast < $decimal_end }

       # included ok for the last but one value of $cidr
       $cidr-- }

    $mask = &mask($cidr);
    ($start,$end,$nb_add) = (split / /,&net_all($$ref_start,$mask))[0,1,2];
    $$ref_result = sprintf $r_format , $start , $end , $mask , "/$cidr" , &invers($mask) , $nb_add;

    $x_start = &decimal('ip',$start);
    $x_end   = &decimal('ip',$end);
    $$ref_text = sprintf $s_format , '4.' , '1' , $start , $end , $x_start , $x_end }

1;

__END__

=encoding utf8

=head1 NAME

 Net::Kalk - Perl extension for calculate addresses and networks IP
 
=head1 SYNOPSIS

 use Net::Kalk;

 Functions are not exported , it is necessary to use full name to call them
 Example : Net::Kalk::network($add,$mask);

=head1 FUNCTIONS AND PARAMETERS

=head2

=head2 1 : Address

 plus    ($x,$add);  #  calculation of $add + $x , $x is a decimal value
 minus   ($x,$add);  #  calculation of $add - $x , $x is a decimal value
 invers  ($add);     #  calculation of the complement to 1 ip address 

 examples :
  - plus   ('1','1.2.3.255') -> 1.2.4.0
  - plus   ('10','1.2.3.4')  -> 1.2.3.14
  - minus  ('1','1.2.4.0')   -> 1.2.3.255
  - minus  ('10','1.2.3.14') -> 1.2.3.4
  - invers ('255.255.0.0')   -> 0.0.255.255
  - invers ('0.255.255.255') -> 255.0.0.0

=head2 2 : Address conversion

 ip      ('src',$add);
 x12     ('src',$add);
 decimal ('src',$add);
 hexa    ('src',$add);
 binary  ('src',$add);

 src = ip or x12 or decimal or hexa or binary

 x12 = address ip without the points , in addition by 0 if a value is on 1 or 2 digits
 result AAABBBCCCDDD still on 12 digits
 possibility of direct numerical comparisons of addresses

 examples :
  - x12     ('ip','1.2.3.4')       -> 001002003004
  - decimal ('ip','1.2.3.4')       -> 16909060
  - hexa    ('ip','1.2.123.254')   -> 01.02.7B.FE
  - binary  ('ip','1.2.3.4')       -> 00000001.00000010.00000010.00000100
  - ip      ('x12','001002003004') -> 1.2.3.4
  - ip      ('decimal','16909060') -> 1.2.3.4
  - x12     ('decimal','16909060') -> 001002003004
  - hexa    ('decimal','16909060') -> 01.02.03.04

=head2 3 : Mask conversion

 mask($mask);
 mask($cidr);
 
 examples :
  - mask(24)            -> 255.255.255.0
  - mask(255.255.255.0) -> 24

=head2 4 : Network 
 
 network   ($add,$mask);
 broadcast ($add,$mask);
 nb_add    ($add,$mask);  # number of network address
 nb_net    ($add,$mask);  # number of possible networks with the same mask
 net_all   ($add,$mask);  # all the calculations

 examples :
  - network   ('1.2.3.4','255.255.255.0') -> 1.2.3.0
  - broadcast ('1.2.3.4','255.255.255.0') -> 1.2.3.255
  - nb_add    ('1.2.3.4','255.255.255.0') -> 256
  - nb_net    ('1.2.3.4','255.255.255.0') -> 16777216 
  - net_all   ('1.2.3.4','255.255.255.0') -> 1.2.3.0 1.2.3.255 256 16777216

=head2 5 : Error

 error ('fct',$add); 

 fct = ip , mask , cidr or x12
  - ip   : ip address test
  - mask : mask test
  - cidr : cidr test
  - x12  : ip test in x12 format

 return :
  - 1 if error
  - 0 if ok

 examples :
  - error ('ip','1.2.3.4')         -> 0
  - error ('ip','1.2.3.300')       -> 1
  - error ('mask','255.255.255.0') -> 0
  - error ('mask','1.2.3.4')       -> 1
  - error ('cidr','24')            -> 0
  - error ('x12','172030064156')   -> 0

=head2 6 : Address range

 range ($start,$end);

 result  : search for networks necessary to cover an address range defined by a start and an end
 display : network    broadcast   mask     cidr   wildcard   number_of_addresses

 examples :
  - range ('0.0.0.1','255.255.255.254')

=head2 7 : Address sort

 sort ($list);

 list = list of adresses to sort , separated by semicolons

 examples :
  - sort ('10.145.23.89;20.33.45.187;192.168.25.137;2.0.59.74;172.10.35.0;15.6.7.8;1.2.3.4;111.23.45.67')

=head2 8 : Address and network summary

 summary ($list);
 summary ($list,'d');

 list    = list of addresses and networks to summarize , separated by semicolons
 network = address + mask in short or long format , or address + wildcard mask
 examples : A.B.C.D/24 ou A.B.C.D 255.255.255.0 ou A.B.C.D 0.0.0.255

 with a second parameter at 'd' , the calculation is displayed in detail, with all the intermediate steps

 examples :
  - summary ('10.145.23.89;172.10.35.0 255.255.255.0;172.10.35.100 0.0.0.15;192.168.25.137/24;172.10.35.22;172.10.35.241/28')
  - summary ('10.145.23.89;172.10.35.0 255.255.255.0;172.10.35.100 0.0.0.15;192.168.25.137/24;172.10.35.22;172.10.35.241/28' , 'd')

=head2 9 : Address and network included

 included ($list);
 included ($list,'d');

 list    = list of addresses and networks to include , separated by semicolons
 network = address + mask in short or long format , or address + wildcard mask
 examples : A.B.C.D/24 ou A.B.C.D 255.255.255.0 ou A.B.C.D 0.0.0.255

 with a second parameter at 'd' , the calculation is displayed in detail, with all the intermediate steps

 examples :
  - included ('10.145.23.89;10.145.22.0 255.255.255.0;10.145.24.0/24')
  - included ('10.145.23.89;10.145.22.0 255.255.255.0;10.145.24.0/24' , 'd')

=head1 UTILIZATION EXAMPLE

 ip_kalk : example of script perl using Net::Kalk which can call all functions
 command : ip_kalk FUNCTION [VARIABLES] 
 example : ip_kalk decimal ip 1.2.3.4

   #!/usr/bin/perl -w

   exit if @ARGV == 0;
   $fct = $ARGV[0];

   $all_fct  = "error|plus|minus|invers";
   $all_fct .= "|ip|x12|decimal|hexa|binary|mask";
   $all_fct .= "|network|broadcast|nb_add|nb_net|net_all";
   $all_fct .= "|range|sort|summary|included";
   exit if $fct !~ /^($all_fct)$/;

   shift;
   use Net::Kalk;
   $fct = "Net::Kalk::$fct";

   $result = &$fct(@ARGV);
   print $result if defined($result);

=head1 VERSION AND AUTHOR

 Version  : v1.00 - September 2020
 Author   : Thierry LE GALL
 Contact  : facila@gmx.fr

=cut
