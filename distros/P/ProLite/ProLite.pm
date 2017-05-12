package ProLite;

require 5.005_62;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

use Time::HiRes qw(usleep);
use Device::SerialPort 0.05;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
	'all' => [ qw(
		dimRed red brightRed orange brightOrange dimYellow yellow 
		brightYellow dimLime lime brightLime brightGreen green dimGreen
		
		yellowSRedOnGreen rainbow redSGreen redSYellow greenSRed greenSYellow 
		greenOnRed redOnGreen orangeSBlackOnGreen limeSBlackOnRed greenSBlackOnRed 
		redSBlackOnGreen 

		RESET blank normal bold italic boldItalic 
		normalFlash boldFlash italicFlash boldItalicFlash uncondensed condensed 

		telephone glasses faucet rocket monster key shirt 
		helicopter car tank house teaPot knifeFork duck motorcycle bicycle crown 
		twinHearts arrowR arrowL arrowDL arrowUL beerGlass chair shoe wineGlass 

		autoL openOutL coverOutL date cyclingL closeRT closeLT closeInT scrollUpL
		scrollDownL overlapL stackingL comic1L comic2L beep pauseT appearL randomL
		shiftLeftL currentTime magicL thankyou welcome linkPage target current
		dayLeft hourLeft minLeft secLeft
		
		new connect waiting getBytes sendCommand pretty plIndex
		
		wakeUp deletePage deleteGraphic deleteAll setPage runPage signInfo
		factoryReset setSpeed setClock pad targetUp targetDown chain
	)],
	
	'core' => [ qw(
		new connect waiting getBytes sendCommand pretty plIndex
	)],
	
	'commands' => [ qw(
		wakeUp deletePage deleteGraphic deleteAll setPage runPage signInfo
		factoryReset setSpeed setClock pad targetUp targetDown chain
	)],
	
	'colors' => [ qw(
		RESET dimRed red brightRed orange brightOrange dimYellow yellow 
		brightYellow dimLime lime brightLime brightGreen green dimGreen
		
		yellowSRedOnGreen rainbow redSGreen redSYellow greenSRed greenSYellow 
		greenOnRed redOnGreen orangeSBlackOnGreen limeSBlackOnRed greenSBlackOnRed 
		redSBlackOnGreen 
	)],
	
	'styles' => [ qw(
		RESET blank normal bold italic boldItalic 
		normalFlash boldFlash italicFlash boldItalicFlash uncondensed condensed 
	)],
	
	'dingbats' => [ qw(
		RESET telephone glasses faucet rocket monster key shirt 
		helicopter car tank house teaPot knifeFork duck motorcycle bicycle crown 
		twinHearts arrowR arrowL arrowDL arrowUL beerGlass chair shoe wineGlass 
	)],

	'effects' => [ qw(
		autoL openOutL coverOutL date cyclingL closeRT closeLT closeInT scrollUpL
		scrollDownL overlapL stackingL comic1L comic2L beep pauseT appearL randomL
		shiftLeftL currentTime magicL thankyou welcome linkPage target current
		dayLeft hourLeft minLeft secLeft
	)],
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = ( qw(
		new connect waiting getBytes sendCommand pretty plIndex
		
		wakeUp deletePage deleteGraphic deleteAll setPage runPage signInfo
		factoryReset setSpeed setClock pad targetUp targetDown chain
));

our $VERSION = '0.01';

1;

__END__

=head1 NAME

ProLite - Perl extension to control Pro-Lite LED Message Signs

=head1 SYNOPSIS

  use ProLite qw(:core);
  
  my $s = new ProLite(id=>1, device=>'/dev/ttyS0', debug=>0, charDelay=>2000);
  
  $err = $s->connect();
  die "Can't connect to device - $err" if $err;
  
  $s->wakeUp();
  $s->setPage(1, "Hello World");
  $s->runPage(1);

=head1 DESCRIPTION

Pro-Lite "Programmable Electronic Displays" available at discount stores and
clubs like BJ's Wholesale Club contain a built-in RS-232 Interface via which
you can communicate with the device rather than the IR remote control. 

Pro-Lite (unlike some of their competitors) has decided to make the protocol
for communicating with the sign freely available. This class provides a
simple interface embodying that communication protocol for the sign.

=head2 EXPORT

Only the core methods are exported by default. While this is kinda nice, you 
can't do much but initiate communication with the sign.

The class methods and constants are broken down into the following groups:

  :core      methods responsible for basic communication
  :commands  methods responsible for the control of sign functions
  :colors    constants for text colors (see below)
  :styles    constants for text styles
  :dingbats  constants for graphic characters
  :effects   constants for transition effects

=head1 OVERVIEW

Pro-Lite signs have 26 pages available, each of which can be filled with
content. The content can be augmented with special codes to control text
color, font, effects, or special characters.

There may be up to 99 signs all listening on a common RS-422 network connected
to a single serial port.

Communication is established by instantiating a ProLite object, passing the
id number of the sign with which you want to communicate and the name of a 
(writable) serial device:

  my $s = new ProLite(id=>1, device=>'/dev/ttyS0', debug=>0, charDelay=>2000);

Next, the connection is established:

  $err = $s->connect();
  die "Can't connect to device - $err" if $err;

and, since the sign disables it's communication port after a period of
inactivity, the sign is sent a 'Wake-Up' command:

  $s->wakeUp();

Pages can then be populated with data and selected for display. See the
examples accompanying this class.

=head1 METHODS

=over 5

=item new(id=>$integer, device=>$string, [debug=>$boolean, maxReadAttempts=>$integer])

B<$evice> sets the device over which to communicate. 

B<$debug> if true, communication processes are displayed over STDOUT

B<$id> an integer, 1-99, of the sign with which to communicate.
Default is 1

B<$maxReadAttempts> the number of times internally to try to get a
byte from the sign before timing out. Default is 10000


=item connect()

Establishes the connection with the sign. Returns false on success, and an error
string if a communication or other failure occurs.


=item wakeUp()

Sends a 'wake-up' signal to the sign. After a period of inactivity, the sign
disables it's communication port.


=item deletePage($page)

Removes the contents (permanently!) of page B<$page>. Valid range 1-26.


=item deleteGraphic($graphic)

Removes the contents (permanently!) of graphic B<$graphic>. Valid range 1-26.


=item deleteAll()

Removes all sign data. Use with caution.


=item setPage($page, @content)

Sets the content of page B<$page> to the list passed. There are 26 pages, numbered
1 through 26. The list can contain literal text or any of the constant methods
described below.

For example:

  setPage(1, RESET, yellow, "Hello ", green, "world");


=item runPage($page)

Tells the sign to immediately display the page specified.


=item signInfo()

Causes the sign to display it's configuration settings.


=item factoryReset()

Sets the sign back to it's original settings. Usefull after replacing the internal
battery or upgrading the sign's ROM.


=item setSpeed($speed)

Sets the speed of scrolling activity by inserting delays. 


=item setClock()

Sets the date and time on the sign to the current system time.


=item targetUp($type, $value, $target, $page)

Sets the event count-up target. The sign will maintain this number and make
it available for insertion into sign messages.

B<$type> may be one of 'DAYS' or 'HOURS'. If 'DAYS' the counter is incremented every
24 hours. If 'HOURS' the counter is incremented every hour.

B<$value> the current counter value

B<$target> The desired value

B<$page> The page number to display when this value is reached.


=item targetDown($days, $hours, $mins, $page)

Sets the event count-down target. The sign will maintain this number and make
it available for insertion into sign messages.

B<$days> The number of days to the target

B<$hours> The number of hours to the target

B<$mins> The number of minutes to the target

B<$page> The page number to display when this value is reached.


=item chain($page)

Generates the code to cause the sign to jump to the specified page. 

B<$page> indicates the page

For example:

  setPage(1, RESET, yellow, "Hello ", green, "world", chain(2));
  setPage(2, " Happy Birthday ", chain(1));

would cause "Hello world Happy Birthday " to cycle on the sign. This allows for
arbitrarily complex content, especially when coupled to the target functions.

=back


=head1 LOW-LEVEL METHODS

Several of the methods listed below are 'Low Level'. They are not
needed for common use, and provide access to byte-level communication
processes.

=item waiting()

Returns the number of bytes waiting on the serial port to be read.


=head2 getBytes()

Returns, then flushes the serial port input buffer.


=head2 sendCommand($data, [$global])

Sends data in B<$data> to the sign with the ID specified in the constructor.
If B<$global> is true, formats is as a message to all signs.



=head1 CONSTANTS

All of the 'special' characters that the protocol specifies can be generated
via constants as described in these tables:

=head2 Colors

  RESET             dimRed              red                 brightRed
  orange            brightOrange        dimYellow           yellow 
  brightYellow      dimLime             lime                brightLime
  brightGreen       green               dimGreen
        
  yellowSRedOnGreen rainbow             redSGreen           redSYellow
  greenSRed         greenSYellow        greenOnRed          redOnGreen
  orangeSBlackOnGr  limeSBlackOnRed     greenSBlackOnRed    redSBlackOnGreen 

=head2 Styles

  blank             normal              bold                italic
  boldItalic        normalFlash         boldFlash           italicFlash
  boldItalicFlash
  
  uncondensed       condensed 

=head2 Dingbats

  telephone         glasses             faucet              rocket
  monster           key                 shirt               helicopter
  car               tank                house               teaPot
  knifeFork         duck                motorcycle          bicycle
  crown             twinHearts          arrowR              arrowL
  arrowDL           arrowUL             beerGlass           chair
  shoe              wineGlass 

=head2 Effects

  autoL             openOutL            coverOutL           cyclingL
  closeRT           closeLT             closeInT            scrollUpL
  scrollDownL       overlapL            stackingL           comic1L
  comic2L           appearL             randomL             shiftLeftL
  magicL
  
  thankyou          welcome
  
  currentTime       target              current             dayLeft
  hourLeft          minLeft             secLeft
  
  beep              pauseT
  
  date


=head1 AUTHOR

Marc D. Spencer, marcs@pobox.com

=head1 SEE ALSO

perl(1).

=cut

# ---------------------------------------------------------------------------

sub dimRed 					{return  '<CA>'}
sub red 					{return  '<CB>'}
sub brightRed 				{return  '<CC>'}
sub orange 					{return  '<CD>'}
sub brightOrange 			{return  '<CE>'}
sub dimYellow 				{return  '<CF>'}
sub yellow 					{return  '<CG>'}
sub brightYellow 			{return  '<CH>'}
sub dimLime 				{return  '<CI>'}
sub lime 					{return  '<CJ>'}
sub brightLime 				{return  '<CK>'}
sub brightGreen 			{return  '<CL>'}
sub green 					{return  '<CM>'}
sub dimGreen 				{return  '<CN>'}

sub yellowSRedOnGreen 		{return  '<CO>'}
sub rainbow 				{return  '<CP>'}
sub redSGreen 				{return  '<CQ>'}
sub redSYellow 				{return  '<CR>'}
sub greenSRed 				{return  '<CS>'}
sub greenSYellow 			{return  '<CT>'}
sub greenOnRed 				{return  '<CU>'}
sub redOnGreen 				{return  '<CV>'}
sub orangeSBlackOnGreen 	{return  '<CW>'}
sub limeSBlackOnRed 		{return  '<CX>'}
sub greenSBlackOnRed 		{return  '<CY>'}
sub redSBlackOnGreen 		{return  '<CZ>'}

sub RESET 					{return  '<SA><SI><CP>'}
sub blank 					{return  '                '}

sub normal 					{return  '<SA>'}
sub bold 					{return  '<SB>'}
sub italic 					{return  '<SC>'}
sub boldItalic				{return  '<SD>'}
sub normalFlash 			{return  '<SE>'}
sub boldFlash 				{return  '<SF>'}
sub italicFlash 			{return  '<SG>'}
sub boldItFlash 			{return  '<SH>'}
sub uncondensed 			{return  '<SI>'}
sub condensed 				{return  '<SJ>'}

sub telephone 				{return  '<BA>'}
sub glasses 				{return  '<BB>'}
sub faucet 					{return  '<BC>'}
sub rocket 					{return  '<BD>'}
sub monster 				{return  '<BE>'}
sub key 					{return  '<BF>'}
sub shirt 					{return  '<BG>'}
sub helicopter 				{return  '<BH>'}
sub car 					{return  '<BI>'}
sub tank 					{return  '<BJ>'}
sub house 					{return  '<BK>'}
sub teaPot 					{return  '<BL>'}
sub knifeFork 				{return  '<BM>'}
sub duck 					{return  '<BN>'}
sub motorcycle 				{return  '<BO>'}
sub bicycle 				{return  '<BP>'}
sub crown 					{return  '<BQ>'}
sub twinHearts 				{return  '<BR>'}
sub arrowR 					{return  '<BS>'}
sub arrowL 					{return  '<BT>'}
sub arrowDL 				{return  '<BU>'}
sub arrowUL 				{return  '<BV>'}
sub beerGlass 				{return  '<BW>'}
sub chair 					{return  '<BX>'}
sub shoe 					{return  '<BY>'}
sub wineGlass 				{return  '<BZ>'}

sub autoL 					{return  '<FA>'}
sub openOutL 				{return  '<FB>'}
sub coverOutL 				{return  '<FC>'}
sub date 					{return  '<FD>'}
sub cyclingL 				{return  '<FE>'}
sub closeRT 				{return  '<FF>'}
sub closeLT 				{return  '<FG>'}
sub closeInT 				{return  '<FH>'}
sub scrollUpL 				{return  '<FI>'}
sub scrollDownL 			{return  '<FJ>'}
sub overlapL 				{return  '<FK>'}
sub stackingL 				{return  '<FL>'}
sub comic1L 				{return  '<FM>'}
sub comic2L 				{return  '<FN>'}
sub beep 					{return  '<FO>'}
sub pauseT 					{return  '<FP>'}
sub appearL 				{return  '<FQ>'}
sub randomL 				{return  '<FR>'}
sub shiftLeftL 				{return  '<FS>'}
sub currentTime 			{return  '<FT>'}
sub magicL 					{return  '<FU>'}
sub thankyou 				{return  '<FV>'}
sub welcome 				{return  '<FW>'}
sub linkPage 				{return  '<FZ>'}
sub target 					{return  '<F1>'}
sub current 				{return  '<F2>'}
sub dayLeft 				{return  '<F3>'}
sub hourLeft 				{return  '<F4>'}
sub minLeft 				{return  '<F5>'}
sub secLeft 				{return  '<F6>'}

sub new
{
	my $that  = shift;
	my $class = ref($that) || $that;
			   
	my(%params) = @_;

	my $this = {};

	bless $this, $class;
	
	$this->{device} = $params{'device'};
	$this->{debug} = $params{'debug'};
	$this->{id} = $params{'id'};
	$this->{maxReadAttempts} = $params{'maxReadAttempts'} || 10000;
	
	return $this;
}



sub connect
{
	my($this) = @_;
	
	my $ob = Device::SerialPort->new ($this->{device}, 'quiet') || return "".$this->{device}.": $!";

	$ob->baudrate(9600)     || die "fail setting baudrate";
	$ob->parity("none")     || die "fail setting parity";
	$ob->databits(8)        || die "fail setting databits";
	$ob->stopbits(1)        || die "fail setting stopbits";
	$ob->handshake("none")  || die "fail setting handshake";
	$ob->write_settings || die "no settings";
	
	$ob->purge_all();

	$this->{connection} = $ob;	
	
	print STDERR "Connected\n" if $this->{debug};
	
	return 0;
}



sub waiting
{
	my($this) = @_;
	
	my($ob) = $this->{connection};

	($num, $data) = $ob->read(1);	# Read a byte;
	
	$this->{pending} = $data if ($num>0);
	
	return $num;
}



sub getBytes
{
	my($this) = @_;
	my($dataRead, $readCount);
	undef $done;
	
	my($ob) = $this->{connection};

	$dataRead .= $this->{pending};
	my $mra = $this->{'maxReadAttempts'};
	
	print "<-" if $this->{'debug'};
	while(not $done)
	{
		do
		{
			$readCount ++;
			($num, $data) = $ob->read(100);	# Read a byte;
			print pretty($data) if $data and $this->{'debug'}; 
		}until ($num>0 or $readCount > $mra);

		$dataRead .= $data;
		$done = 1 if $dataRead =~ /\r|\n/;
		$done = 2 if $readCount > $mra;
	}
	print "\n" if $this->{'debug'};

	return $done == 2 ? $readCount : $dataRead;
}



sub sendCommand
{
	my($this, $data, $global) = @_;
	my($gotOK) = 0;
	my($count, $response);

	my($ob) = $this->{connection};
	$ob->purge_all();

	# Make the ID
	$id = $this->{id};
	$id = "0$id" if $id < 10;
	$id = "<ID$id>";
	$id = '' if $global;
	
	do
	{
		$count ++;
		
		# Send the command
		print "->" if $this->{'debug'};
		foreach $ch (split '', "$id$data\r\n")
		{
			$ob->write($ch);
			usleep(5000);
			print pretty($ch) if $this->{'debug'};
		}
		print " [$count]\n" if $this->{'debug'};

		# Get the response
		unless($global)
		{
			$response = $this->getBytes();
			$response =~ s/$id//;
			$response =~ s/[\r\n]+//g;
			chomp $response;
		}
	} until ($response eq 'S' || $global);
	return $response;
}



sub pretty
{
	my($str) = @_;

	$str =~ s/\r/<CR>/g;
	$str =~ s/\n/<NL>/g;
	$str =~ s/\e/<ESC>/g;
	$str =~ s/\001/<1>/g;
	$str =~ s/\002/<2>/g;
	$str =~ s/\003/<3>/g;
	$str =~ s/\034/<FS>/g;
	$str =~ s/[\001-\037]/<*>/g;

	$str;
}



sub plIndex
{
	my($index) = @_;
	
	return '*' if $index eq 'ALL';
	return chr($index + 64);
}

# ---------------------------------------------------------------------------

sub wakeUp
{
	my($this) = @_;
	
	return $this->sendCommand();
}


sub deletePage
{
	my($this, $page) = @_;
	
	$page = plIndex($page);
	
	$this->sendCommand("<DP$page>");
}


sub deleteGraphic
{
	my($this, $page) = @_;
	
	$page = plIndex($page);
	
	$this->sendCommand("<DG$page>");
}


sub deleteAll
{
	my($this) = @_;
	
	$this->sendCommand("<D*>");
}


sub setPage
{
	my($this, $page, @content) = @_;
	
	$page = plIndex($page);
	my $content = join '', @content;
	
	$this->sendCommand("<P$page>$content");
}


sub runPage
{
	my($this, $page) = @_;
	
	$page = plIndex($page);
	
	$this->sendCommand("<RP$page>");
}


sub signInfo
{
	my($this) = @_;
	
	$this->sendCommand("<?>");
}


sub factoryReset
{
	my($this) = @_;

	$this->sendCommand("<RST>");
}


sub setSpeed
{
	my($this, $speed) = @_;
	
	$speed = plIndex($speed);
	
	$this->sendCommand("<SPD$speed>");
}


sub setClock
{
	my($this) = @_;
	
	my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$year += 1900;
	$mon ++;
	
	$mon = pad($mon, 2);
	$mday = pad($mday, 2);
	$hour = pad($hour, 2);
	$min = pad($min, 2);
	$sec = pad($sec, 2);
# <TCCYYMMDDWhhmmssH>

	$this->sendCommand("<T$year$mon$mday$wday$hour".$min.$sec."0>", 1);
}

sub pad
{
	my($val, $places) = @_;
	
	return '0' x ($places - length $val). $val;
}
	


sub targetUp
{
	my($this, $type, $value, $target, $page) = @_;
	
	$type = $type eq 'DAYS' ? 'D':'H';
	$value = '0' x (4 - length $value) . $value;
	$target = '0' x (4 - length $target) . $target;
	$page = plIndex($page);
	
	$this->sendCommand("<U$type$value$target$page>");
}


sub targetDown
{
	my($this, $days, $hours, $mins, $page) = @_;
	
	$days = '0' x (4 - length $days) . $days;
	$hours = '0' x (2 - length $hours) . $hours;
	$mins = '0' x (2 - length $mins) . $mins;
	$page = plIndex($page);
	
	$this->sendCommand("<V$days$hours$mins$page>");
}



sub chain
{
	my($next) = @_;
	
	return linkPage."<".plIndex($next).">";
}
