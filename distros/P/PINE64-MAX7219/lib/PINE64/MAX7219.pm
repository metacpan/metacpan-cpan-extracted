#!/usr/bin/perl -w
use strict;
use PINE64::GPIO;
use Time::HiRes qw(usleep);

package PINE64::MAX7219;

our $VERSION = '0.9101';

#routines to control a MAX7219 8-digit LED
#display driver.  
#This is implemented as bit-banged SPI.
#data is shifted into regs on rising edge of CLK, 
#output displayed on rising edge of LOAD

#NOTES:
#This version supports cascading several 7219's.  I have
#noticed that even with programs that assume only one
#7219, that if there is another cascaded, the exact same
#output is mirrored on subsequent displays. 

#I assume that turn_on, set_intenisty, set_scanlimit, etc
#all get shifted into the next chip anyway, however, 
#these subroutines take the number of cascaded 7219s as
#an argument and shift in and latch the necessary
#controls to use the display.  


#global vars for gpio init function
#$clk 	SPI clock
#$ds	SPI data
#$load	SPI chip select
my ($clk, $ds, $load);

############### GLOBAL VARS #####################
#shutdown register 
my @sdreg = (0,0,0,0,1,1,0,0);
my @turn_on = (0,0,0,0,0,0,0,1);
my @turn_off = (0,0,0,0,0,0,0,0);

#set scan limit register 
my @slimreg = (0,0,0,0,1,0,1,1);
#last 3 LSBs scan all 8 digits
my @slregall = (0,0,0,0,0,1,1,1);

#display test register
my @disptstreg = (0,0,0,0,1,1,1,1);

#intensity register
my @intreg = (0,0,0,0,1,0,1,0);

#digit addrs
#first 4 bits D15-D12
#don't care bits, then addr
my @_d0 = (0,1,0,1,0,0,0,1);
my @_d1 = (0,1,0,1,0,0,1,0);
my @_d2 = (0,1,0,1,0,0,1,1);
my @_d3 = (0,1,0,1,0,1,0,0);
my @_d4 = (0,1,0,1,0,1,0,1);
my @_d5 = (0,1,0,1,0,1,1,0);
my @_d6 = (0,1,0,1,0,1,1,1);
my @_d7 = (0,1,0,1,1,0,0,0);

#0-9
my @_1 = (0,0,1,1,0,0,0,0);
my @_2 = (0,1,1,0,1,1,0,1);
my @_3 = (0,1,1,1,1,0,0,1);
my @_4 = (0,0,1,1,0,0,1,1);
my @_5 = (0,1,0,1,1,0,1,1);
my @_6 = (0,1,0,1,1,1,1,1);
my @_7 = (0,1,1,1,0,0,0,0);
my @_8 = (0,1,1,1,1,1,1,1);
my @_9 = (0,1,1,1,0,0,1,1);
my @_0 = (0,1,1,1,1,1,1,0);
my @_all = (1,1,1,1,1,1,1,1);

#alpha chars
my @_a = (0,1,1,1,0,1,1,1);
my @_b = (0,0,0,1,1,1,1,1);
my @_c = (0,1,0,0,1,1,1,0);
my @_d = (0,0,1,1,1,1,0,1);
my @_e = (0,1,0,0,1,1,1,1);
my @_f = (0,1,0,0,0,1,1,1);
my @_g = (0,1,1,1,1,0,1,1);
my @_h = (0,0,1,1,0,1,1,1);
my @_i = (0,0,0,0,0,1,0,0);
my @_j = (0,0,1,1,1,1,0,0);
my @_k = (0,0,1,1,0,1,1,0);
my @_l = (0,0,0,0,1,1,1,0);
my @_m = (1,0,0,1,0,1,0,0);
my @_n = (0,0,0,1,0,1,0,1);
my @_o = (0,0,0,1,1,1,0,1);
my @_p = (0,1,1,0,0,1,1,1);
my @_q = (0,1,1,1,0,0,1,1);
my @_r = (0,0,0,0,0,1,0,1);
my @_s = (0,1,0,1,1,0,1,1);
my @_t = (0,0,0,0,1,1,1,1);
my @_u = (0,0,0,1,1,1,0,0);
my @_v = (0,0,0,1,1,1,0,0);
my @_w = (0,0,0,1,0,1,0,0);
my @_x = (0,0,0,1,1,1,0,1);
my @_y = (0,0,1,1,1,0,1,1);
my @_z = (0,1,1,0,1,1,0,1);

#special chars
my @_dp = (1,0,0,0,0,0,0,0);
my @_sp = (0,0,0,0,0,0,0,0);
my @_dash = (0,0,0,0,0,0,0,1);
my @_comma = (1,0,0,0,0,0,0,0);
my @_period = (1,0,0,0,0,0,0,0);
my @_question = (1,1,1,0,0,0,1,0);
my @_exclaimation = (1,0,1,1,0,0,0,0);

#individual segments
my @_seg_a = (0,1,0,0,0,0,0,0);
my @_seg_b = (0,0,1,0,0,0,0,0);
my @_seg_c = (0,0,0,1,0,0,0,0);
my @_seg_d = (0,0,0,0,1,0,0,0);
my @_seg_e = (0,0,0,0,0,1,0,0);
my @_seg_f = (0,0,0,0,0,0,1,0);
my @_seg_g = (0,0,0,0,0,0,0,1);

#@all_digits is an arra of array references
#representing each digit used to operate
#on each digit 
my @all_digits = (\@_d0,\@_d1,\@_d2,\@_d3,\@_d4,\@_d5,\@_d6,\@_d7);

#@all_segs is an array of array references
#representing each segment of a 7-seg LED array
my @all_segs = (\@_seg_a,\@_seg_b,\@_seg_c,\@_seg_d,\@_seg_e,\@_seg_f,\@_seg_g);

#Hash that maps alphanumeric chars to array ref
my %alphanums = (
	'A' => \@_a,
	'B' => \@_b,
	'C' => \@_c,
	'D' => \@_d,
	'E' => \@_e,
	'F' => \@_f,
	'G' => \@_g,
	'H' => \@_h,
	'I' => \@_i,
	'J' => \@_j,
	'K' => \@_k,
	'L' => \@_l,
	'M' => \@_m,
	'N' => \@_n,
	'O' => \@_o,
	'P' => \@_p,
	'Q' => \@_q,
	'R' => \@_r,
	'S' => \@_s,
	'T' => \@_t,
	'U' => \@_u,
	'V' => \@_v,
	'W' => \@_w,
	'X' => \@_x,
	'Y' => \@_y,
	'Z' => \@_z, 
	'0', => \@_0, 
	'1', => \@_1, 
	'2', => \@_2, 
	'3', => \@_3, 
	'4', => \@_4, 
	'5', => \@_5, 
	'6', => \@_6, 
	'7', => \@_7, 
	'8', => \@_8, 
	'9', => \@_9, 
	'.' => \@_period, 
	'-' => \@_dash, 
	',' => \@_comma, 
	'?' => \@_question, 
	'!' => \@_exclaimation
);#end %alphanums declaration

#instantiate PINE64 gpio device
my $p64 = PINE64::GPIO->new();

############### SUBROUTINES #####################
sub new{
	my $class = shift;
	my $self = bless {}, $class;

	#args are the GPIO pin numbers from PINE64::GPIO
	#that will be used for bit-bang SPI

	#initializes gpio lines and set to low
	$clk = $_[0];
	$ds = $_[1];
	$load = $_[2];

	$p64->gpio_enable($clk, 'out');
	$p64->gpio_write($clk, 0);
	$p64->gpio_enable($ds, 'out');
	$p64->gpio_write($ds, 0);
	$p64->gpio_enable($load, 'out');
	$p64->gpio_write($load, 0);

	return $self;
}#end new

sub shift_in{
	#data is shifted in with 16 bit packets: 8-bit segment,
	#4-bit digit address, 4-bit dont care bits

	#used by internal methods only

	#array ref seg data
	my $leds = $_[0];
	#array ref seg addr
	my $addr = $_[1];
	#number cascaded 7219s
	my $ncas = $_[2];
	#delay in milliseconds
	my $delay = $_[3];
	#latch flag
	my $lf = $_[4];

	#high flag for data gpio line
	my $hf = 0;

	#my $ncp = $ncas * 32;	#min number 32 for 16 clock pulses
	my $ncp = 32;
	##print "ncp: $ncp\n"; 

	#main clock loop
	my $i=0;
	#$state toggles from 1 to 0 needed for clock pulse
	my $state = 0;					
	#ensures first pulse goes from low to high
	my $seed = 3;					

	while($i<$ncp){#correct num clock pulses
		$state = $seed%2;
		$seed++;
	
		#load data in last 8 clock pulses
		#make DS high before clock pulse; only on even num
		#so index array is whole number
		#MSB read first, then addr, last data
		if(($i%2) eq 0){	

			#address D8-D11, and don't care bits D12-D15
			if($addr->[$i/2] == 1 && $i<=14){
				$p64->gpio_write($ds,1); 
				$hf = 1;#set high flag
			}#end addr high bit	
			
			#7-seg data, D0-D7	
			if($leds->[($i-16)/2] == 1 && $i > 14){#array ref, light this led up
				#test; set q1 high
				##print "inside data loop, i: $i\tindex: " .(($i-16)/2) . "\n";
				$p64->gpio_write($ds, 1);
				$hf = 1;#set high flag
			}#end if build D0-D7

		}#end if even $i 

		#TEST
		#print "i:\t$i\nD:\t$hf\n\n";
	
		#toggle clock pulse
		$p64->gpio_write($clk, $state);
		Time::HiRes::usleep($delay);#sleep .001 sec

		#lower data if high flag set
		if($hf eq 1){
			$p64->gpio_write($ds,0);
			$hf = 0;#reset high flag
		}#end if

		$i++;
	}#end while

	#latch output lines
	if($lf eq 1){	
		load();
	}#end latch flag

	$p64->gpio_write($clk,0);#set clock pulse low

}#end shift_in

sub load{
	#toggles LOAD (SPI chip select) pin on 7219 to send to output pins.  When the pin goes from low to high, sets output. 

	#enable XIO-p2
	$p64->gpio_enable($load, 'out');

	#ensure it is low
	$p64->gpio_write($load, 0);#low

	#go from low to high
	$p64->gpio_write($load, 1);#high
	#print "LATCH HIGH\n";
	Time::HiRes::usleep(500);#pause 0.0005 second

	#reset to low
	$p64->gpio_write($load, 0);#low
	#print "LATCH LOW\n";
	
}#end load

sub print_sentence{
	#currently for a single 7219 array
	my $sentence = $_[1];
	#set to all uppercase letters
	$sentence = uc $sentence;

	#delay between words in microseconds
	my $delay = $_[2];

	#all off flag, set if reading, unset if
	#you want the text to remain on the array
	#if empty, clears the text
	my $cleartxt_flag = $_[3];

	my @words = split / /, $sentence;
	my $numwords = @words;
	
	#loop through words
	for(my $i=0;$i<$numwords;$i++){
		#split word into an array of chars
		my @letters = split //, $words[$i];

		#number of chars in word
		my $numalphanums = @letters;
		#print "num letters: $numalphanums\n";
			
		#first letter
		my $ln = 0;
		
		#reverse @all_digits to display words
		#left to right
		my @rev_segs = reverse @all_digits;

		foreach my $digit (@rev_segs){
		
			#limited to 8 digits for now
			shift_in($alphanums{$letters[$ln]}, $digit, 1, 250, 1 );
			#print "letter: $letters[$ln]\n";
			$ln++;#go to next letter
		}#end letters inner for loop
		
		Time::HiRes::usleep($delay);
		unless($cleartxt_flag == 1){
			all_off();
		}#end if
	}#end for numwords
}#end print_sentence

sub print_interleaved{
	#takes separate strings for each
	#line of displays. The strings are
	#assumed to fit into the 8-digit
	#line of an led array for a 7219
	my $str1 = $_[1];
	my $str2 = $_[2];

	#upper case
	$str1 = uc $str1;
	$str2 = uc $str2;

	#convert strings to array of chars
	my @s1 = split //, $str1;
	my @s2 = split //, $str2;

	#pad string arrays with spaces
	#if less than 8 chars
	my $s1_len = @s1;
	my $s2_len = @s2;
	#print "s1len: $s1_len\ts2len: $s2_len\n";

	if($s1_len < 8){
		my $nsp = 8-$s1_len;
		for(my $n=$s1_len;$n<8;$n++){
			$s1[$n] = " ";
		}#end for pad w/ spaces
	}#end pad str1 with spaces

	if($s2_len < 8){
		my $nsp = 8-$s2_len;
		for(my $n=$s2_len;$n<8;$n++){
			$s2[$n] = " ";
		}#end for pad w/ spaces
	}#end pad str1 with spaces

	$s1_len = @s1;
	$s2_len = @s2;
	#print "s1len: $s1_len\ts2len: $s2_len\n";

	#reverse @all_digits to display words
	#left to right
	my @rev_segs = reverse @all_digits;

	#init letter number to 0
	my $ln = 0;

	foreach my $digit (@rev_segs){
		shift_in($alphanums{$s2[$ln]}, $digit, 1, 250, 0 );
		shift_in($alphanums{$s1[$ln]}, $digit, 1, 250, 0 );
		load();
		$ln++;
	}#end for
}#end print_interleaved

sub turn_on{
	#ncas is number of cascaded MAX7219 displays
	my $ncas = $_[1];
	if(defined($ncas)){
		#print "tu ncas defined\n";
		for(my $ni=0;$ni<$ncas;$ni++){
			shift_in(\@turn_on, \@sdreg, $ncas, 250, 0);
			if($ni ==($ncas-1)){
				#print "tu load\n";
				load();
			}#end if
		}#end for
	}#end if multiple 7219's
	else{#just one
		#set shutdown register to normal operation
		shift_in(\@turn_on, \@sdreg, 1, 250, 1);
	}#end else
}#end turn_on

sub turn_off{
	#ncas is number of cascaded MAX7219 displays
	my $ncas = $_[1];
	if(defined($ncas)){
		for(my $ni=0;$ni<$ncas;$ni++){
			shift_in(\@turn_off, \@sdreg, $ncas, 250, 0);
			if($ni ==($ncas-1)){
				load();
			}#end if
		}#end for
	}#end if multiple 7219's
	else{#just one
		#set shutdown register to off
		shift_in(\@turn_off, \@sdreg, 1, 250, 1);
	}#end else
}#end turn_off

sub set_scanlimit{
	#ncas is number of cascaded MAX7219 displays
	my $ncas = $_[1];
	if(defined($ncas)){
		#print "sl ncas defined\n";
		for(my $ni=0;$ni<$ncas;$ni++){
			shift_in(\@slregall, \@slimreg, $ncas, 250, 0);
			if($ni ==($ncas-1)){
				load();
				#print "sl load\n";
			}#end if
		}#end for
	}#end if multiple 7219's
	else{#just one
		#set scan limit register
		shift_in(\@slregall, \@slimreg, 1, 500, 1);
		#print "sl 1 chip\n";
	}#end else
}#end set_scanlimit

sub set_intensity{
	#takes string as arg: min, dim, mid, bright, max
	my $intensity = $_[1];
	
	#default to max
	my @intregdata = (0,0,0,0,1,1,1,1);
	if($intensity eq 'min'){
		@intregdata = (0,0,0,0,0,0,0,0);
	}#end if
	if($intensity eq 'dim'){
		@intregdata = (0,0,0,0,0,0,1,1);
	}#end if
	if($intensity eq 'mid'){
		@intregdata = (0,0,0,0,0,1,1,1);
	}#end if
	if($intensity eq 'bright'){
		@intregdata = (0,0,0,0,1,0,1,1);
	}#end if
	if($intensity eq 'max'){
		@intregdata = (0,0,0,0,1,1,1,1);
	}#end if

	#print "Intensity: $intensity\n";
	shift_in(\@intregdata, \@intreg, 1, 250, 1);
}#end set_intensity

sub all_off{
	#clear display
	#call after turned on, and
	#scan reg set to all digits
	my $ncas = $_[1];
	if(defined($ncas)){
		foreach my $digit(@all_digits){
			for(my $ni=0;$ni<$ncas;$ni++){
				shift_in(\@turn_off, $digit, $ncas, 100, 0);
				if($ni ==($ncas-1)){
					load();
				}#end if
			}#end for
		}#end outer for
	}#end if multiple 7219's
	else{#just one
		#@all_digits is an array of array references
		#representing each digit
		foreach my $digit (@all_digits){
			shift_in(\@turn_off, $digit, 1, 100, 1);
		}#end foreach
	}#end else
}#end all_off

sub disp_teston{
	#turn on display test, 
	#all digits and dp
	shift_in(\@turn_on, \@disptstreg, 1, 200, 1);
}#end disp_test

sub disp_testoff{
	#turn off display test, 
	#all digits and dp
	shift_in(\@turn_off, \@disptstreg, 1, 200, 1);
}#end disp_test

#################### EFFECTS######################
sub clockwise_circles{
	#number of iterations
	my $i = $_[1];
	my $k = 0;
	
	while($k<$i){
		for(my $n=0;$n<6;$n++){
			#outer for, each segment
			for(my $x=0; $x<8; $x++){
				#inner for, each digit
				shift_in(@all_segs[$n], @all_digits[$x], 1, 100, 1);
			}#end inner for
		}#end outer for

		$k++;

	}#end while
	all_off();
}#end clockwise_circles

sub countercw_circles{
	#number of iterations
	my $i = $_[1];
	my $k = 0;
	my @revall_segs = reverse @all_segs;
	while($k<$i){
		for(my $n=1;$n<7;$n++){
			#outer for, each segment
			for(my $x=0; $x<8; $x++){
				#inner for, each digit
				shift_in(@revall_segs[$n], @all_digits[$x], 1, 100, 1);
			}#end inner for
		}#end outer for

		$k++;

	}#end while
	all_off();
}#end countercw_circles

sub bullets_lrtop {
	#number of iterations
	my $ni = $_[1];
	for(my $n=0;$n<$ni;$n++){
		for(my $i=8;$i>=0;$i--){
			shift_in(\@_seg_a, @all_digits[$i], 1, 100, 1);
			all_off();
		}#end inner for
	}#end outer for	
	all_off();
}#end bullets_lrtop

sub bullets_rltop {
	#number of iterations
	my $ni = $_[1];
	for(my $n=0;$n<$ni;$n++){
		for(my $i=0;$i<=8;$i++){
			shift_in(\@_seg_a, @all_digits[$i], 1, 100, 1);
			all_off();
		}#end inner for
	}#end outer for	
	all_off();
}#end bullets_lrtop

sub bullets_lrmid {
	#number of iterations
	my $ni = $_[1];
	for(my $n=0;$n<$ni;$n++){
		for(my $i=8;$i>=0;$i--){
			shift_in(\@_seg_g, @all_digits[$i], 1, 100, 1);
			all_off();
		}#end inner for
	}#end outer for	
	all_off();
}#end bullets_lrtop

sub bullets_rlmid {
	#number of iterations
	my $ni = $_[1];
	for(my $n=0;$n<$ni;$n++){
		for(my $i=0;$i<=8;$i++){
			shift_in(\@_seg_g, @all_digits[$i], 1, 100, 1);
			all_off();
		}#end inner for
	}#end outer for	
	all_off();
}#end bullets_lrtop

sub bullets_lrbot {
	#number of iterations
	my $ni = $_[1];
	for(my $n=0;$n<$ni;$n++){
		for(my $i=8;$i>=0;$i--){
			shift_in(\@_seg_d, @all_digits[$i], 1, 100, 1);
			all_off();
		}#end inner for
	}#end outer for	
	all_off();
}#end bullets_lrtop

sub bullets_rlbot {
	#number of iterations
	my $ni = $_[1];
	for(my $n=0;$n<$ni;$n++){
		for(my $i=0;$i<=8;$i++){
			shift_in(\@_seg_d, @all_digits[$i], 1, 100, 1);
			all_off();
		}#end inner for
	}#end outer for	
	all_off();
}#end bullets_lrtop
1;

__END__

=head1 NAME

PINE64::MAX7219 driver for 8-digit 7-seg MAX7219 displays

=head1 SYNOPSIS

	use PINE64::MAX7219;

	my $max = PINE64::MAX7219->new(0,1,2);

	$max->turn_on(1);
	$max->set_scanlimit(1);
	$max->set_intensity('max');

	#display test (all on / all off))
	$max->disp_teston();
	sleep(2);
	$max->disp_testoff();

	#clockwise circles
	$max->clockwise_circles(10);

	#counter clockwise circles
	$max->countercw_circles(10);

	#print a sentence, 0.5sec / word
	$max->print_sentence("perl rules on pine64", 500000);

	#endless KnightRider effect!
	for(;;){
		$max->bullets_lrmid(1);
		$max->bullets_rlmid(1);
	}#end for

=head1 DESCRIPTION

This module is a driver for 8-digit seven-segment MAX7219 displays. It
is implemented as bit-banged SPI.  Using the object's methods, you can
set the intensity of the display, print words, and cascade multiple 
displays. It also comes with several built-in effects.  

Only three GPIO pins are required: SPI clk, SPI data, and SPI chip 
select.  This modules uses the PINE64::GPIO numbering scheme. 

=head1 METHODS

=head2 new($clock,$data,$chip_select)

Takes the GPIO pin numbers that will be used to inplement the bit-bang
SPI interface to the MAX7219 as arguments.  Returns an object to
control an 8-digit display.  

=head2 shift_in($leds, $digit, $n_cascaded, $delay, $latch_flag)

This method is only used internally.  It takes an array of a single
seven-segment's LEDs, the digit position, the number of cascaded
MAX7219 displays, a delay in usec (between SPI clock pulses), and a
latch flag.  Each individual letter of a word is shifted in one at
a time.  Once all the letters are shifted in, the latch_flag is set
high, and displays the word.  

=head2 load()

This method is only used internally. It manipulates the chip select
line, aka latch pin.  When called, it will render what has been
shifted into the display. 

=head2 print_sentence($sentence, $delay, $clear_flag)

Perhaps the most useful method.  Takes a string, however long, and
displays each word for $delay micro seconds.  $sentence could be the 
text of an entire book.  $clear_flag is not required.  

=head2 print_interleaved($string1, $string2)

This method is for use with two 8-digit displays cascaded.  $string1
will be displayed in the first display, $string2 in the cascaded
display. 

=head2 turn_on($num_cascaded)

Turns on the MAX7219 chip by writing to the turn on register.  Takes
the number of cascaded displays as an argument. Enter 1 if only 
using one display. 

=head2 set_scanlimit($num_cascaded)

Writes to the scan-limit register.  Sets it up to use all 8-digits
of the display.  Takes number of cascaded displays an arg. 

=head2 set_intensity($intensity); 

Adjusts the brightness of the display.  Takes a string as an arg.
Valid vlaues are: min, dim, mid, bright, max.  

=head2 all_off($num_cascaded)  

Turns off all digits.  Takes number of cascaded displays as an arg. 

=head2 disp_teston()

Turns on all segments on all digits.  

=head2 disp_testoff()

Turns off all segments on all digits. 

=head2 clockwise_circles($number_iterations)

Clockwise circles effect. 

=head2 countercq_circles($number_iterations)

Counter clockwise circles effects

=head2 bullets_lrtop($number_iterations)

Knight-rider like bullets effect.  Top row of horizontal LEDs of each
digit move from right to left. 

=head2 bullets_rltop($number_iterations)

Knight-rider like bullets effect.  Top row of horizontal LEDs of each
digit move from left to right. 

=head2 bullets_lrmid($number_iterations) 

Knight-rider like bullets effect.  Mid row of horizontal LEDs of each
digit move from left to right. 

=head2 bullets_rlmid($number_iterations) 

Knight-rider like bullets effect.  Mid row of horizontal LEDs of each
digit move from right to left. 

=head2 bullets_lrbot($number_iterations) 

Knight-rider like bullets effect.  Bottom row of horizontal LEDs of 
each digit move from left to right. 

=head2 bullets_rlbot($number_iterations) 

Knight-rider like bullets effect.  Bottom row of horizontal LEDs of 
each digit move from right to left. 
