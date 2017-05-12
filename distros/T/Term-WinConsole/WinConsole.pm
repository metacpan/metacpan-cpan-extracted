package Term::WinConsole;

require 5.005_62;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.02';

$|++;

############################################################
## Declarations
# 

use vars qw( @ISA $AUTOLOAD %sequences %attcode $MAXWIN $USECOLOR %borderChr);

$MAXWIN	 = 20;
$USECOLOR = 1;

# %borderChr contains the different chars used to draw borders.
%borderChr = ( 'ul' => '/', 'ur' => '\\', 'bl' => '\\', 'br' => '/', 'hrz' => '=', 'vrt' => '|' );

# %sequence is used to convert a command into its corresponding ANSI sequence. During runtime the '?' 
# is replaced by a parameter.
# 
# Idea taken from Term::ANSIScreen
#               
%sequences = (
'black'     => '30m',   'on_black'   => '40m',
'red'       => '31m',   'on_red'     => '41m',
'green'     => '32m',   'on_green'   => '42m',
'yellow'    => '33m',   'on_yellow'  => '43m',
'blue'      => '34m',   'on_blue'    => '44m',
'magenta'   => '35m',   'on_magenta' => '45m',
'cyan'      => '36m',   'on_cyan'    => '46m',
'white'     => '37m',   'on_white'   => '47m',
'clear'     => '0m',    'reset'      => '0m',
'light'     => '1m',    'dark'       => '2m',
'underline' => '4m',    'underscore' => '4m',
'blink'     => '5m',
'reverse'   => '7m',
'hidden'    => '8m',
'up'        => '?A',    'down'       => '?B',
'right'     => '?C',    'left'       => '?D',
'savepos'   => 's' ,    'loadpos'    => 'u',
'saveatt'   => '7' ,    'loadatt'    => '8',
'cls'       => '2J',    'cll'        => '2K',
'locate'    => '?;?H',  'setmode'    => '?h',
'font0'     => '(',     'font1'      => ')',
'wrapon'    => '7h',    'wrapoff'    => '7l',
'fullreset' => 'c',
);

# attcode is used to convert a color attribute into a bit rank thus combined attributes
# can give a unique integer 
#
# format is :
# attrib back  fore
# chrbld  rgb   rgb
               
%attcode = (
'on_red'    => 32,
'on_green'  => 16,
'on_yellow' => 48,
'on_blue'   => 8,
'on_magenta'=> 40,
'on_cyan'   => 24,
'on_white'  => 56,
'black'     => 0,
'red'       => 4,
'green'     => 2,
'yellow'    => 6,
'blue'      => 1,
'magenta'   => 5,
'cyan'      => 3,
'white'     => 7,
'light'     => 64,  
'dark'      => 128,
'underline' => 256,
'blink'     => 512,
'reverse'   => 1024,
'hidden'    => 2048,
'clear'     => 4096,
);

############################################################
## Constructor
# 

sub new {
	my $class = shift;
	my $title = shift;
	my $colsize = shift;   
	my $rowsize = shift;   
	my $border = shift;    
	my $cr = shift;        
	my $pattern = shift;   
	my $buffered = shift;  if (!defined($buffered)) {$buffered=1}

	my %object = (
		"winActive" => 0,        #active miniwin index
		"miniwin"   => undef,    #miniwin structures reference
		"useBuffer" => $buffered,#flag
		"lsAtt"     => undef,    #last sent attribute
		"frontTxt"  => undef,    #production text buffer reference 
		"frontAtt"  => undef,    #production attributes buffer reference 
		"zBuffer"   => undef,    #Z-Buffer reference
		"winStack"  => undef,    #miniwins stack reference
		"stats"     => 0,    	 #stats
	);

# Init the miniwin structure with a fullscreen miniwin (miniwin #0)
&setWindow(\%object,$title, 1, 1, $colsize, $rowsize, $border, $cr, $pattern);

# Init buffers
my (@frontTxt,@frontAtt,@zBuffer);

for (1..$rowsize){
   push @frontTxt , $pattern x $colsize;
   push @frontAtt , [(0) x $colsize];
   push @zBuffer , [(0) x $colsize];
}

$object{'frontAtt'} = \@frontAtt;
$object{'frontTxt'} = \@frontTxt;
$object{'zBuffer'} = \@zBuffer;

return bless \%object , $class;
}

#################################################
## AUTOLOAD implementation
#

# using %sequence keys as function name return/print the corresponding ANSI sequence
# Idea taken from Term::ANSIScreen

sub AUTOLOAD {
    my $sub;
    ($sub = $AUTOLOAD) =~ s/^.*:://;
    if (my $seq = $sequences{$sub}) {
    	shift(@_);
        $seq =~ s/\?/defined($_[0]) ? shift(@_) : 1/eg;
	return (defined wantarray) ? "\e[$seq" : print("\e[$seq");
    }else{
        die "Undefined subroutine &$AUTOLOAD called";
    }
}

sub DESTROY
{}

###########################################################################################
## MISC FUNCTIONS
#

# the stat counter is incremented each time a character is printed by a display function
# ( currently refresh and flush).
# this feature is given for optimisation purposes.

sub resetStat
{
	my ($self) = @_;
	$self->{'stats'} = 0;
}

sub getStat
{
	my ($self) = @_;
	return $self->{'stats'};
}

###########################################################################################
## WINDOW STACK HANDLING
#

# this stack is used to store windows depth level 

# add $idx on top of the stack
sub stackAdd
{
	my ($self,$idx) = @_;
	unshift(@{$self->{'winStack'}},$idx);
}

# supress $idx from the stack
sub stackDel
{
	my ($self,$idx) = @_;
	my ($offset);
	
	$offset = stackFind($self,$idx);
	if (defined $offset){
		splice(@{$self->{'winStack'}},$offset,1);
		return 1;
	}else{
		return undef;
	}
}

# move $idx on top of the stack
sub stackFocus
{
	my ($self,$idx) = @_;
	if (!defined(stackDel($self,$idx))){
		stackAdd($self,$idx);
		return 1;
	}else{
		return undef;
	}
}

# return the offset of $idx in the stack
sub stackFind
{
	my ($self,$idx) = @_;
	my ($offset);
	
	$offset = 0;
	for (@{$self->{'winStack'}}){
		if ($_==$idx){
			return $offset;
		}
		$offset++
	}
	return undef;
}

# return the index of the miniwin with $title as title
sub indexFind
{
	my ($self,$title) = @_;
	my ($idx);
	
	$idx = 0;
	for (@{$self->{'miniwin'}}){
		if ($_->{'title'} eq $title){
			return $idx;
		}
		$idx++
	}
	return undef;
}

# useful aliases
sub showWindow
{
	my ($self,$idx) = @_;
	my ($offset);

	if (!defined $idx){
		$idx = $self->{'winActive'};
	}
		
	$offset = stackFind($self,$idx);
	if (!defined $offset){
		&stackAdd($self,$idx);	
	}else{
		&stackFocus($self,$idx);	
	}
}

sub hideWindow
{
	my ($self,$idx) = @_;
	my ($offset);

	if (!defined $idx){
		$idx = $self->{'winActive'};
	}
		
	$offset = stackFind($self,$idx);
	if (defined $offset){
		&stackDel($self,$idx);	
	}
}

###########################################################################################
## DISPLAY HANDLING
#

# every drawing operations are made in a local miniwin buffer. Each time a display request is done,
# all the miniwins'buffer are melt into a unique 'backbuffer'.
#
# there are two methods to start a display :
#      - refresh : simply overwrite the production buffer with the back buffer and display it.
#                  (it needs less computations but send more data to the terminal)
#      - flush   : makes a diff between the production and the back buffer and display only differences
#                  (more computations needed but less data sent to the terminal)

sub makeFullBackBuffer 
{
	my ($self) = @_;
	my (@backAtt,@backTxt,$screen,$current, $destCol, $destRow, $active );		

	$screen = $self->{'miniwin'}[0];
	for (1..$screen->{'height'}){
   		push @backTxt , ' ' x $screen->{'width'};
   		push @backAtt , [(0) x $screen->{'width'}];	
	}

	for $active (reverse @{$self->{'winStack'}})
	{
		$current=$self->{'miniwin'}[$active];
       		for my $row (1..$current->{'height'})
       		{
           		for my $col (1..$current->{'width'})
	   		{
	   			$destCol = $current->{'colTop'}+$col-2;
	   			if ($destCol>$screen->{'width'}) { $destCol = $screen->{'width'} };
	   			$destRow = $current->{'rowTop'}+$row-2;
	   			if ($destRow>$screen->{'height'}) { $destRow = $screen->{'height'} };
	      			$backAtt[$destRow][$destCol]=$current->{'backAtt'}[$row-1][$col-1];
	      			$self->{'zBuffer'}[$destRow][$destCol]=$active;
	      			substr($backTxt[$destRow],$destCol,1)=substr($current->{'backTxt'}[$row-1],$col-1,1); 
	      		}
	   	}
	}
	return \(@backAtt,@backTxt);	
}


sub flush 
{
	my ($self, $win) = @_;
	my ($current, $curAtt, $col, $row, $gathering, $backAtt, $backTxt, $chunk, @chunk, $result );

	if (defined $win){
		if ($win<$#{$self->{'miniwin'}}){
			$win = $self->{'winActive'};
		}else{
			$win = 0;
		}
	}else{
		$win = 0;
	}

	($backAtt,$backTxt) = &makeFullBackBuffer($self);
        $current = $self->{'miniwin'}[$win];
	$curAtt = $self->{'lsAtt'};
	$gathering = 0;
	
	for my $row ($current->{'rowTop'}..($current->{'rowTop'}+$current->{'height'}-1))
	{
		for my $col ($current->{'colTop'}..($current->{'colTop'}+$current->{'width'}-1))
		{
			if (!$gathering){
				if (($self->{'frontAtt'}[$row-1][$col-1]!=${$backAtt}[$row-1][$col-1]) 
				  ||(substr($self->{'frontTxt'}[$row-1],$col-1,1) ne substr(@{$backTxt}[$row-1],$col-1,1))
				  &&(($self->{'zBuffer'}[$row-1][$col-1]==$win)||($win==0))
				  ){
					$chunk = {
		        				"col"   => $col,
		        				"row"   => $row, 
		        				"att"   => ${$backAtt}[$row-1][$col-1], 
		        				"txt"   => substr(@{$backTxt}[$row-1],$col-1,1),
		        			};
		        		$curAtt = ${$backAtt}[$row-1][$col-1];
					$self->{'frontAtt'}[$row-1][$col-1]=${$backAtt}[$row-1][$col-1];
					substr($self->{'frontTxt'}[$row-1],$col-1,1) = substr(@{$backTxt}[$row-1],$col-1,1);
		        		$gathering = 1;
				}
			}else{
				if ( ($curAtt == ${$backAtt}[$row-1][$col-1])
				   &&( ($self->{'frontAtt'}[$row-1][$col-1]!=${$backAtt}[$row-1][$col-1])
				       ||
				       (substr($self->{'frontTxt'}[$row-1],$col-1,1) ne substr(@{$backTxt}[$row-1],$col-1,1))
				     )
				    &&
					(($self->{'zBuffer'}[$row-1][$col-1]!=$win)&&($win!=0))
				   ){
					${$chunk}{'txt'}.=substr(@{$backTxt}[$row-1],$col-1,1);
					$self->{'frontAtt'}[$row-1][$col-1]=${$backAtt}[$row-1][$col-1];
					substr($self->{'frontTxt'}[$row-1],$col-1,1) = substr(@{$backTxt}[$row-1],$col-1,1);
				}else{
					push @chunk, $chunk;
					undef($chunk);
					$gathering = 0;
					# at this point we're ending the current chunk
					# but the current char is maybe the beginning of a new chunk
					# so we redo the current loop
					redo;
				}
			}
		}
		if ($gathering){
			push @chunk, $chunk;
			undef($chunk);
			$gathering = 0;
		}
	}
	
       $result = "\e[s";

	for(@chunk){

		if (!$_) { next; }

	        $result.="\e[0m"; 
	        $self->{'stats'}+= length("\e[0m");		

          	$result.="\e[".${$_}{'row'}.";".${$_}{'col'}."H";
          	$self->{'stats'}+= length("\e[".${$_}{'row'}.";".${$_}{'col'}."H");

	      	$result.=&att2seq(${$_}{'att'});
		$self->{'stats'}+= length(&att2seq(${$_}{'att'}));

		$result.=${$_}{'txt'};
		$self->{'stats'}+= length(${$_}{'txt'});

		$self->{'lsAtt'} = ${$_}{'att'};
	}
       $result.="\e[u";
       undef (@chunk);
       return (defined wantarray) ? $result : print $result;
}


sub fullDump
{
	my ($self, $win) = @_;
	my ($current, $lastAtt, $backAtt, $backTxt, $result);

	if (defined $win){
		if ($win<$#{$self->{'miniwin'}}){
			$win = $self->{'winActive'};
		}else{
			$win = 0;
		}
	}else{
		$win = 0;
	}

	$lastAtt=0;

        $current = $self->{'miniwin'}[$win];

	($backAtt,$backTxt) = &makeFullBackBuffer($self);

	@{$self->{'frontAtt'}} = @{$backAtt};
	@{$self->{'frontTxt'}} = @{$backTxt};

       $result = "\e[s";
       for my $row ($current->{'rowTop'}..($current->{'rowTop'}+$current->{'height'}-1))
       {
           $result.="\e[".$row.";".$current->{'colTop'}."H";
	   $self->{'stats'}+= length("\e[".$row.";".$current->{'colTop'}."H");

           for my $col ($current->{'colTop'}..($current->{'colTop'}+$current->{'width'}-1))
	   {
		if (
		      ($self->{'zBuffer'}[$row-1][$col-1]==$win)
		      ||
		      ($win==0)
		    )
		      {
	      		if ($self->{'frontAtt'}[$row-1][$col-1]!=$lastAtt){
	      		  $result.="\e[0m";		
				$self->{'stats'}+= length("\e[0m");
              		
	      			$result.=&att2seq($self->{'frontAtt'}[$row-1][$col-1]);
				$self->{'stats'}+= length(&att2seq($self->{'frontAtt'}[$row-1][$col-1]));
              		
	      			$lastAtt = $self->{'frontAtt'}[$row-1][$col-1];
	      			$self->{'lsAtt'} =  $lastAtt;
	      		}
              		
	      		$result.=substr($self->{'frontTxt'}[$row-1],$col-1,1);
	      		$self->{'stats'}+= length(substr($self->{'frontTxt'}[$row-1],$col-1,1));
		}
	   }
       }	
      $result.="\e[u";

       return (defined wantarray) ? $result : print $result;
}

###########################################################################################
## CURSOR HANDLING
#

sub gotoCR
{
	my ($self, $column, $row) = @_;
	my ($current, $modif);

        $current = $self->{'miniwin'}[$self->{'winActive'}];

	if ($current->{'border'}) {
		$modif = 2;
	}else{
		$modif = 1;
	}

	# return on bad values
	return undef if ((!$column)||(!$row));

	# -1 means the last column/row
	if ($column<0){ 
		$column = $current->{'width'}-$modif+$column+1;
	}
	if ($row<0){ 
		$row = $current->{'height'}-$modif+$row+1;
	}
        
	if ($row<=($current->{'height'}-$modif)){
		$current->{'cursRow'}=$row;		
	}else{
		if ($current->{'carrRet'}){
			&scrollWin($self,'up',1);
			$current->{'cursRow'}=$current->{'height'}-$modif;
			$current->{'curscol'}=1;
		}else{
			return undef;		
		}
	}

	if ($column<=($current->{'width'}-$modif)){
		$current->{'cursCol'}=$column;		
	}else{
		if ($current->{'carrRet'}){
			&doCR($self);
			($column, $row) = &getCR;
		}else{
			return undef;		
		}		
	}
	return 1;
}

sub getCR
{
	my ($self) = @_;
	my $current;

        $current = $self->{'miniwin'}[$self->{'winActive'}];

	return $current->{'cursCol'},$current->{'cursRow'};
}

sub getAbsCR
{
	my ($self) = @_;
	my ($current, $col, $row);

        $current = $self->{'miniwin'}[$self->{'winActive'}];
	($col, $row) = &getCR;
	
	if ($current->{'border'}){
		$col++;
		$row++;
	}
	return ($col + $current->{'colTop'} - 1),($row + $current->{'rowTop'} - 1 );
}

sub doCR
{
	my ($self) = @_;
	my ($col,$row);

	($col, $row) = &getCR;
	$col = 1;
	$row++;
	&gotoCR($self, $col, $row);
}

sub readyCurs
{
	my ($self, $col, $row) = @_;
	my ($current);

        $current = $self->{'miniwin'}[$self->{'winActive'}];

	if (!$col){
		$col = $current->{'cursCol'};
	}

	if (!$row){
		$row = $current->{'cursRow'};
	}

	# correction des coordonnées par gotoCR/getAbsCR
	&gotoCR($self,$col,$row);
	($col,$row) = &getAbsCR;
	print "\e[0m";		
	print &att2seq($self->{'frontAtt'}[$row-1][$col-1]);
	$self->{'lsAtt'} =  $self->{'frontAtt'}[$row-1][$col-1];
	print("\e[".$row.";".$col."H");
}

###########################################################################################
##    COLOR HANDLING
#

sub setWinColor
{
	my ($self, $color) = @_;
	return $self->{'miniwin'}[$self->{'winActive'}]->{'winCol'} = &codeAtt($color);
	
}

sub setCurrentColor
{
	my ($self, $color) = @_;
	return $self->{'miniwin'}[$self->{'winActive'}]->{'curCol'} = &codeAtt($color);
	
}

sub resetColor
{
	my ($self) = @_;
	return $self->{'miniwin'}[$self->{'winActive'}]->{'curCol'} = $self->{'miniwin'}[$self->{'winActive'}]->{'winCol'};
}

###########################################################################################
##   ATTRIBUTES STRING CODING/UNCODING
#
sub codeAtt
{
no warnings;
	my ($attStr) = @_;
	my ($code);
	
	$code=0;	
	foreach(split ' ',$attStr){
		$code |= $attcode{$_};
	}
	return $code;
use warnings;
}

sub uncodeAtt
{
	my ($code) = @_;
	my ($attStr, $key, $val, $idx);

	#decimal to binary conversion
	$code = unpack("B32", pack("N",$code));

	if ($USECOLOR){
		#extracting background color
		$val = unpack("N", pack("B32", substr("0"x32 .substr($code, -3, 3),-32)));
		foreach $key (keys %attcode){ if ($attcode{$key}==$val){ $attStr.=" $key"; }}
		
		#extracting foreground color
		$val = unpack("N", pack("B32", substr("0"x32 .substr($code, -6, 3),-32)));
		foreach $key (keys %attcode){ if ($attcode{$key}==$val){ $attStr.=" on_$key"; }}
	}

	#extracting attributes
	$val = substr($code, -13, 7);
	for $idx (1..length($val)){
		if (substr($val,-$idx,1)){
			foreach (keys %attcode){
				if ($attcode{$_}==(2**($idx+5))){
					 $attStr.=" $_"; 
				}
			}
		}
	}
	return $attStr;
}

sub att2seq
{
	my ($code) = @_;
	my ($attStr, $sequence);
	
	$attStr= &uncodeAtt($code);	
	foreach(split ' ',$attStr){
		$sequence .= "\e[".$sequences{$_};
	}
	return $sequence;
}


###########################################################################################
## MINIWINS HANDLING
#

sub deleteWin
{
	my ($self, $winId) = @_;
	if (($winId>0)&&($winId<$#{$self->{'miniwin'}})){
		$self->{'miniwin'}[$winId]= undef;
		if ($self->{'winActive'}==$winId){
			$self->{'winActive'}=0;
		}
		return 1;
	}else{
		return undef;
	}
}

sub setWinBorder
{
	my ($self, $flag) = @_;
	return $self->{'miniwin'}[$self->{'winActive'}]->{'border'} = $flag;
}

sub setWinCarret
{
	my ($self, $flag) = @_;
	return $self->{'miniwin'}[$self->{'winActive'}]->{'carrRet'} = $flag;
}

sub setActiveWin
{
	my ($self, $winId) = @_;
	if ( ($winId<=$#{$self->{'miniwin'}}) && (defined ($self->{'miniwin'}[$winId])))
	{
		$self->{'winActive'} = $winId;
	}else{
		return undef;
	}
}

sub setWinPattern
{
	my ($self, $pattern) = @_;
	return $self->{'miniwin'}[$self->{'winActive'}]->{'pattern'} = $pattern;
}

sub setWinTitle
{
	my ($self, $title) = @_;
	return $self->{'miniwin'}[$self->{'winActive'}]->{'title'} = $title;
}

sub setWinCol
{
	my ($self, $col) = @_;
	
	if (($col>0)
	  &&($col<=($self->{'miniwin'}[0]->{'width'}-$self->{'miniwin'}[$self->{'winActive'}]->{'width'}+1))
	  ){
		return $self->{'miniwin'}[$self->{'winActive'}]->{'colTop'} = $col;
	}else{
		return undef;
	}
}

sub setWinRow
{
	my ($self, $row) = @_;
	
	if (($row>0)
	  &&($row<=($self->{'miniwin'}[0]->{'height'}-$self->{'miniwin'}[$self->{'winActive'}]->{'height'}+1))
	  ){
		return $self->{'miniwin'}[$self->{'winActive'}]->{'rowTop'} = $row;
	}else{
		return undef;
	}
}

sub setWinWidth
{
	my ($self, $width) = @_;
	my ($current);

	$current = $self->{'miniwin'}[$self->{'winActive'}];
	if (($width>0)
	  &&($width<=length($current->{'backTxt'}[0]))
	  ){
		return $self->{'miniwin'}[$self->{'winActive'}]->{'width'} = $width;
	}else{
		return undef;
	}
}

sub setWinHeight
{
	my ($self, $height) = @_;
	my ($current);
	
	$current = $self->{'miniwin'}[$self->{'winActive'}];
	if (($height>0)
	  &&($height<=$#{$current->{'backTxt'}}+1)
	  ){
		return $self->{'miniwin'}[$self->{'winActive'}]->{'height'} = $height;
	}else{
		return undef;
	}
}

sub setWindow
{
	my ($self, $title, $colTop, $rowTop, $width, $height, $border, $cr, $pattern) = @_;
	my ($screen, $newwin, @backTxt, @backAtt);

	if (!defined($title)) {$title=''}
	if (!defined($colTop)) {$colTop=1}
	if (!defined($rowTop)) {$rowTop=1}
	if (!defined($width)) {$width=80}
	if (!defined($height)) {$height=25}
	if (!defined($border)) {$border=0}
	if (!defined($cr)) {$cr=1}
	if (!defined($pattern)) {$pattern=' '}

	if ($#{$self->{'miniwin'}}<$MAXWIN)
	{
		if (defined(@{$self->{'miniwin'}}))
		{
			$screen = $self->{'miniwin'}[0];
			if ($colTop>=$screen->{'width'}){
				$colTop = 1;
			}
			if ($rowTop>=$screen->{'height'}){
				$rowTop = 1;
			}
			if (($colTop+$width-1)>$screen->{'width'}){
				$width = $screen->{'width'} - $colTop +1 ;
			}
			if (($height+$rowTop-1)>$screen->{'height'}){
				$height = $screen->{'height'} - $rowTop +1 ;
			}
		}

		for (1..$height){
   			push @backTxt , $pattern x $width;
   			push @backAtt , [(0) x $width];	
		}

		$newwin = {
		        "title"   => $title,
		        "colTop"  => $colTop, 
		        "rowTop"  => $rowTop, 
		        "width"	  => $width,
		        "height"  => $height,
		        "border"  => $border,
		        "cursRow" => 1,
		        "cursCol" => 1,
		        "carrRet" => $cr,
		        "winCol"  => &codeAtt("white on_black"),
		        "curCol"  => &codeAtt("white on_black"),
		        "pattern" => $pattern,
			"backTxt" => \@backTxt,
			"backAtt" => \@backAtt
		};

		if (!defined(@{$self->{'miniwin'}})) 
		{
			$self->{'miniwin'} = [$newwin];
		}else{
			push @{$self->{'miniwin'}} , $newwin;
		}
		
		&stackAdd($self, $#{$self->{'miniwin'}});
		
		return $#{$self->{'miniwin'}};
	}else{
		return undef;
	}
}

###########################################################################################
## DISPLAY HANDLING
#
sub home
{
	my ($self) = @_;
	my ($current, $row, $col);

	$current = $self->{'miniwin'}[$self->{'winActive'}];

	for my $row (1..$current->{'height'})
	{
		for my $col (1..$current->{'width'})
		{
			$current->{'backAtt'}[$row-1][$col-1] = $current->{'winCol'};
			substr($current->{'backTxt'}[$row-1],$col-1,1)= $current->{'pattern'};
		}
	}	

       if ($current->{'border'})
       {
		# 201 upperleft corner symbol
		$col = 1;
		$row = 1;
	        $current->{'backAtt'}[$row-1][$col-1] = $current->{'winCol'};
	        substr($current->{'backTxt'}[$row-1],$col-1,1)= $borderChr{'ul'};

		# 187 upperright corner symbol
		$col = $current->{'width'};
		$row = 1;
	        $current->{'backAtt'}[$row-1][$col-1] = $current->{'winCol'};
	        substr($current->{'backTxt'}[$row-1],$col-1,1)= $borderChr{'ur'};

		# 188 bottomright corner symbol
		$col = $current->{'width'};
		$row = $current->{'height'};
	        $current->{'backAtt'}[$row-1][$col-1] = $current->{'winCol'};
	        substr($current->{'backTxt'}[$row-1],$col-1,1)= $borderChr{'br'};

		# 200 bottomleft corner symbol
		$col = 1;
		$row = $current->{'height'};
	        $current->{'backAtt'}[$row-1][$col-1] = $current->{'winCol'};
	        substr($current->{'backTxt'}[$row-1],$col-1,1)= $borderChr{'bl'};

		# 205 horizontal symbol
		for (2..$current->{'width'}-1)
		{
		    $col = $_;
		    $row = 1;
	            $current->{'backAtt'}[$row-1][$col-1] = $current->{'winCol'};
	            substr($current->{'backTxt'}[$row-1],$col-1,1)= $borderChr{'hrz'};
		    $row = $current->{'height'};
	            $current->{'backAtt'}[$row-1][$col-1] = $current->{'winCol'};
	            substr($current->{'backTxt'}[$row-1],$col-1,1)= $borderChr{'hrz'};
		}

		# title
		$col = 3;
		$row = 1;
		my $title = $current->{'title'}.($borderChr{'hrz'} x ($current->{'width'}-1));
                substr($current->{'backTxt'}[$row-1],$col-1,$current->{'width'}-4)= substr ($title,0,$current->{'width'}-4);
		

		# 186 vertical symbol
		for (2..$current->{'height'}-1)
		{
		    $row = $_;
		    $col = 1;
	            $current->{'backAtt'}[$row-1][$col-1] = $current->{'winCol'};
	            substr($current->{'backTxt'}[$row-1],$col-1,1)= $borderChr{'vrt'};
		    $col = $current->{'width'};
	            $current->{'backAtt'}[$row-1][$col-1] = $current->{'winCol'};
	            substr($current->{'backTxt'}[$row-1],$col-1,1)= $borderChr{'vrt'};
		}
	}
	&gotoCR($self,1,1);
}

sub deleteCh
{
	my ($self, $col, $row) = @_;
	my ($current);

        $current = $self->{'miniwin'}[$self->{'winActive'}];
	return &printCh($self, $current->{'pattern'}, $col, $row);
}

sub printCh
{
	my ($self, $char , $col, $row) = @_;
	my ($current, $oldCol, $oldRow, $modif);

        $current = $self->{'miniwin'}[$self->{'winActive'}];

	if ($current->{'border'}) {
		$modif = 1;
	}else{
		$modif = 0;
	}

	if ($char ne "\n"){
		($oldCol, $oldRow) = &getCR;
		if (&gotoCR($self, $col, $row)){
			substr ($current->{'backTxt'}[$row-1+$modif],$col-1+$modif,1) = $char;
			$current->{'backAtt'}[$row-1+$modif][$col-1+$modif] = $current->{'curCol'};
			&gotoCR($self,$oldCol,$oldRow);
			return 1;
		}else{
			return undef;
		}
	}else{
		&doCR($self);
		return 1;
	}
}

sub streamCh
{
	my ($self, $char) = @_;
	my ($current, $col, $row, $modif);

        $current = $self->{'miniwin'}[$self->{'winActive'}];

	if ($current->{'border'}) {
		$modif = 1;
	}else{
		$modif = 0;
	}

	if ($char ne "\n"){
		($col,$row) = &getCR;
		substr ($current->{'backTxt'}[$row-1+$modif],$col-1+$modif,1) = $char;
		$current->{'backAtt'}[$row-1+$modif][$col-1+$modif] = $current->{'curCol'};
		($col,$row) = &getCR;
		return &gotoCR($self,$col+1,$row);;
	}else{
		&doCR($self);
		return 1;
	}

}

sub printSt
{
	my ($self, $chars) = @_;
	for (1..length($chars))
	{
		&streamCh($self,substr($chars,$_-1,1));
	}
}

sub centerSt
{
	my ($self, $chars) = @_;
	my ($current, $modif, $pos, $slice);

        $current = $self->{'miniwin'}[$self->{'winActive'}];

	if ($current->{'border'}) {
		$modif = 2;
	}
	
	foreach(split "\n",$chars){
		$slice = $_;
		if (($current->{'width'}-$modif)>length($slice)){
			$pos = ($current->{'width'}-length($slice))/2;
		}else{
			$pos=1;
		}
		&gotoCR($self,$pos,$current->{'cursRow'});
		for (1..length($slice))
		{
			&streamCh($self,substr($slice,$_-1,1));
		}
		if ($chars=~/$slice/){
			&doCR($self);
		}
	}
	
}

###########################################################################################
####    SCROLL HANDLING
#

sub scrollWin # up, down, left right
{
	my ($self, $dir, $dist) = @_;
	my ($current, @saveText, @saveAtt, $modif, %src, %clip, $colDest, $rowDest);

        $current = $self->{'miniwin'}[$self->{'winActive'}];
	if (!$dist){
		$dist=1;
	}

	if ($current->{'border'}){
		$modif = 1;
	}

	if (($dir eq 'down')||($dir eq 'd'))
	{
	$colDest       = 1+$modif;
	$rowDest       = 1+$modif+$dist;
	$src{'left'}   = 1+$modif;
	$src{'top'}    = 1+$modif;
	$src{'height'} = $current->{'height'}-$modif*2-$dist;
	$src{'width'}  = $current->{'width'}-$modif*2;
	$clip{'left'}  = 1+$modif; 
	$clip{'top'}   = 1+$modif;    
	$clip{'width'} = $current->{'width'}-$modif*2;   
	$clip{'height'}= $dist;  
	}

	if (($dir eq 'right')||($dir eq 'r'))
	{
	$colDest       = 1+$modif+$dist;
	$rowDest       = 1+$modif;
	$src{'left'}   = 1+$modif;
	$src{'top'}    = 1+$modif;
	$src{'height'} = $current->{'height'}-$modif*2;
	$src{'width'}  = $current->{'width'}-$dist-$modif*2;
	$clip{'left'}  = 1+$modif; 
	$clip{'top'}   = 1+$modif;    
	$clip{'width'} = $dist;   
	$clip{'height'}= $current->{'height'}-$modif*2;  
	}

	if (($dir eq 'up')||($dir eq 'u'))
	{
	$colDest       = 1+$modif;
	$rowDest       = 1+$modif;
	$src{'left'}   = 1+$modif;
	$src{'top'}    = 1+$modif+$dist;
	$src{'height'} = $current->{'height'}-$modif*2-$dist;
	$src{'width'}  = $current->{'width'}-$modif*2;
	$clip{'left'}  = 1+$modif; 
	$clip{'top'}   = 1+$current->{'height'}-$dist-$modif;
	$clip{'width'} = $current->{'width'}-$modif*2;   
	$clip{'height'}= $dist;  
	}

	if (($dir eq 'left')||($dir eq 'l'))
	{
	$colDest       = 1+$modif;
	$rowDest       = 1+$modif;
	$src{'left'}   = 1+$modif+$dist;
	$src{'top'}    = 1+$modif;
	$src{'height'} = $current->{'height'}-$modif*2;
	$src{'width'}  = $current->{'width'}-$dist-$modif*2;
	$clip{'left'}  = 1+$current->{'width'}-$dist-$modif;
	$clip{'top'}   = 1+$modif;    
	$clip{'width'} = $dist;   
	$clip{'height'}= $current->{'height'}-$modif*2;  
	}

       	#Backup buffers creation
       	for (0..$src{'height'}-1){
   		push @saveAtt , [(0) x $src{'width'}];
   		push @saveText , '' x $src{'width'};
	}

	#Save the data
	for my $row (0..$src{'height'}-1)
	{
	    for my $col (0..$src{'width'}-1)
	   {
	      $saveAtt[$row][$col]=$current->{'backAtt'}[$src{'top'}+$row-1][$src{'left'}+$col-1];
	      substr($saveText[$row],$col,1) = substr($current->{'backTxt'}[$src{'top'}+$row-1],$src{'left'}+$col-1,1);
	   }
	}	

       for my $row (0..$src{'height'}-1)
       {
           for my $col (0..$src{'width'}-1)
	   {
	      $current->{'backAtt'}[$rowDest+$row-1][$colDest+$col-1]=$saveAtt[$row][$col];
	      substr($current->{'backTxt'}[$rowDest+$row-1],$colDest+$col-1,1) = substr($saveText[$row],$col,1);
	   }
       }	
       for my $row (0..$clip{'height'}-1)
       {
           for my $col (0..$clip{'width'}-1)
	   {
	      $current->{'backAtt'}[$clip{'top'}+$row-1][$clip{'left'}+$col-1]= $current->{'winCol'};
	      substr($current->{'backTxt'}[$clip{'top'}+$row-1],$clip{'left'}+$col-1,1) = $current->{'pattern'};
	   }
       }	
}

sub pasteWin  # up, down, left right
{
	my ($self, $dir, $txtref, $attref) = @_;
	my ($current, @saveText, @saveAtt, $modif, %src, %clip, $colDest, $rowDest, $dist);

        $current = $self->{'miniwin'}[$self->{'winActive'}];

	@saveText = @{$txtref};
	if (defined $attref){
		@saveAtt = @{$attref};
	}

	if ($current->{'border'}){
		$modif = 1;
	}

	if (($dir eq 'up')||($dir eq 'u')||($dir eq 'down')||($dir eq 'd'))
	{
		# test hrz validity
		if ((length $saveText[0]<($current->{'width'}-$modif*2)) 
		  or (     (defined $attref)
		       and ($#{@{$attref}[0]}<($current->{'width'}-1-$modif*2)) 
		      )
		  ){
		  	return undef;
		  }else{
	  		$dist=$#saveText+1;
		  }
	}

	if (($dir eq 'left')||($dir eq 'l')||($dir eq 'right')||($dir eq 'r'))
	{
		# test vrt validity
		if (($#saveText<($current->{'height'}-1-$modif*2)) 
		  or (     (defined $attref)
		       and ($#{@{$attref}}<($current->{'height'}-1-$modif*2)) 
		      )
		  ){
		  	return undef;
		  }else{
	  		$dist=length $saveText[0];
		  }
        }

	if (($dir eq 'up')||($dir eq 'u'))
	{
	$clip{'left'}  = 1+$modif; 
	$clip{'top'}   = 1+$modif;    
	$clip{'width'} = $current->{'width'}-$modif*2;   
	$clip{'height'}= $dist;  
	}

	if (($dir eq 'left')||($dir eq 'l'))
	{
	$clip{'left'}  = 1+$modif; 
	$clip{'top'}   = 1+$modif;    
	$clip{'width'} = $dist;   
	$clip{'height'}= $current->{'height'}-$modif*2;  
	}

	if (($dir eq 'down')||($dir eq 'd'))
	{
	$clip{'left'}  = 1+$modif; 
	$clip{'top'}   = 1+$current->{'height'}-$dist-$modif;
	$clip{'width'} = $current->{'width'}-$modif*2;   
	$clip{'height'}= $dist;  
	}

	if (($dir eq 'right')||($dir eq 'r'))
	{
	$clip{'left'}  = 1+$current->{'width'}-$dist-$modif;
	$clip{'top'}   = 1+$modif;    
	$clip{'width'} = $dist;   
	$clip{'height'}= $current->{'height'}-$modif*2;  
	}

       for my $row (0..$clip{'height'}-1)
       {
           for my $col (0..$clip{'width'}-1)
	   {
	      if (@saveAtt){
	         $current->{'backAtt'}[$clip{'top'}+$row-1][$clip{'left'}+$col-1]= $saveAtt[$row][$col];
	      }else{
	         $current->{'backAtt'}[$clip{'top'}+$row-1][$clip{'left'}+$col-1] = $current->{'winCol'};
	      }
	      substr($current->{'backTxt'}[$clip{'top'}+$row-1],$clip{'left'}+$col-1,1) = substr($saveText[$row],$col,1);
	      #print " $col : $row '".substr($current->{'backTxt'}[$clip{'top'}+$row-1],$clip{'left'}+$col-1,1)."' on ".$saveAtt[$row][$col]."\n";
	   }
       }	
       
       return $dist;
}


1;
__END__

=head1 NAME

Term::WinConsole - Perl extension for text based windows management.

=head1 SYNOPSIS

	use WinConsole;
	
	$con = WinConsole->new('HELLO',80,25,1,1,'~',1);
	$con->home;
	$con->gotoCR(1,1);
	$con->centerSt('This application uses WinConsole!');

	$index = $con->setWindow('Login',5,5,55,5,1,1,'.');
	$con->setActiveWin($index);
	$con->setWinColor('light red on_black');
	$con->resetColor;
	$con->home;
	$con->gotoCR(1,2);
	$con->printSt('Hi you! what is your name ? :');
	$con->fullDump;
	$con->readyCurs;
	chomp($answer = <>);
	$con->doCR;

	$index = $con->setWindow('Connected',7,7,50,6,1,1,'_');
	$con->setActiveWin($index);
	$con->setWinColor('light green on_black');
	$con->resetColor;
	$con->home;
	$con->printSt("Your access is granted\n");
	$con->printSt("Glads to see you $answer\n");
	$con->printSt("Have a nice day\n");
	$con->flush;
	<>;

	$con->setActiveWin(1);
	$con->setWinTitle('Disconnected');
	$con->home;
	$con->printSt("Good Bye $answer\n");
	$con->showWindow;
	$con->fullDump;


=head1 ABSTRACT

This module allows you to handle windows, cursor and colors on an ANSI compliant terminal.

=head1 DESCRIPTION

First of all, WinConsole uses ANSI sequences so don't expect to use it if your terminal is not
ANSI/VT100 compliant.

WinConsole uses a backbuffer to build your screens. This means that all printing operations are
invisible to the user until the next terminal refresh. WinConsole implements two methods for screen
display. The first is a simple refresh method that just prints the backbuffer on the terminal. 
The second prints only differences between the terminal and the back buffer. Thanks to this
feature, WinConsole allows you to greatly improve terminal applications performance by reducing
the amount of data sent other the net.

WinConsole allows you to manage independent regions of text called miniwins. each miniwin
has its own backbuffer so it can be moved around the screen and overlapped as you wish. they can even be
resized under some restrictions.

There's always an active miniwin (miniwin 0 stands for the full screen) and all the cursor moving,
color changing and text printing operations take place in that active miniwin. Thus, coordinates
are relative to the active miniwin and not the entire screen (unless using the miniwin 0).







=head1 MINIWINS HANDLING

... functions used to create, move, resize, activate and delete miniwins ...

=head2 setWindow ($title, $colTop, $rowTop, $width, $height, $border, $cr, $pattern)

Creates a new miniwin starting at row $rowTop and column $colTop (in screen coordinates),
$width characters wide and $height characters high with $title as title and char $pattern
used as a default pattern.
$border and $cr are just flags meaning 'draw a window border' if $border is true, and manage
automatic carriage return if $cr is true.

This function returns the new miniwin index. 

=head2 deleteWin ($winId)

Deletes the miniwin number $winId. Beware, this function just frees the memory used by the miniwin.
It doesn't suppress this entry in the miniwin array.

=head2 setActiveWin ($winId)

Sets miniwin number $winId as the current active miniwin.

=head2 setWinBorder ($bool)

Sets the value of the 'border' flag for the active miniwin.

=head2 setWinCarret ($bool)

Sets the value of the 'automatic carriage return' flag for the active miniwin.

=head2 setWinPattern($pattern)

Sets $pattern as the default char used as background pattern in the active miniwin.

=head2 setWinTitle ($title)

Sets $title as the new miniwin title for the active miniwin

=head2 setWinCol ($col)

Sets $col as the new starting column for the active miniwin.

=head2 setWinRow ($row)

Sets $row as the new starting row for the active miniwin.

=head2 setWinWidth ($width)

Sets $width as the new width for the active miniwin.(The new value can't be greater than the creation size)

=head2 setWinHeight ($height)

Sets $height as the new height for the active miniwin.(The new value can't be greater than the creation size)

=head2 indexFind ($title)

Returns the miniwin index with $title as title







=head1 DISPLAY HANDLING

... functions used to send data to the terminal ...

Every drawing operations are made in a local miniwin backbuffer, so are they invisible to the user 
until the next refresh. When you want to refresh the terminal, all the miniwins' backbuffers are 
melt into a unique fullscreen backbuffer. This fullscreen backbuffer is then copied into a fullscreen 
frontbuffer (its purpose is to store a mirror of terminal's content into memory).

There are two methods to send the frontbuffer to the terminal :

- fullDump : displays every character on the terminal using correct colors and attributes.
(it needs less computations but sends more data to the terminal)

- flush    : makes a diff between the front and the back buffer and sends only differences
(more computations needed but less data sent to the terminal)

=head2 makeFullBackBuffer

return a fullscreen attribute and a fullscreen text backbuffers using all the miniwins' backbuffer content.

=head2 flush ($win)

(See above for description)
$win is optional. if defined, the refresh is limited to the miniwin $win. if ommited full screen
will be refreshed. 

In an array context : return data to be sent as a string. 

In a non array context : send data to the terminal (i.e. print). 

=head2 fullDump ($win)

(See above for description)
$win is optional. if defined, the refresh is limited to the miniwin $win. if ommited full screen
will be refreshed. 

In an array context : return data to be sent as a string. 

In a non array context : send data to the terminal (i.e. print).








=head1 CURSOR HANDLING

...functions used to set or retrieve the cursor position...

(these functions target the active miniwin's backbuffer. It means that you won't see
their effect until the next terminal refresh.)

=head2 gotoCR ($col,$row)

Sets the cursor position on column $col and row $row of the active miniwin.A negative value
takes the opposite edge as origin (-1,-1 means the last row and the last column)

=head2 getCR

Returns the cursor current column and row position relative to the active miniwin.

=head2 getAbsCR 

Returns the cursor current column and row position relative to the entire screen.

=head2 doCR

Sets the cursor position to the left side of the active miniwin, one row below. ("do Carriage return")

=head2 readyCurs ($col,$row)

Prepares the terminal for direct character display. Useful if you want to retrieve user input
with the correct active win colors and char attributes.
Basically it sends ESC[$row;$colH and some ESC[....m to the terminal.








=head1 COLOR HANDLING

...functions used to set the current and window color...

(these functions target the active miniwin's backbuffer. It means that you won't see
their effect until the next terminal refresh.)

To set a character color and attribute you have to define a color string using a combination of
the following keywords :

Background colors : on_black on_red on_green on_yellow on_blue on_magenta on_cyan on_white  

Foreground colors : black red green yellow blue magenta cyan white    

Attributes : reset dark underscore clear light underline blink reverse hidden   


for example : to define a light blue blinking text on a white background you will use the
following string "light blue blink on_white".

=head2 setWinColor ($colorString)

Set a new default color for the active window. This default color is especially used when
calling the home function.

=head2 setCurrentColor ($colorString)

Set a new current color for the active window. This color is used when printing text.

=head2 resetColor

Set the default window color as the new current color.


=head1 PRINTINGS HANDLING

...functions used to draw text and clear screen...

(these functions target the active miniwin's backbuffer. It means that you won't see
their effect until the next terminal refresh.)


=head2 home

Erases the active miniwin content replacing every character by the miniwin's pattern and draws a border
around the miniwin if its border flag is set to true.

=head2 deleteCh ($col, $row)

deletes the char at column $col and row $row in current active miniwin coordinates.

=head2 printCh ($char, $col, $row)

prints the char $char at column $col and row $row in current active miniwin coordinates.

=head2 streamCh ($char)

prints the char $char at column $col and row $row in current active miniwin coordinates and
moves the cursor one column right.

=head2 printSt ($text)

prints the string $text at the current cursor position in current active miniwin coordinates.


=head2 centerSt($text)

prints the string $text centered at the current cursor row in the active miniwin.








=head1 BLOCK HANDLING

...functions used to paste or move text area...

(these functions target the active miniwin's backbuffer. It means that you won't see
their effect until the next terminal refresh.)

The direction parameter is one of the following keywords :
'up' or 'u', 'down' or 'd', 'left' or 'l', 'right' or 'r'.

=head2 scrollWin($dir, $dist)

Scrolls the active miniwin's content $dist steps in the $dir direction.

=head2 pasteWin($dir, $txtref, $attref)

Paste the content of the supplied arrays on the $dir border. $txtref and $attref are arrays reference.
txtref contains the characters to be printed. attref is optionnal and contains the attributes to be associated
with each character of txtref.





=head1 WINDOW STACK HANDLING

... In order to manage miniwins overlapping, a stack is used to store miniwins depth level. I
recommend you to only use the showWindow and hideWindow functions... 

=head2 stackAdd ($idx)

adds window with ref $idx on top of the stack

=head2 stackDel ($idx)

supress window $idx from the stack

=head2 stackFocus ($idx)

moves window $idx on top of the stack

=head2 stackFind ($idx)

returns the offset of window $idx in the stack

=head2 showWindow

sets the active miniwin visible

=head2 hideWindow

sets the active miniwin hidden








=head1 MISCELLANEOUS FUNCTIONS

...the stat counter is incremented each time a character is printed by a display function
(currently fullDump and flush). This feature is given for optimisation purposes...

=head2 resetStat

reset the stat counter.

=head2 getStat

return the stat counter value.








=head1 TIPS

=head2 Changing the characters used to draw miniwins' borders

These characters are stored in a hash %borderChr. the keys are :
'ul'  for upper left corner
'ur'  for upper right corner
'bl'  for bottom left corner
'br'  for bottom right corner
'hrz' for horizontal border
'vrt' for vertival border

=head2 How to bypass the 20 miniwins max limit ?

Just change the value of $MAXWIN

=head2 The terminal don't manage color orders but can use attributes orders (light, underline...)

You can set $USECOLOR to zero.


=head1 EXPORT

None by default.

=head1 AUTHOR

Jean-Michel VILOMET, jmichel@faeryscape.com

=head1 SEE ALSO

Term::ANSIColor - Color screen output using ANSI escape sequences by Russ Allbery 

Term::ANSIScreen - Terminal control using ANSI escape sequences by Autrijus Tang 

=head1 CREDITS

ANSI sequence call via AUTOLOAD with placeholders borrowed from Term::ANSIScreen. 

=head1 COPYRIGHT 

Copyright 2002 by Jean-Michel VILOMET <jmichel@faeryscape.com>

All rights reserved. This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.



 

=cut




