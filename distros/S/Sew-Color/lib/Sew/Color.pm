package Sew::Color;

use 5.010001;
use strict;
use warnings;
use Carp; 

require Exporter;

our @ISA = qw(Exporter);

our $VERSION='1.05'; 
#
#use base 'Exporter';
our @EXPORT=(
             'rgb',   # rgb('Brother','405') returns the red green and blue colors of this thread. 
			 'name',  # returns english name of color, eg 'Bright Red'. Caution, not unique. 
			 'code',  # code('Brother',$r,$g,$b) gives the closest thread code to the given rgb 
			          # in array context, returns (code, error distance) using a simple 3d color
					  # space model. 
					  # 1st parameter may be a manufacturers name, empty (for all)
					  # a comma seperate list, or an array reference containing single manufacturers
			 'manlist',
			 'custom',
             'custom_sub', 
             'custom_list',
             'evecrgb',
             'mag',
             'sat'
		    ) ; 
my $colorlist=''; 

sub get_color_list 
{ 
# Brother,Black,100,28,26,28
$colorlist={}; 
local $_; 
while (<DATA>)
{
   m/^ *#/ and next; 
   chomp;  
   my @x=split(/,/); 
   my @rgb; 
   @rgb=@x[3..5]; 
   exists($colorlist->{$x[0]}) or  $colorlist->{$x[0]}={}; 
   $colorlist->{$x[0]}->{$x[2]}={}; 
   $colorlist->{$x[0]}->{$x[2]}->{name}=$x[1]; 
   $colorlist->{$x[0]}->{$x[2]}->{rgb}=\@rgb; 
} 
close DATA; 
} 
sub rgb
{
  my ($man,$code)=@_; 

  $colorlist or get_color_list(); 

  my $r=$colorlist->{$man}->{$code}->{rgb}; 
  return @$r; 
}
sub name
{
  my ($man,$code)=@_; 

  $colorlist or get_color_list(); 
  if (!exists($colorlist->{$man}))
  { 
    croak("Invalid manufacturer code '$man' supplied to function name()"); 
  } 

  my $r=$colorlist->{$man}->{$code}->{name}; 
  return $r; 
}

sub manlist
{
  $colorlist or get_color_list(); 
  return keys %$colorlist; 
} 

# give a list of threads that you have for custom searches. 
# can be Brother 405 406 407 Maderia 1005 102 
sub custom
{
  $colorlist or get_color_list(); 
  my @mankeys=keys %$colorlist; 
  my $man=''; 
  if (@_==0)
  { 
	for $man  (@mankeys)
	{
	  for my $code (keys %{$colorlist->{$man}})
	  {
		  delete $colorlist->{$man}->{$code}->{custom}; 
	  } 
	} 
    return; 
  } 
  for my $t (@_) 
  {
	 my $nmk;
	 $nmk=''; 
	 ($nmk)=grep { $t eq $_ } @mankeys; 
	 defined $nmk or $nmk=''; 
	 #if (0<grep { $t eq $_ } @mankeys)
	 if ($nmk ne '') 
	 {
	    $man=$nmk; 
		next; 
	 }
	 # else its a code. 
	 if ($t eq 'all') # add all for current manufacturer or all manufacturer. 
     { 
       if ($man ne '') 
       {
         for my $key (keys %{$colorlist->{$man}})
         {
             $colorlist->{$man}->{$key}->{'custom'}=1;
         } 
       } 
       else
       { 
         for my $man (keys %{$colorlist}) 
         { 
           for my $key (keys %{$colorlist->{$man}})
           {
             $colorlist->{$man}->{$key}->{'custom'}=1;
           } 
         } 
       } 
      next; 
      } 
	 die "Error no manufacturer given in call to custom for code $t or mispelt manufacturer!" if ($man eq ''); 
	 die "Invalid code '$t' for manufacturer $man in call to custom" if (!exists($colorlist->{$man}->{$t}));
	 $colorlist->{$man}->{$t}->{'custom'}=1; 
  } 
}
# list entries for custom searches. 
sub custom_list 
{
  my ($man,$format)=@_; 
  # man can be empty, a single manufacturer, or a ref to a list of manufacturers. 
  # format can be '%m replace with manufacturer code. %c replace with code, %% replace with %. 
  # Default is '%c'; 
  $colorlist or get_color_list(); 

  my @r; 

  my @mana; 

  defined($format) or  $format='%c'; 
 
  if ($man eq '')
  {
    @mana=();
  } 
  elsif (!ref($man))
  {
    @mana=($man); 
  }
  else
  {
    @mana=@$man; 
  } 

  @mana=keys %$colorlist if (@mana==0); 
      
	 for my $man (@mana)
     {
        for my $key (keys %{$colorlist->{$man}})
        { 
           if (exists($colorlist->{$man}->{$key}->{'custom'}))
           {
             my $f; 
             $f=$format; 
             $f=~s/%m/$man/g; 
             $f=~s/%c/$key/g; 
             $f=~s/%%/%/g; 
             push(@r,$f); 
           }     
        } 
      } 
      return @r; 
} 

# remove keys from  
sub custom_sub
{
  $colorlist or get_color_list(); 
  my @mankeys=keys %$colorlist; 
  my $man=''; 
  my $nmk; 
  for my $t (@_) 
  {
	 my $nmk;
	 $nmk=''; 
	 ($nmk)=grep { $t eq $_ } @mankeys; 
	 defined $nmk or $nmk=''; 
	 #if (0<grep { $t eq $_ } @mankeys)
	 if ($nmk ne '') 
	 {
	    $man=$nmk; 
		next; 
	 }
	 # else its a code. 
	 if ($t eq 'all') # add all for current manufacturer or all manufacturer. 
     { 
       if ($man ne '') 
       {
         for my $key (keys %{$colorlist->{$man}})
         {
             delete($colorlist->{$man}->{$key}->{'custom'}); 
         } 
       } 
       else
       { 
         for my $man (keys %{$colorlist}) 
         { 
           for my $key (keys %{$colorlist->{$man}})
           {
             delete($colorlist->{$man}->{$key}->{'custom'})
           } 
         } 
       } 
      next; 
      } 
	 die "Error no manufacturer given in call to custom for code $t or mispelt manufacturer!" if ($man eq ''); 
	 die "Invalid code '$t' for manufacturer $man in call to custom" if (!exists($colorlist->{$man}->{$t}));
	 delete($colorlist->{$man}->{$t}->{'custom'}); 
  } 
} 
sub code
{
  my ($man,$r,$g,$b)=@_; 
  my $custom=0; 
  my @mans; 

  $colorlist or get_color_list(); 

  my @mankeys=keys %$colorlist; 
  my $err=10000; 
  my $c='' ; # return value; 
  my $mk=''; 

  if (ref($man))
  {
	@mans=@$man; 
  }
  else
  {
    @mans=($man); 
  } 
  @mans=map { split(/,/,$_) }  @mans;   
  @mans=grep {$_ ne '' } @mans; 
  if (grep { $_ eq 'custom' } @mans ) 
  {
     $custom=1; 
	 @mans=grep { $_ ne 'custom'  } @mans; 
  } 

  for my $mankey (@mankeys)
  {
    next if (@mans>0 and 0==grep {$mankey eq $_ } @mans); # only use the wanted keys; 
    for my $code (keys %{$colorlist->{$mankey}})
	{
			#print "#3 $mankey $code\n"; 
	   next if ($custom and !exists $colorlist->{$mankey}->{$code}->{'custom'} ) ; 
	   my $rgb=$colorlist->{$mankey}->{$code}->{rgb}; 
	   my @rgb=@$rgb; 
	   my $d3=($r-$rgb[0])**2+($g-$rgb[1])**2+($b-$rgb[2])**2; 
	   $d3=sqrt($d3); 
	   #print "$code ($r,$g,$b) - (@rgb) $d3\n"; 
	   if ($d3<$err)
	   {
		  $c=$code; 
		  $err=$d3; 
		  $mk=$mankey; 
	   } 
	} 
  }
  $err='' if ($c eq ''); 
  if (wantarray) { return ($c,$mk,$err); } 
  return $c; 
}
# return an error veector between 2 colours as rgb. 
sub evecrgb
{
  my ($r1,$g1,$b1,$r2,$g2,$b2)=@_; 

  my ($r,$g,$b); 

  ($r,$g,$b)=($r1-$r2,$g1-$g2,$b1-$b2); 
  
  return ($r,$g,$b); 
} 
# return magnetude of rgb value. 
sub mag
{
  my ($r,$g,$b)=@_;  

  return sqrt($r*$r+$g*$g+$b*$b); 
} 
# return saturation of rgb value. 
# value returned is between 0 an 255 inclusive. 
sub sat
{
  my ($r,$g,$b)=@_;  
  my $s=0;  # saturation is zero for black.   

  my $w=min($r,$g,$b); # white component; 
  my $m=mag($r,$g,$b); # magnetude of given colour 

  map { $_-=$w } ($r,$g,$b); 

  my $nw=mag($r,$g,$b); # non white component;

  if ($m>=1)
  {
     $s=255*$nw/$m; 
  } 
  return $s; 
}
sub min
{
   my (@x)=@_; 

   my $m=$x[0]; 

   for my $x (@x)
   {
      $m=$x if ($x<$m);  
   } 
   return $m; 
} 
return 1; 
=head1 NAME 

 Sew:Color - rgb colours for various manufactures of coloured embroidery thread.   

=head1 ABSTRACT

  Extensible Module for determining rgb colours of various manufacturers of embroidering thread 
  and the codes that go with them. 

=head1 SYNOPSIS 

 use Sew::Color
 my @rgb=rgb('Brother', '502'); 
 my $name=name('Brother','502'); 

 print "$name (@rgb)\n"; 
 my @m=manlist(); 

=head1 DESCRIPTION

 These calls return respectively the red green and blue components of the colour of the thread 
 and the 'English' name of the thread colour. The colour components will be in the range 0 to 255. 
 In this case, Brother thread number 502. 
 Be aware that the name of the thread colour is not unique, there are some codes that have 
 the same name, although they are mostly different. 

 The above code prints out 
    
    Mint Green (148 190 140) 

 code(Manufacturer,red,green.blue)

 This function does a simple search in the colour space to find the colour that is closest to the rgb values you provide. 

 The parameters are

   Manufacturer: Can be a single manufacturer, a comma seperated list or an array reference of manufacturers. 
   				 It can be empty to search all known about. 
   red, green, blue are the colour co-ordinates to search for. Distnce is done through a very simple sequential search
                 using a simple 3-d colour model without any weightings. (so rgb all treated the same.) 

 The return values are: 

	In a scalar context, just the code, for example '502'. 
	In an array context it returns a 3 element array, with the following entries

		Thread code, eg '502'
		Manufacturer, eg 'Brother' 
		Error distance, eg 42. This is the distance in linear units scaled to 255 
		between the thread found and the desired colour. Note that it can be more than 255
		(Consider that the diagonal of a cube with side 255 is more than 255. ) but will normally 
		not be.

     Note that only one result is returned, and this ought tobe changed, all nearest results should be found. 

The function manlist() returns an array of the names of the manufacturers supported.  

=head2 Custom Searches

 If you only have certain threads that you want to search (you dont happen to have the full Madeira
 in your store cupboard!) you can say which ones you do have by using the custom function. This is called as follows

   custom('Manufacturer',list of codes, 'Manufacturer', list of codes ) 

 A call to the code function with the special string 'custom' as manufacturer will search only these threads. 

   custom() 

 will reset all the custom threads. 

 Multiple calls to custom where the argument list is not empty will add each new set to the custom search list. 

 The special keyword all may be used with the custom function to either add all the threads for a manufacturer, or to add all threads of all manufacturers. so custom('Brother','all') would add all Brother threads, while custom('all') would add all known threads. Once added individual threads or sets can be removed with the custom_sub function. 

 custom_sub() takes parameters similar to custom and will remove specific threads from the custom search list. 

 

=head2 Methods

		rgb(Manufacturer, code) returns a 255-max scaled rgb tripplet. 
		name(Manufacturer,code) returns the "English" name of the colour. 
		code(Manufacturer-list,r,g,b)  returns either the code or an array 
								with the following: (Manufacturer,code,error distance) 

=head1 CAVEAT

 All should be aware that giving an rgb value for a thread colour will never be anything more than an approximation at best, even assuming 
 the values are right. Be aware that many thread manufacturers give or sell colour cards that have actual samples of the thread on, because even 
 using paint on paper has proved so unsatisfactory. Really I cannot say it loud enough, trying to represent real-world colours that are not 
 a photograph, using rgb values is massively approximate at best. For example, it depends on the angle of the light, the amount of 
 light, the type of light and other factors. Or it may not. I have seen materials that change colour quite noticibly depending on weather they 
 are viewed by sunlight, incandescent light or flourscent light. Its a manufacturers nightmare, but it happens.

=head1 PROCESS

 In the main these values were derived by me by taking a web page which has a photograph of the thread, cropping it to remove anything like a shadow, 
 changing the size to 1 by 1 pixcel (so that all other pixcels are averaged) and then listing the colour of that pixcel. 

 This results in rather real-world values - the extreme ends of the scale near 0 and 255 do not appear and the colours are a bit less saturated than...
 well then you might think. 

 Sulky helpfully provide a spreadsheet with rgb values. It would be a bit silly not to use it, wouldnt it? But the truth is that the values 
 you get are very different since they have clearly been normalised in some way so that blacks are fully black and whites are fully white. 

 For example, Sulky "Black" 942-1005 has rgb values (0,0,0) in the spreadsheet. But using the other method, has rgb values (44,42,44). 

 Which is right? The answer is of course that both are, and you need to use the values obtained carefully and sensibly, processing them if needed. 

 Sulky do this (perhaps) because in part you are throwing away some of the precision in your 8 bit representation if you say the lowest value 
 I am going to have is 42. They are (probably) not happy using 8 bits any way, because from there perspective this is not much precision to 
 represent a world of colour, why throw some of it away?  

 Which Sulky values did I include? In the end I included the real-world values since thats more compatible with the other manufacturers in the 
 package. Let me know if you think I should do other wise. It also allows me to easily include varigated threads (that have a delibneratly 
 variable colour along its length) since this will be correctly averaged. 

=head2 EXTENSION

The module may be extended to a new manufacturer by adding lines of the following format to the module: 

manufacturer,english name,code,red,green,blue

for example the line 
      Brother,Moss Green,515,48,125,38

is responsible for the Moss Green number 515 entry. 

=head1 BUGS and the like 

 There are many manufacturers not covered. 

 If you use this please drop me an email to say it has been useful (or not) to you. 

 The sat() function generally returned 255 in version 1.04. This is fixed in 1.05 

=head1 AUTHOR 

 Mark Winder June 2012. 
 markwin (at) cpan.org 							

=cut   

__DATA__
Madeira,,1000,44,42,44
Madeira,,1001,228,238,252
Madeira,,1002,236,238,252
Madeira,,1003,236,238,236
Madeira,,1004,204,206,212
Madeira,,1005,204,210,220
Madeira,,1006,44,42,44
Madeira,,1007,44,42,44
Madeira,,1008,44,42,44
Madeira,,1009,44,42,44
Madeira,,1010,196,198,196
Madeira,,1011,180,186,188
Madeira,,1012,164,178,188
Madeira,,1013,244,214,204
Madeira,,1014,244,186,196
Madeira,,1015,236,186,180
Madeira,,1016,228,154,156
Madeira,,1017,244,194,172
Madeira,,1018,244,186,172
Madeira,,1019,236,170,164
Madeira,,1020,252,142,132
Madeira,,1021,188,86,52
Madeira,,1022,244,234,188
Madeira,,1023,244,222,108
Madeira,,1024,252,166,36
Madeira,,1025,212,134,36
Madeira,,1026,252,198,148
Madeira,,1027,156,186,204
Madeira,,1028,92,142,172
Madeira,,1029,44,142,188
Madeira,,1030,148,174,196
Madeira,,1031,204,162,188
Madeira,,1032,124,106,156
Madeira,,1033,116,78,140
Madeira,,1034,156,66,100
Madeira,,1035,100,50,68
Madeira,,1036,92,50,52
Madeira,,1037,196,18,36
Madeira,,1038,148,46,52
Madeira,,1039,172,42,52
Madeira,,1040,148,138,140
Madeira,,1041,108,118,132
Madeira,,1042,36,86,124
Madeira,,1043,44,54,68
Madeira,,1044,44,50,60
Madeira,,1045,132,206,188
Madeira,,1046,92,178,156
Madeira,,1047,164,198,172
Madeira,,1048,132,158,92
Madeira,,1049,116,166,76
Madeira,,1050,60,146,68
Madeira,,1051,4,134,68
Madeira,,1052,60,118,116
Madeira,,1053,236,186,172
Madeira,,1054,180,130,124
Madeira,,1055,212,178,140
Madeira,,1056,156,106,76
Madeira,,1057,156,110,84
Madeira,,1058,116,70,60
Madeira,,1059,68,58,52
Madeira,,1060,188,178,164
Madeira,,1061,252,222,172
Madeira,,1062,148,142,132
Madeira,,1063,132,126,116
Madeira,,1064,252,202,20
Madeira,,1065,236,122,36
Madeira,,1066,252,218,156
Madeira,,1067,244,226,172
Madeira,,1068,252,190,4
Madeira,,1069,252,182,20
Madeira,,1070,212,170,108
Madeira,,1071,236,234,220
Madeira,,1072,196,194,180
Madeira,,1073,212,222,212
Madeira,,1074,156,186,212
Madeira,,1075,140,174,204
Madeira,,1076,4,82,148
Madeira,,1077,236,82,68
Madeira,,1078,244,86,44
Madeira,,1079,4,138,84
Madeira,,1080,164,126,172
Madeira,,1081,180,46,76
Madeira,,1082,212,194,172
Madeira,,1083,252,206,84
Madeira,,1084,212,190,164
Madeira,,1085,188,186,180
Madeira,,1086,204,206,204
Madeira,,1087,196,198,196
Madeira,,1088,108,178,180
Madeira,,1089,108,170,180
Madeira,,1090,4,134,140
Madeira,,1091,4,118,132
Madeira,,1092,156,198,212
Madeira,,1093,44,194,204
Madeira,,1094,4,182,204
Madeira,,1095,4,170,196
Madeira,,1096,4,130,164
Madeira,,1097,188,214,196
Madeira,,1098,76,126,116
Madeira,,1099,196,202,164
Madeira,,1100,188,210,180
Madeira,,1101,68,142,76
Madeira,,1102,156,158,100
Madeira,,1103,52,78,60
Madeira,,1104,204,202,156
Madeira,,1105,180,170,132
Madeira,,1106,156,142,84
Madeira,,1107,236,102,124
Madeira,,1108,236,146,172
Madeira,,1109,212,82,140
Madeira,,1110,196,46,108
Madeira,,1111,204,182,204
Madeira,,1112,84,74,132
Madeira,,1113,244,206,196
Madeira,,1114,244,194,196
Madeira,,1115,244,194,196
Madeira,,1116,236,178,196
Madeira,,1117,212,98,140
Madeira,,1118,148,154,156
Madeira,,1119,164,82,108
Madeira,,1120,236,190,204
Madeira,,1121,228,182,204
Madeira,,1122,84,58,108
Madeira,,1123,244,230,188
Madeira,,1124,252,202,84
Madeira,,1125,244,178,52
Madeira,,1126,188,134,100
Madeira,,1127,220,194,172
Madeira,,1128,172,154,140
Madeira,,1129,76,58,52
Madeira,,1130,68,54,52
Madeira,,1131,60,54,52
Madeira,,1132,140,190,212
Madeira,,1133,44,130,188
Madeira,,1134,4,94,156
Madeira,,1135,252,218,116
Madeira,,1136,148,130,116
Madeira,,1137,252,142,12
Madeira,,1138,204,190,172
Madeira,,1140,132,134,52
Madeira,,1141,156,114,124
Madeira,,1142,180,154,140
Madeira,,1143,76,114,156
Madeira,,1144,140,114,92
Madeira,,1145,100,66,60
Madeira,,1146,212,38,44
Madeira,,1147,180,18,52
Madeira,,1148,228,146,164
Madeira,,1149,220,198,180
Madeira,,1150,220,226,140
Madeira,,1151,172,182,196
Madeira,,1152,252,142,116
Madeira,,1153,180,198,212
Madeira,,1154,220,70,100
Madeira,,1155,252,154,92
Madeira,,1156,124,118,68
Madeira,,1157,124,110,76
Madeira,,1158,124,70,60
Madeira,,1159,212,162,60
Madeira,,1160,84,118,140
Madeira,,1161,52,82,92
Madeira,,1162,28,70,76
Madeira,,1163,100,122,140
Madeira,,1164,76,66,84
Madeira,,1166,36,66,132
Madeira,,1167,36,74,124
Madeira,,1169,140,154,76
Madeira,,1170,92,110,44
Madeira,,1171,244,178,76
Madeira,,1172,236,154,44
Madeira,,1173,196,118,60
Madeira,,1174,132,58,52
Madeira,,1175,60,106,148
Madeira,,1176,28,138,188
Madeira,,1177,4,114,172
Madeira,,1178,252,106,68
Madeira,,1179,212,90,84
Madeira,,1180,236,202,84
Madeira,,1181,140,38,52
Madeira,,1182,124,46,68
Madeira,,1183,140,50,84
Madeira,,1184,196,34,76
Madeira,,1185,4,102,100
Madeira,,1186,172,2,68
Madeira,,1187,180,26,84
Madeira,,1188,124,62,116
Madeira,,1189,28,42,20
Madeira,,1190,156,126,60
Madeira,,1191,148,114,60
Madeira,,1192,164,114,36
Madeira,,1193,164,162,76
Madeira,,1194,84,70,20
Madeira,,1195,140,182,180
Madeira,,1196,124,110,20
Madeira,,1198,164,178,196
Madeira,,1199,36,22,36
Madeira,,1212,140,146,164
Madeira,,1217,228,182,164
Madeira,,1218,156,94,92
Madeira,,1219,140,162,172
Madeira,,1220,228,130,140
Madeira,,1221,172,66,52
Madeira,,1222,204,198,172
Madeira,,1223,252,206,44
Madeira,,1224,228,190,84
Madeira,,1225,204,142,68
Madeira,,1226,220,150,108
Madeira,,1227,132,166,164
Madeira,,1228,84,74,76
Madeira,,1229,68,50,52
Madeira,,1230,52,30,28
Madeira,,1232,172,162,196
Madeira,,1233,76,66,100
Madeira,,1234,188,54,100
Madeira,,1235,156,106,148
Madeira,,1236,76,42,52
Madeira,,1238,132,38,52
Madeira,,1239,84,78,76
Madeira,,1240,116,106,108
Madeira,,1241,60,66,68
Madeira,,1242,36,62,92
Madeira,,1243,52,58,76
Madeira,,1244,52,50,60
Madeira,,1245,52,162,132
Madeira,,1246,4,150,140
Madeira,,1247,4,154,116
Madeira,,1248,164,210,108
Madeira,,1249,36,162,68
Madeira,,1250,4,110,76
Madeira,,1251,4,146,76
Madeira,,1252,60,98,108
Madeira,,1253,204,126,84
Madeira,,1254,236,146,132
Madeira,,1255,156,126,76
Madeira,,1256,140,86,44
Madeira,,1257,116,42,12
Madeira,,1258,92,30,20
Madeira,,1259,116,90,84
Madeira,,1260,204,186,140
Madeira,,1261,148,150,204
Madeira,,1263,116,110,164
Madeira,,1264,132,122,156
Madeira,,1266,36,54,156
Madeira,,1267,204,198,156
Madeira,,1270,228,190,132
Madeira,,1272,188,126,76
Madeira,,1273,140,114,68
Madeira,,1274,116,162,204
Madeira,,1275,116,134,188
Madeira,,1276,60,98,156
Madeira,,1277,28,30,76
Madeira,,1278,252,102,20
Madeira,,1279,12,134,124
Madeira,,1280,4,122,100
Madeira,,1281,156,34,60
Madeira,,1282,116,194,172
Madeira,,1284,20,86,92
Madeira,,1286,188,182,188
Madeira,,1287,84,78,84
Madeira,,1288,100,94,100
Madeira,,1289,68,154,164
Madeira,,1290,28,82,84
Madeira,,1291,4,106,124
Madeira,,1292,148,198,196
Madeira,,1293,4,110,116
Madeira,,1294,4,138,164
Madeira,,1295,4,146,172
Madeira,,1296,4,98,132
Madeira,,1297,4,118,164
Madeira,,1298,4,142,124
Madeira,,1299,12,194,180
Madeira,,1301,68,178,132
Madeira,,1302,132,210,156
Madeira,,1303,52,62,52
Madeira,,1304,4,78,68
Madeira,,1305,196,182,156
Madeira,,1306,124,122,100
Madeira,,1307,228,74,84
Madeira,,1308,76,78,68
Madeira,,1309,220,106,164
Madeira,,1310,156,62,124
Madeira,,1311,140,138,188
Madeira,,1312,100,82,116
Madeira,,1313,68,58,92
Madeira,,1315,236,158,172
Madeira,,1317,236,166,164
Madeira,,1318,76,70,76
Madeira,,1319,164,102,140
Madeira,,1320,92,70,100
Madeira,,1321,228,150,188
Madeira,,1322,68,66,124
Madeira,,1323,172,162,52
Madeira,,1328,132,98,92
Madeira,,1329,124,98,84
Madeira,,1330,84,102,164
Madeira,,1334,100,54,108
Madeira,,1335,68,102,164
Madeira,,1336,116,94,84
Madeira,,1337,124,138,124
Madeira,,1338,172,146,116
Madeira,,1339,140,138,132
Madeira,,1340,148,134,52
Madeira,,1341,164,102,100
Madeira,,1342,164,130,116
Madeira,,1343,52,58,100
Madeira,,1344,140,114,84
Madeira,,1347,76,54,20
Madeira,,1348,84,58,28
Madeira,,1349,204,190,124
Madeira,,1350,180,162,68
Madeira,,1351,20,54,60
Madeira,,1352,148,118,20
Madeira,,1353,68,90,132
Madeira,,1354,204,78,116
Madeira,,1356,188,166,188
Madeira,,1357,76,74,52
Madeira,,1358,116,78,76
Madeira,,1359,212,162,52
Madeira,,1360,124,150,164
Madeira,,1361,76,70,76
Madeira,,1362,84,78,100
Madeira,,1363,116,126,148
Madeira,,1364,76,94,116
Madeira,,1365,60,74,100
Madeira,,1366,44,54,108
Madeira,,1367,28,18,36
Madeira,,1368,28,22,52
Madeira,,1369,60,126,68
Madeira,,1370,36,90,68
Madeira,,1371,28,90,84
Madeira,,1372,204,146,52
Madeira,,1373,92,150,196
Madeira,,1374,100,46,52
Madeira,,1375,60,130,164
Madeira,,1376,36,82,108
Madeira,,1377,92,138,84
Madeira,,1378,220,58,44
Madeira,,1379,236,98,76
Madeira,,1380,4,154,132
Madeira,,1381,140,34,60
Madeira,,1382,100,58,68
Madeira,,1383,156,34,84
Madeira,,1384,108,46,60
Madeira,,1385,100,42,52
Madeira,,1386,76,50,68
Madeira,,1387,116,106,132
Madeira,,1388,100,62,92
Madeira,,1389,108,46,68
Madeira,,1390,52,74,68
Madeira,,1391,76,102,92
Madeira,,1392,108,126,116
Madeira,,1393,68,70,52
Madeira,,1394,76,82,68
Madeira,,1395,68,78,68
Madeira,,1396,84,98,84
Madeira,,1397,36,74,60
Madeira,,2010,236,222,188
Madeira,,2011,244,214,132
Madeira,,2012,244,182,196
Madeira,,2013,244,178,196
Madeira,,2014,196,106,196
Madeira,,2015,148,174,220
Madeira,,2016,156,170,212
Madeira,,2017,188,186,188
Madeira,,2018,204,186,172
Madeira,,2019,180,214,180
Madeira,,2020,124,210,148
Madeira,,2021,236,118,164
Madeira,,2022,244,86,52
Madeira,,2023,220,150,36
Madeira,,2024,196,118,44
Madeira,,2025,92,170,204
Madeira,,2026,100,74,132
Madeira,,2027,204,2,4
Madeira,,2028,188,210,148
Madeira,,2029,148,122,20
Madeira,,2030,52,158,196
Madeira,,2031,108,190,68
Madeira,,2032,164,78,20
Madeira,,2033,108,150,52
Madeira,,2034,100,66,76
Madeira,,2035,204,218,188
Madeira,,2036,60,50,164
Madeira,,2037,244,194,212
Madeira,,2038,108,122,196
Madeira,,2039,100,186,124
Madeira,,2040,228,210,84
Madeira,,2050,164,66,148
Madeira,,2051,236,86,164
Madeira,,2052,244,82,156
Madeira,,2053,236,106,36
Madeira,,2054,164,82,52
Madeira,,2055,204,82,116
Madeira,,2056,188,62,76
Madeira,,2057,228,154,212
Madeira,,2058,132,2,4
Madeira,,2059,204,30,36
Madeira,,2060,236,66,60
Madeira,,2101,220,226,212
Madeira,,2102,220,218,196
Madeira,,2103,180,194,180
Madeira,,2105,180,130,140
Madeira,,2106,156,130,124
Madeira,,2140,132,114,140
Madeira,,2141,164,134,132
Madeira,,2142,196,102,84
Madeira,,2143,156,114,68
Madeira,,2144,140,46,36
Madeira,,2145,172,58,12
Madeira,,2146,100,146,76
Madeira,,2147,164,130,84
Madeira,,2148,132,94,60
Madeira,,2149,124,94,52
Long Creek Mills,Alpha Blue,ES0697,4,102,148
Long Creek Mills,Amber,ES0652,212,174,44
Long Creek Mills,Antelope,ES1520,132,122,108
Long Creek Mills,Applespice,ES0621,188,130,60
Long Creek Mills,Aqua 2,ES0907,36,178,164
Long Creek Mills,Aqua,ES0109,36,178,164
Long Creek Mills,Ash 2,ES1713,132,138,140
Long Creek Mills,Ash,ES0112,124,130,132
Long Creek Mills,Avacado,ES0950,156,182,100
Long Creek Mills,Azure 2,ES4627,4,106,100
Long Creek Mills,Azure,ES0450,4,146,132
Long Creek Mills,Baby Blue,ES6137,156,202,220
Long Creek Mills,Baltic Blue,ES2093,4,138,196
Long Creek Mills,Barely Beige,ES0828,228,234,220
Long Creek Mills,Bark,ES5558,84,70,44
Long Creek Mills,Bashful Pink 2,ES0315,244,102,140
Long Creek Mills,Bashful Pink,ES0313,244,102,140
Long Creek Mills,Beige,ES0501,252,230,212
Long Creek Mills,Black,ES0020,36,30,36
Long Creek Mills,Black,ES0020,36,30,36
Long Creek Mills,Black Pearl,ES5556,4,54,92
Long Creek Mills,Blonde,ES1147,196,186,164
Long Creek Mills,Blue Mist,ES0965,60,94,116
Long Creek Mills,Blue Spruce,ES0448,4,82,84
Long Creek Mills,Blue Suede 2,ES4453,4,102,180
Long Creek Mills,Blue Suede,ES0414,4,102,180
Long Creek Mills,Bone,ES0812,252,230,196
Long Creek Mills,Bright Gold 2,ES2519,180,154,20
Long Creek Mills,Bright Gold,ES0842,180,154,20
Long Creek Mills,Bronze,ES3142,140,82,28
Long Creek Mills,Brown Linen,ES0412,164,134,100
Long Creek Mills,Bunny Brown,ES0833,148,102,68
Long Creek Mills,Burgundy,ES0333,188,54,92
Long Creek Mills,Burnished Copper,ES0840,140,50,4
Long Creek Mills,Burnt Sienna,ES0905,188,134,52
Long Creek Mills,Cabernet 2,ES0325,220,70,140
Long Creek Mills,Cabernet 3,ES0332,220,106,148
Long Creek Mills,Cabernet,ES0324,236,78,148
Long Creek Mills,Cactus,ES0655,76,74,4
Long Creek Mills,Cafe Au Lait,ES0830,204,158,132
Long Creek Mills,Cantelope,ES0649,252,158,44
Long Creek Mills,Cappaccino,ES0839,156,54,28
Long Creek Mills,Caramel 2,ES0843,172,126,60
Long Creek Mills,Caramel,ES0619,196,158,68
Long Creek Mills,Carnation Pink,ES0506,252,162,156
Long Creek Mills,Carolina Red,ES1240,212,18,68
Long Creek Mills,Chambray Blue 2,ES4004,124,194,228
Long Creek Mills,Chambray Blue,ES0403,92,178,212
Long Creek Mills,Charcoal,ES0116,68,82,84
Long Creek Mills,Cherry 2,ES3015,236,30,44
Long Creek Mills,Cherry,ES0187,180,10,60
Long Creek Mills,Chicory,ES1163,4,94,164
Long Creek Mills,China Blue,ES0104,4,102,172
Long Creek Mills,Christmas Green,ES0777,4,154,76
Long Creek Mills,Cilantro,ES0988,108,182,60
Long Creek Mills,Cinnamon,ES0624,228,134,28
Long Creek Mills,Cobalt Blue 2,ES5551,4,70,140
Long Creek Mills,Cobalt Blue,ES0415,4,46,84
Long Creek Mills,Coffee 2,ES1152,100,70,52
Long Creek Mills,Coffee,ES0878,100,70,52
Long Creek Mills,Copper,ES0654,236,158,28
Long Creek Mills,Cotton Candy,ES0302,252,202,204
Long Creek Mills,Country Blue 2,ES0406,92,154,204
Long Creek Mills,Country Blue,ES0380,116,170,212
Long Creek Mills,Country Rose 2,ES0527,244,90,92
Long Creek Mills,Country Rose 3,ES0700,244,66,36
Long Creek Mills,Country Rose 4,ES3016,244,90,76
Long Creek Mills,Country Rose,ES0266,236,50,44
Long Creek Mills,Cranberry 2,ES0531,132,2,52
Long Creek Mills,Cranberry 3,ES1241,156,2,44
Long Creek Mills,Cranberry,ES0530,180,42,84
Long Creek Mills,Crepe Myrtle,ES0347,164,86,148
Long Creek Mills,Crocus 2,ES0609,228,186,36
Long Creek Mills,Crocus 3,ES0641,252,202,36
Long Creek Mills,Crocus 4,ES0642,252,186,20
Long Creek Mills,Crocus 5,ES0763,252,202,12
Long Creek Mills,Crocus,ES0286,252,206,76
Long Creek Mills,Custard 2,ES0613,244,234,164
Long Creek Mills,Custard,ES0601,244,226,140
Long Creek Mills,Danish Teal,ES0913,4,74,100
Long Creek Mills,Dark Brown 2,ES0859,92,30,4
Long Creek Mills,Dark Brown,ES0513,100,58,44
Long Creek Mills,Dark Dusty Rose,ES0867,180,118,108
Long Creek Mills,Dark Green 2,ES4735,4,78,76
Long Creek Mills,Dark Green,ES0695,4,78,60
Long Creek Mills,Dark Grey 2,ES1716,108,106,116
Long Creek Mills,Dark Grey,ES0585,108,106,116
Long Creek Mills,Dark Lilac,ES0383,172,170,212
Long Creek Mills,Dark Maroon,ES0361,108,18,52
Long Creek Mills,Dark Seafoam,ES0455,20,114,100
Long Creek Mills,Date,ES0841,132,86,44
Long Creek Mills,Deep Purple,ES0390,140,98,172
Long Creek Mills,Desert Rose,ES0307,244,158,180
Long Creek Mills,Dove Greay,ES0102,172,182,188
Long Creek Mills,Dove Grey 2,ES0111,132,142,156
Long Creek Mills,Dusk,ES0873,124,106,100
Long Creek Mills,Dusty Peach,ES0832,212,134,116
Long Creek Mills,Dusty Rose,ES0864,180,114,100
Long Creek Mills,Enchanted Sea,ES1386,4,82,108
Long Creek Mills,Erin Green,ES1183,140,198,60
Long Creek Mills,Fawn,ES0628,188,142,100
Long Creek Mills,Flame Red,ES0528,220,58,44
Long Creek Mills,Flesh 2,ES0503,252,222,196
Long Creek Mills,Flesh,ES0502,252,210,196
Long Creek Mills,French Beige 2,ES2526,212,158,92
Long Creek Mills,French Beige,ES2518,220,174,124
Long Creek Mills,Golden,ES0033,252,194,12
Long Creek Mills,Grass Green 2,ES0451,12,174,92
Long Creek Mills,Grass Green 3,ES0944,236,234,188
Long Creek Mills,Grass Green 4,ES0945,228,230,204
Long Creek Mills,Grass Green,ES0317,4,154,76
Long Creek Mills,Gray Cat,ES0118,92,86,84
Long Creek Mills,Green Apple 2,ES1619,164,206,60
Long Creek Mills,Green Apple,ES0985,196,222,140
Long Creek Mills,Green Meadow,ES0949,100,194,156
Long Creek Mills,Green Onion,ES0983,180,190,36
Long Creek Mills,Grey 2,ES0115,68,86,100
Long Creek Mills,Grey 3,ES0589,108,118,124
Long Creek Mills,Grey,ES0114,68,86,100
Long Creek Mills,Greyhound,ES0117,36,6,20
Long Creek Mills,Harvest Gold,ES0616,212,170,4
Long Creek Mills,Hazel 2,ES0255,220,102,36
Long Creek Mills,Heart 2,ES0526,244,82,36
Long Creek Mills,Heart,ES0135,244,90,36
Long Creek Mills,Holly Red,ES0571,196,34,60
Long Creek Mills,Honcho Brown,ES0857,108,74,4
Long Creek Mills,Honey,ES0620,196,150,68
Long Creek Mills,Honeysuckle,ES0525,244,126,28
Long Creek Mills,Hortensia Plum,ES0362,76,14,84
Long Creek Mills,Ice Blue,ES0402,172,206,212
Long Creek Mills,Illusion 2,ES0831,244,170,140
Long Creek Mills,Illusion,ES0504,252,190,172
Long Creek Mills,Jay Blue,ES0809,4,90,172
Long Creek Mills,Jockey Red,ES0213,180,42,76
Long Creek Mills,Jungle Green,ES0992,4,118,68
Long Creek Mills,Lake Como,ES0966,68,98,108
Long Creek Mills,Legion Blue 2,ES0423,4,30,68
Long Creek Mills,Legion Blue 3,ES5552,4,30,68
Long Creek Mills,Legion Blue,ES0422,4,30,68
Long Creek Mills,Light Aqua,ES0909,36,178,164
Long Creek Mills,Light Dusty Rose,ES0862,252,202,196
Long Creek Mills,Light Gold,ES0982,212,190,92
Long Creek Mills,Light Grey 2,ES8010,108,118,124
Long Creek Mills,Light Grey,ES0588,140,142,148
Long Creek Mills,Light Navy 2,ES5553,36,58,92
Long Creek Mills,Light Navy,ES0416,4,38,76
Long Creek Mills,Light Neon Orange,ES0042,252,198,60
Long Creek Mills,Light Royal 2,ES1423,12,78,164
Long Creek Mills,Light Royal,ES0413,4,110,180
Long Creek Mills,Light Silver 2,ES5829,212,210,196
Long Creek Mills,Light Silver,ES0101,220,218,212
Long Creek Mills,Lincoln Green,ES3325,4,126,108
Long Creek Mills,Mahogany 2,ES0892,36,6,20
Long Creek Mills,Mahogany,ES0891,68,42,44
Long Creek Mills,Maize 2,ES0811,236,234,220
Long Creek Mills,Maize 4,ES1140,236,234,220
Long Creek Mills,Maize,ES0165,236,234,212
Long Creek Mills,Mandarin,ES0520,252,158,28
Long Creek Mills,Marigold,ES0432,252,194,68
Long Creek Mills,Medium Gold,ES0952,156,150,60
Long Creek Mills,Money,ES0963,60,102,36
Long Creek Mills,Moonlight,ES1708,196,202,204
Long Creek Mills,Muslin,ES1141,172,170,148
Long Creek Mills,Mustard,ES0419,252,234,84
Long Creek Mills,Napa Red,ES0838,180,82,60
Long Creek Mills,Natural,ES0015,244,246,244
Long Creek Mills,Neon Fuchsia,ES0054,188,10,108
Long Creek Mills,Neon Green,ES0032,188,214,44
Long Creek Mills,Neon Orange,ES0043,252,166,28
Long Creek Mills,Neon Pink,ES0046,244,90,140
Long Creek Mills,Neon Rose,ES0047,236,74,84
Long Creek Mills,New Gold,ES1552,180,154,92
Long Creek Mills,Night Horizon,ES2031,4,78,148
Long Creek Mills,Nutmeg 2,ES0858,124,70,4
Long Creek Mills,Nutmeg 3,ES1545,140,82,28
Long Creek Mills,Nutmeg,ES0854,132,90,68
Long Creek Mills,Olive Drab,ES0955,76,90,4
Long Creek Mills,Orchid Bouquet,ES1313,124,82,164
Long Creek Mills,Orchid,ES1323,116,34,132
Long Creek Mills,Pale Green,ES0442,236,234,188
Long Creek Mills,Pale Yellow 2,ES0632,244,242,156
Long Creek Mills,Pale Yellow,ES0604,252,242,108
Long Creek Mills,Papaya,ES3014,244,158,140
Long Creek Mills,Paprika,ES3001,244,134,28
Long Creek Mills,Peach 2,ES0505,252,170,148
Long Creek Mills,Peach,ES0818,252,222,188
Long Creek Mills,Peach Sherbert,ES0466,252,206,116
Long Creek Mills,Peachy Pink,ES0508,252,166,116
Long Creek Mills,Periwinkle 3,ES4419,100,202,228
Long Creek Mills,Periwinkle,ES0444,4,158,188
Long Creek Mills,Persimmon,ES0529,180,14,52
Long Creek Mills,Petal Pink,ES0376,244,222,220
Long Creek Mills,Petunia,ES0305,252,182,196
Long Creek Mills,Pewter,ES1149,148,154,132
Long Creek Mills,Pink Glaze 2,ES0387,236,214,220
Long Creek Mills,Pink Glaze,ES0304,252,198,204
Long Creek Mills,Pink Sorbet,ES0321,244,134,188
Long Creek Mills,Plum,ES0348,76,2,84
Long Creek Mills,Powder Blue,ES0379,156,186,220
Long Creek Mills,Prairie Beige,ES4371,140,110,92
Long Creek Mills,Pueblo Pink,ES0306,252,178,180
Long Creek Mills,Purple Aster,ES0386,180,154,204
Long Creek Mills,Purple,ES0392,124,82,164
Long Creek Mills,Purple Shadow,ES0398,100,58,132
Long Creek Mills,Red Jubiliee,ES2250,124,22,76
Long Creek Mills,Reed Green,ES0653,164,162,116
Long Creek Mills,Rosewood,ES0190,212,18,76
Long Creek Mills,Royal 2,ES5550,4,54,100
Long Creek Mills,Royal,ES0806,4,86,156
Long Creek Mills,Russet 2,ES0363,124,26,60
Long Creek Mills,Russet 3,ES1243,116,2,44
Long Creek Mills,Saffron 2,ES0650,244,102,36
Long Creek Mills,Saffron 3,ES0651,244,114,36
Long Creek Mills,Saffron,ES0134,244,102,36
Long Creek Mills,Salem Blue,ES0142,4,54,92
Long Creek Mills,Sand,ES1160,252,242,220
Long Creek Mills,Sapphire 2,ES0417,4,90,172
Long Creek Mills,Sapphire,ES0385,4,102,180
Long Creek Mills,Saxon Blue,ES0404,100,146,188
Long Creek Mills,Seafoam,ES1615,4,166,124
Long Creek Mills,Seagrass,ES0956,124,126,44
Long Creek Mills,Seashell,ES0303,244,226,212
Long Creek Mills,Seaweed,ES0845,124,130,44
Long Creek Mills,Seedling,ES0984,204,226,172
Long Creek Mills,Shrimp,ES0309,244,134,164
Long Creek Mills,Shutter Green,ES0449,4,126,108
Long Creek Mills,Sienna,ES0146,228,142,76
Long Creek Mills,Silver,ES1707,188,194,196
Long Creek Mills,Silver Green,ES0962,188,202,172
Long Creek Mills,Silver Lining,ES0829,204,206,204
Long Creek Mills,Silver Moon,ES0107,156,174,180
Long Creek Mills,Slate Blue 2,ES0405,52,126,164
Long Creek Mills,Slate Blue 3,ES0541,100,138,172
Long Creek Mills,Slate Blue,ES0382,140,166,204
Long Creek Mills,Smoky Taupe,ES0836,140,118,100
Long Creek Mills,Soft Buff,ES0301,252,234,220
Long Creek Mills,Spa Blue,ES5554,116,178,220
Long Creek Mills,Spring Green,ES0021,236,230,20
Long Creek Mills,Spruce,ES0995,28,90,60
Long Creek Mills,Stainless Steel,ES5559,212,206,204
Long Creek Mills,Straw,ES1145,228,190,132
Long Creek Mills,Sunflower,ES4117,252,214,4
Long Creek Mills,Surf Blue,ES5555,4,130,172
Long Creek Mills,Swamp Green,ES0953,132,142,52
Long Creek Mills,Tan 2,ES1146,228,214,180
Long Creek Mills,Tan 3,ES1148,204,186,156
Long Creek Mills,Tan,ES0814,236,210,172
Long Creek Mills,Tangerine,ES0646,252,186,36
Long Creek Mills,Taupe,ES0815,220,202,156
Long Creek Mills,Tea Green,ES0947,180,222,180
Long Creek Mills,Teak,ES0890,92,38,4
Long Creek Mills,Teal,ES0825,4,146,132
Long Creek Mills,Tulip 2,ES0388,172,142,196
Long Creek Mills,Tulip 3,ES1324,140,114,180
Long Creek Mills,Tulip,ES0343,180,154,204
Long Creek Mills,Turquoise 2,ES0903,100,198,196
Long Creek Mills,Turquoise 3,ES0906,4,166,156
Long Creek Mills,Turquoise 4,ES0961,124,182,172
Long Creek Mills,Turquoise,ES0138,36,190,180
Long Creek Mills,Turquoise Green 3,ES0688,4,146,156
Long Creek Mills,Turquoise Green 4,ES0904,148,206,188
Long Creek Mills,Turquoise Green,ES0443,4,146,156
Long Creek Mills,Tusk,ES0627,252,234,204
Long Creek Mills,Twig 2,ES1527,92,26,4
Long Creek Mills,Twig,ES0888,116,58,44
Long Creek Mills,Verde Green,ES0990,4,166,84
Long Creek Mills,Vintage Grapes 2,ES1331,76,74,156
Long Creek Mills,Vintage Grapes,ES1031,44,50,148
Long Creek Mills,Violet Blue,ES0381,124,154,204
Long Creek Mills,Volcano,ES0675,124,130,132
Long Creek Mills,Wheat 2,ES0612,252,234,148
Long Creek Mills,Wheat,ES0602,244,230,140
Long Creek Mills,White,ES0010,0,0,0
Long Creek Mills,Wicker,ES0819,204,158,132
Long Creek Mills,Windjammer,ES0409,36,134,196
Long Creek Mills,Yellow,ES0633,244,234,68
Long Creek Mills,Yellow Rose 2,ES0635,244,238,100
Long Creek Mills,Yellow Rose,ES0605,252,230,100
Long Creek Mills,Zinc,ES1710,156,158,164
Panton,Pink Cascade,9026,249,221,214
Panton,Light Pink,5543,245,222,214
Panton,Pink,5523,252,191,201
Panton,Dusty Rose,5675,255,163,178
Panton,Petal Pink,7701,247,191,191
Panton,Pink Joy,9030,252,201,198
Panton,Pink Sham,9078,252,173,175
Panton,Ginger Jar,9080,247,209,204
Panton,Winter Almond,9069,247,217,204
Panton,Grape,5572,242,209,191
Panton,Wild Ginseng,9045,232,191,186
Panton,Salmon,5599,206,137,140
Panton,Heather Mist,9070,232,191,186
Panton,Toasted Champagne,9063,219,168,165
Panton,Toasted Champagne,5780,186,119,95
Panton,Fairy Tale Pink,9015,219,130,140
Panton,Pink Pompas,9025,219,130,140
Panton,Maven Maud,9164,232,135,142
Panton,Comfort Pink,9077,178,107,112
Panton,Mountain Rose,5795,249,178,183
Panton,Rose Cerise,5544,252,140,153
Panton,Carnation,5537,252,94,114
Panton,Dancing Salmon,9073,249,186,170
Panton,Shrimp,5546,249,142,153
Panton,Scalloped Coral,9065,229,86,109
Panton,Bitteroot,7709,244,63,79
Panton,Burgundy,5549,140,38,51
Panton,Warm Wine,5796,117,38,61
Panton,Russet,5552,140,38,51
Panton,Wine,5525,112,35,66
Panton,Salvia Plum,9055,109,33,63
Panton,Maroon,5676,124,30,63
Panton,Intense Maroon,5887,109,33,63
Panton,Royal Crest,9162,109,33,63
Panton,Cabernet,5794,231,105,135
Panton,Passion Rose,5899,229,52,118
Panton,Hot Pink,5560,170,0,102
Panton,Perfect Ruby,5797,147,0,66
Panton,Cherry Stone,5804,170,0,79
Panton,Ruby Glint,5561,173,0,91
Panton,Horizon Pink,9168,249,79,142
Panton,Begonia,5528,244,84,124
Panton,Wild Romance,9007,244,84,124
Panton,Azalea,7712,229,76,124
Panton,Rose Pink,5806,229,76,124
Panton,Pink Bleeding Heart,9012,209,0,86
Panton,Strawberry,5732,211,5,71
Panton,Devil Red,7706,175,0,61
Panton,Cherry Punch,5717,175,0,61
Panton,Candy Apple Red,5807,193,5,56
Panton,Red Coral Bell,9013,175,0,61
Panton,Hollyhock Red,9006,163,38,56
Panton,Toasty Red,9002,175,30,45
Panton,Wild Fire,5567,193,5,56
Panton,Red,5678,163,38,56
Panton,Jockey Red,5581,191,10,48
Panton,Radiant Red,5566,196,30,58
Panton,Red Berry,5718,191,10,48
Panton,Very Red,5719,196,30,58
Panton,Foxy Red,5563,206,17,38
Panton,Lipstick,5533,206,17,38
Panton,Miami Artillery,9170,214,40,40
Panton,Scarlet,5519,191,10,48
Panton,Deep Scarlet,5811,191,10,48
Panton,Cranberry,5570,153,33,53
Panton,Carolina Red,5568,153,33,53
Panton,Bisque,5677,242,209,191
Panton,Flesh Pink,5553,249,186,170
Panton,Flamingo,5558,249,137,114
Panton,Melon,5594,249,137,114
Panton,Melonade,7812,249,137,114
Panton,Oriental Poppies,9058,249,96,58
Panton,Honeysuckle,7713,209,68,20
Panton,Orange Glory,9056,165,63,15
Panton,Out of the Blue,9029,214,216,211
Panton,Blue Joy,9032,193,201,221
Panton,Ice Blue,5600,181,209,232
Panton,Cameron Blue,9089,155,196,226
Panton,Sun Blue,5569,181,209,232
Panton,Rockport Blue,5836,119,150,178
Panton,Pastel Blue,5682,155,196,226
Panton,Heron Blue,5825,147,183,209
Panton,Sky Blue,5539,168,206,226
Panton,Baby Blue,5506,147,183,209
Panton,Cristy Blue,5683,102,147,188
Panton,Lake Blue,5604,153,186,221
Panton,Blue Splendor,9039,117,170,219
Panton,Ultra Blue,5733,117,178,221
Panton,Tropic Blue,5734,117,170,219
Panton,Oriental Blue,5601,102,137,204
Panton,Blue Moon,9081,102,147,188
Panton,Copen,5545,58,117,196
Panton,China Blue,5823,0,132,201
Panton,Slate Blue,5575,94,130,163
Panton,Ash,5641,58,73,114
Panton,Favorite Deep Blue,9075,38,84,124
Panton,Wonder Blue,5877,94,153,170
Panton,Mid Windsor,5820,71,153,182
Panton,California Blue,5689,0,163,221
Panton,Cerulean,5801,0,142,214
Panton,Baltic Blue,5741,0,84,160
Panton,Dolphin Blue,5829,0,137,197
Panton,Blue,5520,12,92,146
Panton,Jay Blue,5684,89,96,168
Panton,Imperial Blue,5602,51,86,135
Panton,Fleet Blue,5750,12,28,71
Panton,Blue Ribbon,5739,0,38,84
Panton,Blue Ink,5740,17,33,81
Panton,Light Navy,5603,20,33,61
Panton,Light Navy,5824,17,33,81
Panton,Light Midnight,5686,12,28,71
Panton,Navy,5515,12,28,71
Panton,Midnight Navy,5687,12,28,71
Panton,Sapphire,5580,0,56,147
Panton,Blue Suede,5738,45,51,142
Panton,Fire Blue,5736,30,28,119
Panton,Royal,5510,45,51,142
Panton,Jamie Blue,5685,48,68,181
Panton,Empire Blue,5737,48,68,181
Panton,Nikko Blue,9022,25,33,104
Panton,Chow Blue,9171,28,20,107
Panton,Purple Twist,5729,63,40,147
Panton,Paris Blue,5583,175,188,219
Panton,Amanda Lavender,9048,91,119,204
Panton,Sterlling,5706,168,147,173
Panton,Lucky Lavender,9064,168,147,173
Panton,Tulip,5586,206,163,211
Panton,Tulip Lavender,9167,158,145,198
Panton,Mauve,5587,137,119,186
Panton,Dark Melody,9031,86,0,140
Panton,Livid Lavender,9166,102,86,188
Panton,Purple Chariot,9049,73,48,173
Panton,Purple Maze,5728,56,25,122
Panton,Vanessa Purple,9057,79,0,147
Panton,Deep Purple,5803,63,0,119
Panton,Purple Accent,5731,79,33,112
Panton,Regal Purple,9021,89,17,142
Panton,May Nights,9053,68,35,94
Panton,Dark Purple,5681,79,33,112
Panton,Mod Purple,9071,102,17,109
Panton,Purple,5554,91,2,122
Panton,Iris,5588,122,30,153
Panton,Cindy Purple,9088,170,114,191
Panton,Popular Purple,9019,112,53,114
Panton,Poker Primrose,9011,181,140,178
Panton,Plum,5592,155,79,150
Panton,Arden Lavender,9067,201,173,216
Panton,Russian Sage,9016,198,163,193
Panton,Pansy Purple,9098,173,135,153
Panton,Dwarf Lilac,9009,211,165,201
Panton,Violet,5585,242,186,211
Panton,Liatris Lavender,9004,244,191,209
Panton,Siberian iris,9041,229,196,214
Panton,Fantasia Pink,9044,244,201,201
Panton,Le Reve Pink,9040,252,191,201
Panton,Exclusive Pink,9074,249,191,193
Panton,Pink Sherbert,9036,255,160,204
Panton,Pink Splendor,9037,255,160,204
Panton,Wild Pink,5559,255,119,168
Panton,New Berry,5800,173,0,117
Panton,Rich Pink,9097,160,45,150
Panton,Passion,5591,170,0,102
Panton,Raspberry Ice,9017,135,0,91
Panton,Purple Ice,9027,142,5,84
Panton,Aubergine,9046,119,45,107
Panton,Pillow Blue,9059,130,198,226
Panton,Misty,5608,102,147,188
Panton,Bambino Blue,9079,81,181,224
Panton,Blue Fringe,9054,0,160,186
Panton,Marine Aqua,5607,0,160,186
Panton,Blue Wisteria,9052,0,127,153
Panton,Surf Blue,5819,0,127,153
Panton,Angela Blue,9060,0,153,181
Panton,Mallard Blue,5821,0,109,117
Panton,Peacock,5810,0,84,107
Panton,Mountainview,9105,0,130,155
Panton,Southampton,9143,38,104,109
Panton,Paradise Green,9104,0,73,79
Panton,Perpetual Teal,9062,0,68,89
Panton,Venus Blue,9100,0,63,84
Panton,Light Blue,5522,201,232,221
Panton,Shallow Green,9101,204,226,221
Panton,Sprite,5613,170,196,191
Panton,Nautical Teal,9076,165,221,226
Panton,Alaska Sky,9138,165,221,226
Panton,Herbal Blue,9103,140,204,211
Panton,Mint Julep,5610,170,221,214
Panton,Sea Glass,9141,86,201,193
Panton,Turquoise,5504,0,135,137
Panton,Mystic Teal,5743,0,114,114
Panton,Teal,5609,0,114,114
Panton,Teal,5792,0,178,170
Panton,Oceanic Green,5746,0,132,142
Panton,Blue Appeal,9139,0,119,112
Panton,Tempest Turq,9102,0,135,137
Panton,Breath Of Spring,9140,0,140,130
Panton,Breath Of Spring,5745,0,178,170
Panton,Dark Teal,5809,0,140,130
Panton,Pine Green,5691,0,140,130
Panton,Sea Water,9173,0,140,130
Panton,Inner Sanctum,9142,0,109,102
Panton,Blue Spruce,5849,0,73,63
Panton,Newport,5850,79,109,94
Panton,Endicott Bay,9145,5,112,94
Panton,Green Bay,5755,38,102,89
Panton,Moss,5578,150,170,153
Panton,Palm Leaf,5541,198,204,186
Panton,Willow,5521,114,132,112
Panton,Kiwi Green,9107,119,145,130
Panton,Olive,5502,127,160,140
Panton,Water Lilly,5854,91,135,114
Panton,Dress Green,5884,94,102,58
Panton,Harbor Green,5692,43,76,63
Panton,Ivy,5852,35,79,51
Panton,Special Green,5805,2,73,48
Panton,Dark Army Green,5853,66,71,22
Panton,Dark Army Green,7711,35,58,45
Panton,Alpine Green,9151,73,89,40
Panton,Field Green,5760,33,61,48
Panton,Green Sail,5759,25,56,51
Panton,Teal Appeal,9146,0,53,58
Panton,Pale Green,5618,188,219,204
Panton,Sea Mist,5693,135,221,209
Panton,Green Pearl,5752,86,201,193
Panton,Seafoam,5611,112,206,155
Panton,Tealeaf,9106,150,216,175
Panton,Isle Green,5612,0,135,114
Panton,Cone Forest,9144,0,158,96
Panton,Jade,5813,0,122,94
Panton,Peppermint,5690,0,153,135
Panton,Green Stone,5748,0,130,114
Panton,Fern Green,5749,0,119,112
Panton,Green Forest,5751,0,107,91
Panton,Evergreen,5615,38,81,66
Panton,Latex Green,9169,2,73,48
Panton,Green Petal,5758,25,94,71
Panton,Holly,5623,35,79,51
Panton,Deep Green,5584,33,91,51
Panton,Green,5509,58,119,40
Panton,Irish Green,5812,0,124,89
Panton,Dark Green,5508,0,107,63
Panton,Conner Green,9092,0,135,81
Panton,Veggie Green,9091,0,158,96
Panton,Light Kelly,7710,0,122,61
Panton,Kelly,5540,61,142,51
Panton,Emerald,5514,51,158,53
Panton,Pastel Green,5855,211,232,163
Panton,Mint,5538,198,214,160
Panton,Slightly Green,9149,170,221,150
Panton,Green Oak,5619,160,219,142
Panton,Nile,5511,112,206,155
Panton,Glendale,9153,181,204,142
Panton,Peapod,5756,163,175,7
Panton,Pastoral Green,5621,170,221,109
Panton,Envy Green,9108,163,175,7
Panton,Rolling Meadow,9148,96,198,89
Panton,Enventide Green,9147,30,181,58
Panton,Spruce,5579,96,142,58
Panton,Green Dust,5757,112,147,2
Panton,Ming,5622,86,142,20
Panton,Erin Green,5620,127,186,0
Panton,Limerick,9121,158,153,89
Panton,Tamarack,5530,153,142,7
Panton,Foliage Green,5842,150,140,40
Panton,Meilee Green,9118,181,168,12
Panton,Daiqueri Ice,9120,181,170,89
Panton,Finch,9035,221,206,17
Panton,Black Eyed Susie,5861,249,221,22
Panton,Cloth Of Gold,9005,181,155,12
Panton,Cheviot Gold,9124,191,145,12
Panton,Golden Slipper,9084,153,135,20
Panton,Autumn Green,5843,163,130,5
Panton,Allegheny,9119,112,91,10
Panton,Cone,9154,132,130,5
Panton,Palmetto,5529,107,112,43
Panton,Mosstone,9150,112,147,2
Panton,Meadow,5526,86,107,33
Panton,Bonaire Green,9152,84,119,48
Panton,Olive Drab,5617,94,102,58
Panton,Beau Geste,9122,73,68,17
Panton,Castlewalk Green,9155,84,71,45
Panton,Green Ice,9018,242,237,158
Panton,Coronation Gold,9014,244,226,135
Panton,Lemon,5625,244,237,71
Panton,Celery,5616,247,240,201
Panton,Lemon Fluff,9003,244,219,96
Panton,Daffodil,5626,249,221,22
Panton,Sunflower,5762,249,221,22
Panton,Golden Stargazor,9051,249,214,22
Panton,Moonbeam,5860,249,224,76
Panton,Ombre Gold,9001,252,209,22
Panton,Canary,5535,249,214,22
Panton,Manila,5766,234,175,15
Panton,Goldenrod,5542,252,209,22
Panton,Warm Sunshine,9172,255,198,30
Panton,Pollen Gold,5856,198,127,7
Panton,Day Lilly,9010,198,147,10
Panton,Star Gold,5708,255,198,30
Panton,Cornsilk,5695,252,191,73
Panton,Scholastic,5765,252,181,20
Panton,Pooh,9109,255,204,73
Panton,Brite Yellow,5696,252,191,73
Panton,Nectar,5764,252,191,73
Panton,Merit Gold,5763,252,181,20
Panton,Marigold,5516,252,209,22
Panton,Mango,5694,252,186,94
Panton,Sun Gold,5512,216,140,2
Panton,Karat,5770,216,140,2
Panton,Yellow Mist,5709,252,163,17
Panton,Yellow,5513,226,140,5
Panton,Golden Chair,9050,234,175,15
Panton,Mustard,5631,239,178,45
Panton,Copper,5595,188,109,10
Panton,Grilled Orange,9072,249,86,2
Panton,Orangeade,5767,226,61,40
Panton,Paprika,5536,249,63,38
Panton,Vibrant Orange,9066,249,63,38
Panton,Indian Summer,9023,239,43,45
Panton,Saffron,5629,214,40,40
Panton,Scarlet Flame,9020,206,17,38
Panton,Auburn,5772,175,30,45
Panton,Terra Cotta,5634,175,38,38
Panton,Dark Rust,5505,193,56,40
Panton,Summer Splendor,9061,249,142,109
Panton,Complex Orange,9068,252,158,112
Panton,Tawny,5556,249,191,158
Panton,Shangri La,9047,255,183,119
Panton,Rust,5589,198,96,5
Panton,Deviled Orange,9038,252,135,68
Panton,Orange,5518,232,117,17
Panton,Golden Poppy,5630,232,117,17
Panton,Sunburst,9008,232,117,17
Panton,Dark Texas Orange,5769,249,99,2
Panton,Visor Gold,5698,252,186,94
Panton,Ashley Gold,5701,237,160,79
Panton,Topaz,5700,242,198,140
Panton,Honey,5547,252,173,86
Panton,Almond,5779,204,122,2
Panton,Toast,5531,226,140,5
Panton,Hazel,5781,188,94,30
Panton,Date,5590,155,79,25
Panton,Chocolate,5527,117,56,2
Panton,Sienna,5702,99,58,17
Panton,Wheat,5761,249,224,140
Panton,Maize,5564,255,216,127
Panton,Glow,5534,255,216,127
Panton,Pistachio,5550,204,191,142
Panton,Tommy Tan,9123,204,191,142
Panton,Golden Tan,5870,193,168,117
Panton,Ginger,5633,191,145,12
Panton,Shimmering Gold,5771,181,140,10
Panton,Old Gold,5501,163,127,20
Panton,Temple Gold,9165,198,147,10
Panton,Terry Tan,9131,209,142,84
Panton,Sweet Dreams,9130,186,117,48
Panton,Primedor,9132,232,178,130
Panton,Rice Paper,9125,193,168,117
Panton,Penny,5632,239,178,45
Panton,Candy Tan,9094,244,219,170
Panton,Taupe,5598,193,168,117
Panton,Rattan,5774,193,142,96
Panton,French Toast,9086,196,153,119
Panton,Beige,5524,170,117,63
Panton,Bronze,5815,117,84,38
Panton,Sand Dune,5777,91,71,35
Panton,Bali,9136,211,168,124
Panton,Tan,5573,211,168,124
Panton,Ivory,5635,250,232,207
Panton,Seashell,5776,209,191,145
Panton,Ecru,5532,237,211,188
Panton,Coast Point,9160,244,196,160
Panton,Opaline,5773,244,196,160
Panton,Cocoa Mulch,5788,132,63,15
Panton,Light Cocoa,5778,140,89,51
Panton,Lucrene,9133,117,84,38
Panton,New Gold,5699,249,201,163
Panton,Foundation,9034,255,211,170
Panton,Bamboo,5638,234,170,122
Panton,Gold,5503,232,178,130
Panton,Wicker,5789,209,142,84
Panton,Amber Beige,5636,186,117,48
Panton,Sonesta Brown,9156,96,51,17
Panton,Brownstone,9042,109,51,33
Panton,Coffee Bean,5639,81,38,28
Panton,Brown,5551,89,61,43
Panton,Espresso,5637,61,48,40
Panton,Mahogany,5864,61,51,43
Panton,Cajun Mist,9137,117,84,38
Panton,Dark Brown,5672,76,40,15
Panton,Happy Trail,9087,178,130,96
Panton,Carbondale,9128,175,137,112
Panton,Decorator Tan,9135,181,145,124
Panton,Basket Beige,9126,206,193,181
Panton,Turkish Tan,9134,168,153,140
Panton,Mars Green,9129,119,114,99
Panton,Gray Wool,9158,68,61,56
Panton,Smokey,5787,2,40,58
Panton,Vassar Chic,9111,102,109,112
Panton,Black Chrome,5841,40,45,38
Panton,Aged Charcoal,5865,104,102,99
Panton,Metal,5707,102,109,112
Panton,Twilight,5517,145,150,147
Panton,Cinder,5704,145,150,147
Panton,Bellaire Gray,9110,150,147,142
Panton,Silvery Gray,5784,137,142,140
Panton,Delano Gray,9112,155,153,147
Panton,Coal Hill,9163,140,112,107
Panton,Storm Gray,5786,188,165,158
Panton,Fairview Gray,9114,145,150,147
Panton,Cloud,5783,181,178,170
Panton,Melville,9113,191,186,175
Panton,GS Gray,5802,150,147,142
Panton,Gray Flannel,9117,130,127,119
Panton,Charcoal,5565,68,61,56
Panton,Skylight,5782,186,183,175
Panton,Saturn Gray,5785,196,193,186
Panton,Chrome,5839,232,226,214
Panton,Storm Gail,9090,186,191,183
Panton,Otter Gray,9115,137,142,140
Panton,Teardrop Gray,9116,222,217,219
Panton,Oyster,5703,226,204,186
Panton,Raindrop,9095,219,211,211
Panton,Hi Ho Silver,9082,224,201,204
Panton,Titanium,9083,232,214,222
Panton,Gray,5507,188,165,158
Panton,TH Gold,5906,163,127,20
Panton,Pearl Gray,5640,211,206,196
Panton,Dover Gray,5705,204,193,198
Panton,Millennium,9096,145,150,147
Panton,Steel Gray,5574,188,165,158
Panton,Granite,9099,140,130,153
Panton,Ducky Mauve,5722,132,73,73
Panton,Satin Wine,5614,181,147,155
Panton,Black,5596,28,38,48
Panton,Eggshell,5643,247,237,212
Panton,Ice Ballet,9028,242,227,196
Panton,Beige Delight,9024,247,237,222
Panton,Natural White,5642,255,255,255
Panton,Snow White,5597,255,255,255
Panton,Neon Pink,5711,252,117,142
Panton,Cheeky Pink,9161,244,71,107
Panton,Neon Red,5712,249,94,89
Panton,Hot Cha Cha,9159,249,89,81
Panton,Neon Orange,5710,255,114,71
Panton,Singh Mist,9157,255,147,56
Panton,Havana Yellow,9127,255,204,30
Panton,Stunning Yellow,9085,234,237,53
Panton,Neon Yellow,5713,206,224,7
Panton,Neon Green,5814,96,221,73
Panton,TH Green,5907,0,107,91
Panton,TH Burgundy,5908,124,33,40
Panton,TH Navy,5909,17,33,81
Isacord,Silky White,10,255,255,250
Isacord,White,15,255,255,255
Isacord,Paper White,17,248,255,255
Isacord,Black,20,000,000,000
Isacord,Eggshell - off-white,101,255,255,232
Isacord,Cobblestone - grey,108,117,122,133
Isacord,Whale - grey,111,084,097,094
Isacord,Leadville - grey,112,117,112,117
Isacord,Fieldstone - grey,124,240,243,243
Isacord,Smoke - dark grey,131,227,220,225
Isacord,Dark Pewter - Dark Gray,132,040,069,076
Isacord,Sterling - silver grey,142,204,209,207
Isacord,Skylight - palest blue,145,220,227,235
Isacord,Mystik Grey - lt grey brown,150,240,240,225
Isacord,Cloud - light grey,151,235,232,220
Isacord,Dolphin - dark grey,152,130,120,135
Isacord,Sea Shell,170,212,210,191
Isacord,Fog,176,222,221,213
Isacord,Whitewash - blush pink,180,255,245,238
Isacord,Saturn Grey - pale lavender,182,227,220,240
Isacord,Pearl - light grey,184,248,238,253
Isacord,Light Brass - gold,221,240,255,066
Isacord,Seaweed - lt khaki green,232,217,255,120
Isacord,Lemon Frost - pale yellow,250,248,248,192
Isacord,Buttercream - yellow beige,270,255,255,227
Isacord,Yellow - lemon yellow,310,255,255,112
Isacord,Canary - orange yellow,311,255,238,015
Isacord,Moss - brownish green,345,140,151,046
Isacord,Marsh - lt khaki green,352,197,232,102
Isacord,Tarnished Gold - khaki green,442,166,189,040
Isacord,Army Drab - lt khaki green,453,133,174,076
Isacord,Cypress - olive grey,463,128,194,145
Isacord,Umber - brownish green,465,038,064,000
Isacord,Sun - yellow - neon,501,255,255,000
Isacord,Mimosa,504,225,200,049
Isacord,Yelow Bird - gold,506,255,238,035
Isacord,Daffodil - yellow gold,520,255,255,184
Isacord,Champagne - creamy beige,532,238,230,122
Isacord,Ochre - bronze,542,217,215,030
Isacord,Ginger - khaki green,546,204,215,000
Isacord,Flax - khaki green,552,194,184,081
Isacord,Citrus - yellow,600,255,245,038
Isacord,Daisy - yellow,605,255,240,000
Isacord,Sunshine - Yellow,608,255,240,012
Isacord,Star Gold,622,218,197,086
Isacord,Buttercup - gold,630,255,250,179
Isacord,Parchment - pale gold,640,255,250,145
Isacord,Cornsilk - gold,651,255,243,176
Isacord,Vanilla - cream,660,253,253,202
Isacord,Cream - light beige,670,253,253,215
Isacord,Baquette - pale grey gold,672,230,240,189
Isacord,Bright Yellow - orange yellow,700,255,232,030
Isacord,Papaya - mid gold,702,248,227,005
Isacord,Gold - darker gold,704,255,230,000
Isacord,Sunflower - lt orange - neon,706,255,207,000
Isacord,Lemon - gold,713,255,243,084
Isacord,Khaki - burnished brown,722,197,181,128
Isacord,Golden Brown - brownish green,747,097,099,000
Isacord,Oat - lt grey brown,761,255,255,207
Isacord,Rattan,771,214,198,159
Isacord,Sage - burnished brown,776,128,112,094
Isacord,Golden Rod - orange gold,800,255,211,005
Isacord,Candlelight - copper,811,255,217,048
Isacord,Honey Gold - brass,821,245,212,035
Isacord,Palomino - khaki green,822,232,222,064
Isacord,Liberty Gold - gold,824,238,217,012
Isacord,Sisal - pale brown,832,240,215,076
Isacord,Toffee - pale brown,842,202,174,033
Isacord,Old Gold - gold,851,255,217,112
Isacord,Pecan - brown,853,145,133,033
Isacord,Tantone - Ecru,861,230,227,179
Isacord,Wild Rice - Dark Tan,862,204,197,156
Isacord,Muslin - beige,870,253,255,212
Isacord,Stone - med grey brown,873,202,197,143
Isacord,Gravel - pale brown,874,217,204,176
Isacord,Spanish Gold - light orange,904,248,190,000
Isacord,Ashley Gold - light brown,922,227,192,028
Isacord,Honey - dark gold,931,209,174,000
Isacord,Nutmeg - rust brown,932,220,156,017
Isacord,Redwood - brown,933,102,051,000
Isacord,Fawn - pale brown,934,192,163,066
Isacord,Autumn Leaf - dark gold,940,230,202,000
Isacord,Golden Grain - brown,941,194,176,043
Isacord,Pine Park - brown,945,097,074,033
Isacord,Linen - beige,970,255,255,204
Isacord,Toast,1010,205,154,077
Isacord,Bark - brown,1055,084,058,030
Isacord,Shrimp Pink - flesh,1060,255,225,138
Isacord,Taupe - med grey brown,1061,220,184,110
Isacord,Pumpkin - orange,1102,255,156,010
Isacord,Orange - neon,1106,255,076,000
Isacord,Clay - brown orange,1114,255,148,046
Isacord,Copper - rust brown,1115,204,115,010
Isacord,Sunset - med orange - neon,1120,255,151,000
Isacord,Caramel Cream - pale brown,1123,192,174,094
Isacord,Light cocoa - brown,1134,122,071,030
Isacord,Meringue - creamy beige,1140,255,246,168
Isacord,Tan - brownish cream,1141,253,232,181
Isacord,Penny - medium brown,1154,143,79,000
Isacord,Straw,1161,206,183,149
Isacord,Ivory - pale grey gold,1172,240,238,145
Isacord,Apricot - tangerine,1220,225,153,043
Isacord,Dark Tan,1252,180,145,122
Isacord,Tangerine - orange,1300,255,102,000
Isacord,Paprika - dark peach,1301,232,066,000
Isacord,Red Pepper - orange,1304,240,071,000
Isacord,Fox Fire - orange,1305,255,079,000
Isacord,Devil Red - tangerine - neon,1306,255,000,000
Isacord,Date - rich brown,1311,207,087,005
Isacord,Burnt Orange - rich brown,1312,181,048,000
Isacord,Harvest - brown orange,1332,230,117,040
Isacord,Spice - red brown,1334,174,046,012
Isacord,Dark Rust - red brown,1335,184,053,017
Isacord,Rust - mid brown,1342,171,084,000
Isacord,Coffee Bean,1344,099,054,054
Isacord,Cinnamon - darker brown,1346,056,000,000
Isacord,Starfish - darker peach,1351,255,187,125
Isacord,Salmon - orange peach,1352,255,166,092
Isacord,Fox - dark brown,1355,079,000,000
Isacord,Shrimp - sand,1362,255,212,089
Isacord,Mahogany - dark brown,1366,038,000,000
Isacord,Dark Charcoal - very dark grey,1375,043,035,048
Isacord,Melon - peach,1430,250,133,058
Isacord,Watermelon - neon,1501,255,000,000
Isacord,Brick - rich brown,1514,192,043,000
Isacord,Flamingo - blush,1521,243,120,084
Isacord,Coral - pink peach,1532,255,180,155
Isacord,Pink Clay - peach,1551,255,204,174
Isacord,Espresso - dk burnished brown,1565,138,104,058
Isacord,Spanish Tile - blush,1600,227,122,074
Isacord,Red Berry - reddish orange,1701,232,051,000
Isacord,Poppy - red,1703,255,038,033
Isacord,Candy Apple - watermellon,1704,255,030,012
Isacord,Terra Cotta - deep blush,1725,202,071,038
Isacord,Persimmon,1730,197,054,079
Isacord,Hyacinth - brownish pink,1755,240,204,235
Isacord,Twine - brownish cream,1760,240,204,192
Isacord,Tea Rose - brownish pink,1761,238,189,161
Isacord,Wildfire - deep red,1800,217,002,017
Isacord,Strawberry - deep blush,1805,222,017,053
Isacord,Corsage - peach pink,1840,255,158,128
Isacord,Shell - mid pink,1860,255,225,238
Isacord,Pewter - burnished brown,1874,084,066,069
Isacord,Chocolate - brownish green,1876,046,023,000
Isacord,Geranium - pink red,1900,215,000,043
Isacord,Poinsettia - dark red,1902,168,000,000
Isacord,Lipstick - dark red,1903,222,000,005
Isacord,Cardinal - rich red,1904,204,038,035
Isacord,Tulip - red pink,1906,174,000,010
Isacord,Foliage Rose - rich red,1911,148,000,020
Isacord,Winterberry - plum,1912,071,000,005
Isacord,Cherry - red brown,1913,151,000,058
Isacord,Blossom - dark pink,1921,171,076,076
Isacord,Chrysantemun - pink - neon,1940,225,061,220
Isacord,Tropical Pink - rose - neon,1950,225,000,074
Isacord,Silvery Grey - dark grey,1972,181,181,181
Isacord,Fire Engine - deep blush,2011,153,033,058
Isacord,Rio Red - deep blush,2022,128,069,064
Isacord,Teaberry - mauve pink,2051,215,145,186
Isacord,Country Red - dark red,2101,163,000,048
Isacord,Cranberry - rich red,2113,130,002,046
Isacord,Beet Red - dark maroon,2115,064,025,043
Isacord,Bordeaux - dark plum,2123,064,020,020
Isacord,Heather Pink - plum pink,2152,235,112,158
Isacord,Dusty Mauve - mauve,2153,255,163,197
Isacord,Pink Tulip - bisque,2155,255,171,199
Isacord,Iced Pink - pink,2160,253,215,245
Isacord,Flesh - pale pink,2166,238,212,227
Isacord,Chiffon - beige pink,2170,248,222,235
Isacord,Blush - pale pink,2171,253,227,255
Isacord,Tropicana - dark pink,2220,248,081,122
Isacord,Burgundy - plum,2222,125,000,038
Isacord,Claret - rose,2224,133,040,043
Isacord,Mauve - plum pink,2241,179,102,117
Isacord,Petal Pink - mauve pink,2250,253,215,250
Isacord,Bright Ruby - deep pink,2300,235,043,140
Isacord,Raspberry - deep pink,2320,212,046,156
Isacord,Wine - dark plum,2333,097,023,051
Isacord,Maroon - dark plum,2336,048,002,015
Isacord,Carnation - pale pink,2363,253,225,255
Isacord,Boysenberry - plum,2500,122,000,084
Isacord,Plum - med purple,2504,166,048,122
Isacord,Cerise - deep plum,2506,102,000,043
Isacord,Roseate,2510,159,071,140
Isacord,Garden Rose - pink,2520,240,056,197
Isacord,Fuschia - deep pink,2521,225,033,181
Isacord,Rose,2530,221,147,173
Isacord,Soft Pink - darker pink,2550,240,115,245
Isacord,Azalea Pink - pink,2560,255,145,240
Isacord,Greyhound - dark grey,2576,074,069,087
Isacord,Dusty Grape - mid purple,2600,151,071,168
Isacord,Frosted Plum - pinkish lilac,2640,220,138,255
Isacord,Impatiens lavender,2650,225,192,248
Isacord,Aura - pale lavender,2655,238,209,250
Isacord,Steel - dark grey,2674,166,181,179
Isacord,Dark Current - dark purple,2711,089,000,058
Isacord,Pansy - deep purple,2715,071,000,025
Isacord,Sangria - light purple,2720,115,000,079
Isacord,Very Berry,2721,144,060,135
Isacord,Dessert,2761,199,073,084
Isacord,Violet - darker lilac,2764,209,128,194
Isacord,Orchid - purple,2810,140,043,104
Isacord,Wild Iris - purple,2830,186,156,253
Isacord,Easter Purple,2832,107,057,136
Isacord,Deep Purple - jacaranda,2900,076,000,115
Isacord,Iris Blue - jacaranda,2905,145,028,125
Isacord,Grape - purple,2910,189,084,217
Isacord,Sugar Plum,2912,135,092,055
Isacord,Purple - purple,2920,171,102,163
Isacord,Lavender,3040,199,168,248
Isacord,Cachet - darker lilac,3045,207,153,255
Isacord,Cinder - dark grey,3062,117,122,143
Isacord,Provence - ultra marine,3102,000,000,079
Isacord,Dark Ink - ultra marine,3110,099,000,110
Isacord,Purple Twist - ultra marine,3114,058,000,084
Isacord,Stainless,3150,196,188,211
Isacord,Blue Dawn,3151,181,181,214
Isacord,Blueberry - jacaranda,3210,097,000,145
Isacord,Twilight - ultra marine,3211,158,079,156
Isacord,Amethyst Frost - light violet,3241,176,117,202
Isacord,Haze - light lilac,3251,199,156,217
Isacord,Delft - aubergine,3323,000,000,092
Isacord,Cadet Blue - light blue,3331,197,171,240
Isacord,Fire Blue - ultra marine,3333,040,000,102
Isacord,Flag Blue,3335,069,005,133
Isacord,Midnight - dark blue,3344,000,000,046
Isacord,Light Midnight - bright navy,3353,043,010,115
Isacord,Dark Indigo - navy,3355,000,007,079
Isacord,Concord - steel blue,3444,010,051,066
Isacord,Blue - marine blue,3522,005,074,189
Isacord,Heraldic - purple,3536,094,015,084
Isacord,Venetian Blue - jacaranda,3541,104,000,143
Isacord,Royal Blue - marine blue,3543,071,000,145
Isacord,Sapphire - marine blue,3544,033,028,117
Isacord,Navy,3554,000,000,010
Isacord,Nordic Blue - marine blue,3600,000,074,166
Isacord,Blue Ribbon - marine blue,3611,012,058,140
Isacord,Starlight Blue - marine blue,3612,130,115,179
Isacord,Marine Blue,3620,074,098,168
Isacord,Imperial Blue - marine blue,3622,000,053,158
Isacord,Lake Blue - medium blue,3640,212,220,255
Isacord,Wedgewood - blue,3641,094,135,238
Isacord,Ice Cap - silver blue,3650,235,232,255
Isacord,Baby Blue - light blue,3652,161,204,248
Isacord,Blue Bird,3710,080,115,181
Isacord,Dolphin Blue,3711,084,124,187
Isacord,Empire Blue,3722,075,114,181
Isacord,Slate Blue - dark teal blue,3732,000,028,115
Isacord,Harbor - steel blue,3743,010,076,089
Isacord,Winter Frost - sky blue,3750,212,230,255
Isacord,Winter sky - sky blue,3761,215,230,253
Isacord,Country Blue,3762,154,175,202
Isacord,Oyster - silver grey,3770,245,245,235
Isacord,Laguna - medium blue,3810,084,112,212
Isacord,Reef Blue - medium blue,3815,107,168,255
Isacord,Celestial - medium blue,3820,166,209,255
Isacord,Oxford - pastel blue,3840,209,215,250
Isacord,Copenhagen - steel blue,3842,048,120,138
Isacord,Ash Blue,3853,116,133,159
Isacord,Cerulean - teal blue,3900,043,145,248
Isacord,Tropical Blue - teal blue,3901,020,161,255
Isacord,Colonial Blue - med teal blue,3902,030,138,215
Isacord,Pacific Blue,3906,077,169,230
Isacord,Crystal Blue - pale blue,3910,171,230,227
Isacord,Chicory,3920,133,192,238
Isacord,Azure Blue - pale blue,3951,184,209,225
Isacord,Ocean Blue - medium blue,3953,071,110,135
Isacord,River Mist - pale blue,3962,225,248,255
Isacord,Silver - silver grey,3971,232,232,230
Isacord,Caribbean Blue - med teal blue,4010,005,202,215
Isacord,Teal - medium teal blue,4032,081,156,174
Isacord,Tartan Blue - steel blue,4033,000,084,115
Isacord,Glacier Green - palest blue,4071,232,248,255
Isacord,Metal - medium grey,4073,156,156,156
Isacord,Wave Blue - med teal blue,4101,104,230,232
Isacord,California Blue - turquoise,4103,000,197,238
Isacord,Turquoise - med turquoise,4111,051,235,240
Isacord,Alexis Blue - med teal blue,4113,074,212,215
Isacord,Danish Teal,4114,076,171,203
Isacord,Dark Teal,4116,012,168,179
Isacord,Peacock,4122,104,180,221
Isacord,Deep Ocean - dark teal blue,4133,000,071,094
Isacord,Charcoal - vdark drey,4174,000,035,046
Isacord,Island Green - turquoise,4220,138,240,238
Isacord,Aqua - light turquoise,4230,168,243,240
Isacord,Spearmint - very pale blue,4240,179,255,253
Isacord,Snomoon - very pale blue,4250,215,255,250
Isacord,Rough Sea,4332,113,145,159
Isacord,Aqua Velva - medium aqua,4410,010,166,130
Isacord,Light Mallard - sea green,4421,000,199,181
Isacord,Marina Aqua - aqua,4423,007,184,158
Isacord,Dark Aqua,4425,012,194,140
Isacord,Island Waters - turquoise,4430,145,235,232
Isacord,Deep Sea Blue - dk sea green,4442,012,148,135
Isacord,Truly Teal - sea green,4452,030,194,166
Isacord,Spruce - dark sea green,4515,000,081,081
Isacord,Caribbean - dark aqua,4531,000,176,145
Isacord,Deep Aqua - slate green,4610,025,207,128
Isacord,Jade - light teal green,4620,076,232,174
Isacord,Seagreen - teal,4625,048,184,130
Isacord,Amazon - sea green,4643,012,133,128
Isacord,Mallard - grey blue,4644,000,099,092
Isacord,Rain Forest - teal,5005,035,171,097
Isacord,Scotty Green - blue green,5010,000,225,168
Isacord,Luster - pale turquoise,5050,194,225,225
Isacord,Green - emerald green,5100,017,194,084
Isacord,Dark Jade - blue green,5101,058,212,151
Isacord,Baccarat Green - lt teal green,5115,138,238,176
Isacord,Trellis Green - lt teal green,5210,030,235,110
Isacord,Silver Sage - lt teal green,5220,168,255,204
Isacord,Bottle Green - lt teal green,5230,120,255,186
Isacord,Field Green - dark leaf green,5233,002,174,110
Isacord,Bright Green - med forest green,5324,000,115,046
Isacord,Evergreen - dark leaf green,5326,000,128,033
Isacord,Swamp - dark leaf green,5335,000,092,017
Isacord,Forest Green - dark leaf green,5374,000,081,048
Isacord,Scrub Green,5400,063,163,083
Isacord,Shamrock - green,5411,000,207,000
Isacord,Irish Green - green,5415,017,204,000
Isacord,Swiss Ivy - teal green,5422,000,179,000
Isacord,Limedrop - green - neon,5500,066,255,000
Isacord,Emerald - med leaf green,5510,033,245,035
Isacord,Ming - med olive green,5513,046,209,000
Isacord,Kelly - green,5515,007,227,000
Isacord,Pear - light leaf green,5531,089,230,064
Isacord,Palm Leaf - pale turquoise,5552,171,217,161
Isacord,Deep Green - dark leaf green,5555,000,094,000
Isacord,Bright Mint - light leaf green,5610,143,245,051
Isacord,Light Kelly - med leaf green,5613,076,250,043
Isacord,Lime - medium leaf green,5633,025,171,025
Isacord,Green Dust - olive green,5643,015,145,000
Isacord,Spring Frost - pale green,5650,181,225,138
Isacord,Willow - teal green,5664,120,194,148
Isacord,Green Grass,5722,078,134,063
Isacord,Apple Green,5730,162,202,100
Isacord,Mint,5740,196,219,159
Isacord,Spanish Moss,5770,217,231,198
Isacord,Kiwi - light khaki green,5822,179,227,107
Isacord,Limabean - med olive green,5833,102,215,033
Isacord,Herb Green - dk olive green,5866,000,051,000
Isacord,Erin Green - lt leaf green,5912,140,255,066
Isacord,Grasshopper - med leaf green,5933,046,171,000
Isacord,Moss Green - med leaf green,5934,053,130,000
Isacord,Sour apple - yellow green - neon,5940,145,255,033
Isacord,Backyard Green - dk leaf green,5944,025,104,017
Isacord,Mountain Dew - bright lime yellow,6010,215,235,000
Isacord,Tamarack,6011,187,214,098
Isacord,Jalapeno - pale green,6051,168,255,120
Isacord,Caper - khaki green,6133,153,209,071
Isacord,Spring Green,6141,171,197,116
Isacord,Olive - dark olive green,6156,030,053,000
Brother,Silver,005,169,168,167
Brother,Prussian Blue,007,17,31,119
Brother,Cream Brown,010,255,253,178
Brother,Light Blue,017,174,219,229
Brother,Sky Blue,019,33,135,190
Brother,Fresh Green,027,227,242,96
Brother,Vermilion,030,255,56,11
Brother,Dark Brown,058,43,19,0
Brother,Corn Flower,070,80,104,183
Brother,Salmon Pink,079,254,184,201
Brother,Pink,085,249,148,185
Brother,Deep Rose,086,240,77,141
Brother,Dark Fuchsia,107,199,3,86
Brother,Flesh Pink,124,250,218,222
Brother,Pumpkin,126,253,178,68
Brother,Lemon Yellow,202,237,250,115
Brother,Yellow,205,255,255,2
Brother,Harvest Gold,206,253,219,17
Brother,Orange,208,252,187,52
Brother,Tangerine,209,251,157,50
Brother,Deep Gold,214,230,174,0
Brother,Linen,307,255,227,196
Brother,Light Brown,323,180,118,38
Brother,Brass,328,192,149,9
Brother,Russet Brown,330,125,110,10
Brother,Amber Red,333,180,78,101
Brother,Reddish Brown,337,204,93,3
Brother,Clay Brown,339,217,84,0
Brother,Khaki,348,212,165,94
Brother,Warm Gray,399,216,204,201
Brother,Blue,405,10,83,168
Brother,Ultramarine,406,10,62,145
Brother,Peacock Blue,415,18,73,74
Brother,Electric Blue,420,12,91,165
Brother,Mint Green,502,161,214,125
Brother,Emerald Green,507,5,103,63
Brother,Leaf Green,509,105,185,69
Brother,Lime Green,513,112,187,41
Brother,Moss Green,515,48,125,38
Brother,Dark Olive,517,67,82,10
Brother,Olive Green,519,19,43,24
Brother,Teal Green,534,0,138,116
Brother,Seacrest,542,172,219,192
Brother,Wistaria Violet,607,104,104,181
Brother,Lilac,612,146,94,175
Brother,Violet,613,107,28,136
Brother,Purple,614,79,41,141
Brother,Magenta,620,143,56,144
Brother,Pewter,704,81,84,86
Brother,Dark Gray,707,42,49,51
Brother,Red,800,233,26,27
Brother,Lavender,804,182,174,216
Brother,Carmine,807,250,55,96
Brother,Deep Green,808,4,55,39
Brother,Light Lilac,810,228,154,204
Brother,Cream Yellow,812,255,238,145
Brother,Gray,817,137,136,135
Brother,Beige,843,239,227,188
Brother,Royal Purple,869,115,5,121
Brother,Black,900,0,0,0
