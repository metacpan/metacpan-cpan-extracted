#!perl  -w
#LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL
#
#    Graphical User Interface for drawing and printing
#          
#    ROC curves with nonparametric confidence bounds
#
#    
#    
#
#     copyright 1998-2007 by Hans A. Kestler
#
#
#    Locations of Perl and modules have to be adapted to local configurations.
#
#LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL

# change paths if needed (probably)
#use lib '/opt/perl5/lib/site_perl/5.005/PA-RISC2.0/Tk'; 
#use lib '/home/kestler/PL/ROC.core/';
#use lib '/Applications/perl2exe/perl5/lib/site_perl/5.8.8/Tk';

#LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL
use Statistics::ROC;

use Carp;
use strict;
use Cwd;
use Cwd 'chdir';
use File::Basename;

use Tk;
require Tk::Dialog;

#use Tk::DialogBox;
#use Tk::DummyEncode;
#use Tk::Canvas;
#use utf8;
#use Tk::Menubutton;
#use Tk::Scale;
#use Tk::Optionmenu;
#use Tk::Bitmap;
#use Tk::FBox;
#LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL

##################### global variables ################
use vars qw/$VERSION $undef $loadfirst $fname $DIALOG_ABOUT $DIALOG_USAGE 
                                             $DIALOG_LOAD_ERROR $WAIT_BOX/;


$,=" ";
$VERSION='0.04';
$undef=0;
$loadfirst=0;
$fname=""; 


###########################################################################
###########################################################################
######
###### Graphical User Interface
######
###########################################################################
###########################################################################

# predeclare subroutines
sub make_menubutton;
sub roc_save;
sub fileSelector;
sub draw_roc;
sub initialize_messages;


sub make_menubutton { 
    # This function is courtesy of Steve Lidie, The Perl Journal, vol 1, no 1,
    # 1996.
    #	
    # Make a Menubutton widget; note that the Menu is automatically created.  
    # If the label is '', make a separator.

    my($mbf, $mb_label, $mb_label_underline, $pack, $mb_list_ref) = @_;

    my $mb = $mbf->Menubutton(
			       -text      => $mb_label, 
			       -underline => $mb_label_underline,
			      );
    my $mb_list;
    foreach $mb_list (@{$mb_list_ref}) {
	$mb_list->[0] eq '' ? $mb->separator :
	    $mb->command(
			 -label     => $mb_list->[0], 
			 -command   => $mb_list->[1], 
			 -underline => $mb_list->[2],
			 );
    }
    $mb->pack(-side => $pack);
    return $mb;
} # end make_menubutton




sub roc_save{
    # Saves or prints the ROC curve (canvas widget, drawing area)
    #
    # If the value of the hash is a string with "lpr" at the beginning
    # the drawing area will be piped to the postscript printer otherwise 
    # it will be saved as a postscript file.
    # Arguments: * handle to the canvas widget
    #            * value of entry field (string)
    
    my($w, $pinfo) = @_;    
    my($a,$psfname);
   
    $a = $w->postscript;
            
    if($pinfo->{'prcmd'}=~/^lpr/){
       open(LPR, "| $pinfo->{'prcmd'}");
       #print "yes lpr \n";
    }
    else{
       #print "no lpr file\n";
       #print dirname($fname)."/".$pinfo->{'prcmd'},"\n";
       #open(LPR, ">$pinfo->{'prcmd'}");
       $psfname = dirname($fname)."/".$pinfo->{'prcmd'};
       open(LPR, ">$psfname");
    }
    print LPR $a;close(LPR);
} # end roc_save


sub fileSelector{
    # File selection widget.
    # 
    # Selects and loads a datafile and draws the ROC curve with
    # default values. Makes checks on data.
    # Lines beginning with $ and # are treated as commentaries.
    # Uses the Tk::getOpenFile widget for file selection.
    #
    # Arguments: * handle of the main window
    #            * handle of the canvas widget
    #            * (0,0)- and (1,1)-points in pixels
    #              of the drawing area (this is the complete drawing area).
    #              It is assumed that y-coordinates increase from top
    #              to bottom of the widget, the x-coord. increase as expected
    #              from left to right.
    #            * the model type, this is a reference to string
    #            * the 2-sided confidence interval in %
    #            * the reference to the data (list-of-list)

    my $but=shift;
    my($MW,$c,$xzero,$yzero,$xone,$yone,$model_type_ref,
                                          $conf_ref,$var_grp_ref)   = @$but;  
    my($Horiz) = 1;
    # my $fname; 
    my $dir=cwd();
    my @line=();
    
    @$$var_grp_ref=();  # reinitialize data array
        

 
    
    $fname = $MW->getOpenFile(-title =>'Select a datafile!', -initialdir =>'.'); # $fname needs to be global for draw_roc
    
    
    
    return if !defined($fname); # check if filename is valid

    $main::name=fileparse($fname);
    $MW->title("ROC with confidence: $main::name");
   


    # open file and read in data
    open(DATA, "$fname");
    LINE: 
    while(<DATA>){ 
          next LINE if /^#/ || /^$/;
          @line=split;
          if(($line[1] != 1 && $line[1] != 0) ||
              $line[0] !~ /^(\+|-)?(\d+(\.\d*)?|\.\d+)(E|e)?(\+|-)?\d*$/)
          {                 
             $DIALOG_LOAD_ERROR->Show; return;
          }  
          push @$$var_grp_ref, [ @line ];
    }
    
    # check for not existing data
    if(!scalar(@$$var_grp_ref)){$DIALOG_LOAD_ERROR->Show; return;}
    
    # set loadfirst flag to indicate that data is loaded
    $loadfirst=1;
        
    draw_roc([$c,$xzero,$yzero,$xone,$yone,$model_type_ref,$conf_ref,$var_grp_ref]);
    
} # end of fileSelector


sub draw_roc{
  # Draws the receiver-operator characteristic curve with confidence bounds.
  #
  # Arguments: * handle of the canvas widget
  #            * (0,0)- and (1,1)-points in pixels
  #              of the drawing area (this is the complete drawing area).
  #              It is assumed that y-coordinates increase from top
  #              to bottom of the widget, the x-coord. increases as expected
  #              from left to right.
  #            * the model type, this is a reference to string
  #            * the 2-sided confidence interval in %
  #            * the reference to the data (list-of-list)
  
  my $but=shift;
  my ($c,$xzero,$yzero,$xone,$yone,$model_type,$conf,$var_grp)=@$but;
  my $m_type;
  
  #print $$model_type,"\n";print $$conf,"\n";
  #print ref($$model_type),"\n";print ref($$conf),"\n";
  

  # check for not existing data
  if(!$loadfirst){$DIALOG_LOAD_ERROR->Show; return;}
  
  ($main::state_b,$main::state_o,$main::state_p,$main::state_r,$main::state_v)=
                                                            (1,1,1,1,1); # reset checkbuttons
  

  
  if($$model_type eq 'grp0 > grp1'){$m_type='decrease'}
  elsif($$model_type eq 'grp0 < grp1'){$m_type='increase'}
  else{ croak "Wrong model type in userinterface\n";}
  
  
  my @ROC=roc($m_type,$$conf/100,@$$var_grp);   
  my $label;
  
  for(my $j=0,my $width;$j<3;$j++)
    {
      if($j==1){$width=2; $label='plot';}else{$width=1;$label='bounds';} # set ROC line width to 2
      for(my $i=0;$i<@{$ROC[0]}-1;$i++) # step thru (x,y)-pairs
	{
          $c->create('line',
		     ($xone-$xzero)*$ROC[$j][$i][0]+$xzero,
		     ($yone-$yzero)*$ROC[$j][$i][1]+$yzero,
		     ($xone-$xzero)*$ROC[$j][$i+1][0]+$xzero,
		     ($yone-$yzero)*$ROC[$j][$i+1][1]+$yzero, 
		     -fill=>'red',  -tags=>[$label],    
		     -width=>$width);
	} 
    }
  

  my ($i,$tmp);

   
  
  # calculate optimal cutoff value of empirical ROC curve  
  my($rp,$fp,$rn,$fn)=(0,0,0,0);
  my($acc,$sensi,$speci,$ppv,$npv);
  my @ss2=();
  my $g;
  my $gmax;
  my ($text1,$text2);
   
  for( my $j=0;$j<@$$var_grp;$j++)    
    {	
      $g = $$$var_grp[$j][0]; 	
      #print $g, "\n";
      ($rp,$fp,$rn,$fn)=(0,0,0,0);  
      for($i=0;$i<@$$var_grp;$i++)
	{ 
	  if($m_type eq 'increase')
	    {
	      if($$$var_grp[$i][0] > $g)
		{
		  if($$$var_grp[$i][1] == 1){$rp++;}
		  else {$fp++;}
		}
	      else
		{
		  if($$$var_grp[$i][1] == 0){$rn++;}
		  else {$fn++;}
		}
	    }
	  else			# modeltype decrease
	    {
	      if($$$var_grp[$i][0] < $g)
		{
		  if($$$var_grp[$i][1] == 1){$rp++;}
		  else {$fp++;}
		}
	      else
		{
		  if($$$var_grp[$i][1] == 0){$rn++;}
		  else {$fn++;}
		}
	    }
	}
      #print "$rp $rn $fn $fp \n";
      # acc sensi speci ppv npv
      if(!eval{$acc   = ($rn + $rp) / ($rn + $rp + $fn + $fp);}) {$acc=$undef;}
      if(!eval{$sensi = $rp / ($fn + $rp);}) {$sensi=$undef;}
      if(!eval{$speci = $rn / ($fp + $rn);}) {$speci=$undef;}
      if(!eval{$ppv   = $rp / ($fp + $rp);}) {$ppv=$undef;}
      if(!eval{$npv   = $rn / ($fn + $rn);}) {$npv=$undef;}
      #print "Threshold: $g \n";
      #print "$acc, $sensi, $speci, $ppv, $npv \n";
      #print "---------------\n";
      push @ss2, [$acc, $sensi, $speci, $ppv, $npv];  
    }
 
  for($i=0,$tmp=$ss2[0][1]+$ss2[0][2],$gmax=$tmp;$i<@ss2;$i++)
    {       
      if($ss2[$i][1]+$ss2[$i][2]>$tmp) {$tmp=$ss2[$i][1]+$ss2[$i][2]; $gmax=$i;}      
    } 
  
  $c->createText($xzero+300, $yone-20,
		 -text=>"Threshold: $$$var_grp[$gmax][0]",
		 -tags=>['values']);
  
 
  # rounding routine because 0.8125 rounds falsely with %.3 to 0.812
  sub round {$_[0] >0 ? int $_[0]+0.5 : int $_[0]-0.5}
  $text1= sprintf "ACC SENSI SPECI PPV NPV\n%.3f %.3f %.3f %.3f %.3f", 
                                         map {round(int($_ *10000)/10)/1000} @{$ss2[$gmax]};  
  $c->createText($xzero+100, $yone-20,
		 -text=>$text1,
		 -tags=>['values']);

  $c->createLine(($xone-$xzero)*(1-$ss2[$gmax][2])+$xzero, 
	     $yzero,
	     ($xone-$xzero)*(1-$ss2[$gmax][2])+$xzero,
	     ($yone-$yzero)*$ss2[$gmax][1]+$yzero, 
	     -fill=>'blue',  -tags=>['opt'],    
	     -width=>1);

  $c->createLine($xzero, 
	     ($yone-$yzero)*$ss2[$gmax][1]+$yzero,
             ($xone-$xzero)*(1-$ss2[$gmax][2])+$xzero,
	     ($yone-$yzero)*$ss2[$gmax][1]+$yzero, 
	     -fill=>'blue',  -tags=>['opt'],    
	     -width=>1);

  $c->createOval(($xone-$xzero)*(1-$ss2[$gmax][2])+$xzero-6,           
	     ($yone-$yzero)*$ss2[$gmax][1]+$yzero-6,
	     ($xone-$xzero)*(1-$ss2[$gmax][2])+$xzero+6,           
	     ($yone-$yzero)*$ss2[$gmax][1]+$yzero+6,
	     -width=>1,-fill=>'blue',-tags=>['opt']);
 
  $text2= sprintf "%1.3f\n%1.3f", 1-$ss2[$gmax][2], $ss2[$gmax][1];
  $c->createText(($xone-$xzero)*(1-$ss2[$gmax][2])+$xzero,           
		 ($yone-$yzero)*$ss2[$gmax][1]+$yzero-30,
		 -text=>$text2,
		 -tags=>['opt','values']);
  
  
    
  
  my @s=sort{(1-$ss2[$a][2]) <=> (1-$ss2[$b][2]) || $ss2[$a][1] <=> $ss2[$b][1]} 0..$#ss2;
  #print " $#ss2  $#s \n";
  @ss2=@ss2[@s];
  #for($i=0;$i<@ss2;$i++){print 1-$ss2[$i][2], $ss2[$i][1] ,"\n";}
  
  for($i=0;$i<$#ss2;$i++)	  # step thru (x,y)-pairs
    {
      $c->createLine(
		     ($xone-$xzero)*(1-$ss2[$i][2])+$xzero,
		     ($yone-$yzero)*$ss2[$i][1]+$yzero,
		     ($xone-$xzero)*(1-$ss2[$i+1][2])+$xzero,
		     ($yone-$yzero)*$ss2[$i+1][1]+$yzero, 
		     -fill=>'green4',  -tags=>['realroc'],    
		     -width=>2);
    } 
   
  
  # save ROC curves to file
  if($main::state_s)
    {
      #$c->messageBox(-icon => 'error', -message => 'Cannot create roc-file.');
      unless (open CURVES, ">$fname.txt") {die "Cannot create roc-file: $!";}
      print CURVES "$fname.txt\n";  # print filename
      print CURVES "Modeltype: $$model_type, 2-sided confidence interval: ",$$conf/100,"\n";
      print CURVES "Threshold: $$$var_grp[$gmax][0] \n";
      print CURVES "$text1\n";
      print CURVES "#######\n"; 
      print CURVES "Empirical ROC curve (x,y):\n";
      for($i=0;$i<$#ss2+1;$i++)	  # step thru (x,y)-pairs
	{
	  print CURVES (1-$ss2[$i][2]),"  ",$ss2[$i][1],"\n";
	}
      print CURVES "#######\n";
      print CURVES "Estimated ROC curve (x,y):\n";
      for(my $i=0;$i<@{$ROC[0]};$i++) # step thru (x,y)-pairs
	{
	  print CURVES $ROC[1][$i][0],"  ",$ROC[1][$i][1],"\n";
	}
      print CURVES "#######\n";
      print CURVES "Upper bound to estimated ROC curve (x,y):\n";
      for(my $i=0;$i<@{$ROC[0]};$i++) # step thru (x,y)-pairs
	{
	  print CURVES $ROC[0][$i][0],"  ",$ROC[0][$i][1],"\n";
	}
      print CURVES "#######\n"; 
      print CURVES "Lower bound to estimated ROC curve (x,y):\n";
      for(my $i=0;$i<@{$ROC[0]};$i++) # step thru (x,y)-pairs
	{
	  print CURVES $ROC[2][$i][0],"  ",$ROC[2][$i][1],"\n";
	}
      close(CURVES);
    }
                   
} # end draw_roc


sub initialize_messages{
  
  my $MW=shift;
  # Create all application Dialog objects.
  $DIALOG_LOAD_ERROR=$MW->Dialog(-title   => 'ERRROR',-text    => 
				 "The data has NOT been loaded or is NOT in the right format! 
The datafile has to have the following structure with one
sample per row: \n    <value> <class:0/1>",
				 -bitmap  => 'info',-wraplength => '3i',
				 -buttons => ['Dismiss'],
				 #-font => 'Arialbold'
				 );
  $DIALOG_ABOUT = $MW->Dialog(
			      -title   => 'About',
			      -text    => 
			      "ROC with confidence $VERSION \n\nApril 26. 2007\n\n
This program calculates receiver-operator characteristic  
curves with nonparametric confidence bounds from data 
separated into two groups.\n
Author: Hans A. Kestler, h.kestler\@ieee.org
                         hans.kestler\@uni-ulm.de
Copyright (c) 1998-2007 by Hans Kestler. All rights reserved. 
This program is free software; it may be redistributed and/or 
modified under the same terms as Perl itself.",
				-bitmap  => 'info',-wraplength => '6i',
				-buttons => ['Dismiss'],
				);
    #$DIALOG_ABOUT->configure(-wraplength => '6i');
    $DIALOG_USAGE = $MW->Dialog(
				-title   => 'Usage',
				-buttons => ['Dismiss'],
				);
    $DIALOG_USAGE->Subwidget('message')->configure(
						   -wraplength => '5i',
	 -text =>
"This program calculates and displays ROC curves
with confidence bounds. These bounds are
calculated nonparametrically.\n
The inputfile from which the ROC curve is
determined may be loaded with the LOAD button
in the FILE menu. It has to have the following 
structure with one sample per row: 
        <value> <class:0/1>.\n
The model assumption may be selected below the
drawing area. The confidence limits are set
with the scales. The curve won't be redrawn
after changing this interval. Either the model
has to be reselected or the BOUNDS ON/OFF 
button in the OPTIONS menu has to be toggled
to redraw the curve.\n
The ROC curve may be saved or printed by selecting
the <Print/Save as Postscript> button below the
canvas. If the entry field just above this
button is set to <lpr> the curve will be sent to
the printer otherwise it will saved in the file
specified (so don't use a filename with the
string lpr at the begining).\n
The <Options> menu gives some restricted 
possibilities of changing the appearance of the
graph. The <Optimium> is calculated by maximizing
simultaneously the sensitivity and specificity.
The performance values displayed above the canvas
give the optimal dicriminative ability of the
threshold value maximizing sensitivity and
specificity. If the model is grp0 < grp1 the 
threshold value belongs to grp0, i.e.
grp1 if value > threshold.");


} # end initialize_messages


sub draw_grid{
  # Draws a grid inside the canvas widget
  #
  # The available space is evenly divided into 10x10
  # rectangels.
  # Arguments: * handle of the canvas widget
  #            * (0,0)- and (1,1)-points in pixles
  #              of the drawing area (this is the complete drawing area)
  #              It is assumed that y-coordinates increase from top
  #              to bottom of the widget, the x-coord. increase as expected
  #              from left to right.
  
  my ($c,$xzero,$yzero,$xone,$yone)=@{shift()};
  
  for(my $i=0,my $inc=($xone-$xzero)/10;$i<=10;$i++){
    $c->createLine($xzero+$i*$inc,$yzero+4,
		   $xzero+$i*$inc,$yone,-width=>1,-tags=>['grid']);
  }
  for(my $i=0,my $inc=($yone-$yzero)/10;$i<=10;$i++){
    $c->createLine($xzero-4,$yzero+$i*$inc,
		   $xone,$yzero+$i*$inc,-width=>1,-tags=>['grid']);
  }
}				# end draw_grid


sub draw_small_ticks{
  # Draws small ticks. 
  #
  # Draws 100 small ticks on the x- and y- axis.
  # Arguments: * handle of the canvas widget
  #            * (0,0)- and (1,1)-points in pixles
  #              of the drawing area (this is the complete drawing area)
  #              It is assumed that y-coordinates increase from top
  #              to bottom of the widget, the x-coord. increase as expected
  #              from left to right.
  
  my ($c,$xzero,$yzero,$xone,$yone)=@{shift()};
  
  for(my $i=0,my $inc=($xone-$xzero)/100;$i<=100;$i++){
    $c->createLine($xzero+$i*$inc,$yzero+3,
		   $xzero+$i*$inc,$yzero,-width=>.5);
  }
  for(my $i=0,my $inc=($yone-$yzero)/100;$i<=100;$i++){
    $c->createLine($xzero-3,$yzero+$i*$inc,
		   $xzero,$yzero+$i*$inc,-width=>.5);
  }
}				# end draw_small_ticks


sub draw_numbers{
  # Draws the numbers {0, 0.1,..., 0.9, 1.0} the x- and y-axis. 
  #
  # Arguments: * handle of the canvas widget
  #            * (0,0)- and (1,1)-points in pixles
  #              of the drawing area (this is the complete drawing area)
  #              It is assumed that y-coordinates increase from top
  #              to bottom of the widget, the x-coord. increase as expected
  #              from left to right.
  
  my ($c,$xzero,$yzero,$xone,$yone)=@{shift()};
  
  for(my $i=0,my $inc=($xone-$xzero)/10;$i<=10;$i+=2){
    $c->create('text',$xzero+$i*$inc,$yzero+4+10,
	       -text=>$i/10);
  }
  for(my $i=0,my $inc=($yone-$yzero)/10;$i<=10;$i+=2){
    $c->create('text',$xzero-4-10,$yzero+$i*$inc,
	       -text=>$i/10);
  }
}				# end draw_numbers


sub draw_diagonal{
  # Draws a diagonal from (0,0) to (1,1).
  #
  # Arguments: * handle of the canvas widget
  #            * (0,0)- and (1,1)-points in pixles
  #              of the drawing area (this is the complete drawing area)
  #              It is assumed that y-coordinates increase from top
  #              to bottom of the widget, the x-coord. increase as expected
  #              from left to right.
  
  my ($c,$xzero,$yzero,$xone,$yone)=@{shift()};
  
  $c->createLine($xzero,$yzero,$xone,$yone,-width=>1, -tags=>['diag']);
  
}				# end draw_diagonal





my @var_grp=();
my $var_grp_ref=\@var_grp;
my $MW = new MainWindow;
$MW->title("ROC with confidence");
my $MBF=$MW->Frame(-relief=>'raised',-borderwidth=>1)->pack(-fill=>'x');


my ($xsize,$ysize)=(600,580);
my $area=500;			# actually the length of the quadratic area

# derived values
my ($xzero,$yzero)=(($xsize-$area)/2,$ysize-($ysize-$area)/2);
my ($xone,$yone)=($xsize-($xsize-$area)/2,($ysize-$area)/2);
my @points=($xzero,$yzero,$xone,$yone);
my $model_type ='grp0 < grp1'; 
my $conf=95;
$main::name=""; 


my $c=$MW->Canvas(-width=>$xsize,-height=>$ysize)->pack;
$c->create('text',($xone-$xzero)/2+$xzero,$yzero+4+10+12,-text=>"1-SPECIFICITY");
#my (@i)=qw/S e n s i t i v i t y/;
for(my $i=0,my (@i)=qw/S E N S I T I V I T Y/;$i<@i;$i++){
    $c->create('text',$xzero-36, ($yone-$yzero)/2+$yzero+$i*14-50,-text=>"$i[$i]");}

initialize_messages($MW);
draw_grid([$c,@points]);
draw_numbers([$c,@points]);
draw_small_ticks([$c,@points]);
draw_diagonal([$c,@points]);



###### File Menu Button ######
make_menubutton($MBF,'File',0,'left',[
        ['Load',[\&fileSelector,[$MW,$c,@points,\$model_type,\$conf,\$var_grp_ref]],0],
        ['Quit',\&exit,0]     ]);
##############################

###### Options Menu Button ######
my $mb_o=$MBF->Menubutton(-text=>'Options',-underline=>0)->pack(-side=>'left');
($main::state_b,$main::state_g,$main::state_d,$main::state_o,$main::state_p,$main::state_r,
                                             $main::state_v,$main::state_s)=(1,1,1,1,1,1,1,0);
$mb_o->checkbutton(
         -label=>'Bounds on/off',
         -variable=>\$main::state_b,
         -command=>sub{if(!$main::state_b){$c->delete('bounds')}
                       else{draw_roc([$c,@points,\$model_type,\$conf,\$var_grp_ref]);}}
        );    
$mb_o->checkbutton(
         -label=>'Grid on/off',
         -variable=>\$main::state_g,
         -command=>sub{if(!$main::state_g){$c->delete('grid')}
                       #else{draw_grid([$c,@points]);}}
                       else{draw_grid([$c,@points]);
                            draw_roc([$c,@points,\$model_type,\$conf,\$var_grp_ref]);}}
        );
$mb_o->checkbutton(
         -label=>'Diagonal on/off',
         -variable=>\$main::state_d,
         -command=>sub{if(!$main::state_d){$c->delete('diag')}
                       else{draw_diagonal([$c,@points]);}}
        );
$mb_o->checkbutton(
         -label=>'Optimum on/off',
         -variable=>\$main::state_o,
         -command=>sub{if(!$main::state_o){$c->delete('opt')}
                       else{draw_roc([$c,@points,\$model_type,\$conf,\$var_grp_ref]);}} 
        );
$mb_o->checkbutton(
         -label=>'Estimated ROC on/off',
         -variable=>\$main::state_p,
         -command=>sub{if(!$main::state_p){$c->delete('plot')}
                       else{draw_roc([$c,@points,\$model_type,\$conf,\$var_grp_ref]);}} 
        );
$mb_o->checkbutton(
         -label=>'Empirical ROC on/off',
         -variable=>\$main::state_r,
         -command=>sub{if(!$main::state_r){$c->delete('realroc')}
                       else{draw_roc([$c,@points,\$model_type,\$conf,\$var_grp_ref]);}} 
        );
$mb_o->checkbutton(
         -label=>'Values on/off',
         -variable=>\$main::state_v,
         -command=>sub{if(!$main::state_v){$c->delete('values')}
                       else{draw_roc([$c,@points,\$model_type,\$conf,\$var_grp_ref]);}} 
        );                                
$mb_o->checkbutton(
         -label=>"Save curve values to file (suffix \".txt\" added) off/on",
         -variable=>\$main::state_s,
         -command=>sub{if($main::state_s)
                           {draw_roc([$c,@points,\$model_type,\$conf,\$var_grp_ref]);}} 
        );
# $save_cur->configure(label=>'Save curves values to file: $main::name.dat on/off');
##############################

###### Help Menu Button ######
make_menubutton($MBF, 'Help', 0, 'right',
		    [
		     ['About', [$DIALOG_ABOUT => 'Show'], 0],
		     ['',      undef,                     0],
		     ['Usage', [$DIALOG_USAGE => 'Show'], 0],
		    ],
		   );
##############################



# create border of curve
$c->create('rectangle', @points , -width=>2);     # line width of 2



#### lower part: below drawing area (canvas)
my $controls=$MW->Frame(qw/ -relief ridge/)->pack(-fill=>'x');
$controls->gridColumnconfigure(1,-weight=>1);
my $left=$controls->Frame(qw/-bd 5 -relief ridge/)->grid(qw/-row 0 -column 0 -sticky nsw/);
my $right=$controls->Frame(qw/-bd 5 -relief ridge/)->grid(qw/-row 0 -column 1 -sticky ew/);


######## Print/Save as PostScript #######
my %pinfo=('prcmd','lpr');
my $w_prcmd = $left->Entry(
              -textvariable => \$pinfo{'prcmd'},);
$MW->Advertise('entry' => $w_prcmd);
$w_prcmd->grid(qw/-row 0 -column 0  -sticky ew/);

my $w_print = $left->Button(
        -text         => 'Print/Save as PostScript',
        -command      => [\&roc_save, $c, \%pinfo],);
$MW->Advertise('PostScript_button' => $w_print);
$w_print->grid(qw/-row 1 -column 0  -sticky w /);
$w_prcmd->bind('<Return>' => [$w_print => 'invoke']);
##########################################

######## Delete ROC curves ###############
my $del_roc=$left->Button(-text=>'Delete ROC curve!',
                             -command=>sub{$c->delete('plot');
                                           $c->delete('opt');
                                           $c->delete('bounds');
                                           $c->delete('realroc');
                                           $c->delete('values')},                       
                             -relief=>'raised')
                             ->grid(qw/-row 2 -column 0 -sticky ew/);

##########################################



######## Confidence Interval #########
my $conf_scale=$right->Scale('-orient'=> 'horizontal',
                           '-from'=> 0, '-to'=> 100, '-tickinterval'=> 0, '-width'=> 15, 
                           '-length'=> 340,
                           '-label'=> "2-sided Confidence Interval (%)",
                          -variable=>\$conf,
           #-command=> [\&draw_roc, [$c, @points,\$model_type,\$conf,\$var_grp_ref]], 
           )->grid(qw/-row 0 -column 0 -columnspan 2  -sticky ew/);
######################################


######## Model option button #########
my $model_button=$right->Menubutton(-text=>'Model:   ',
    -relief=>'raised' )->grid(qw/-row 1 -column 0  -sticky ew/);
my $model=$right->Optionmenu(-variable => \$model_type,
                     -options => ['grp0 < grp1', 'grp0 > grp1'], 
                   #   -options=>['GGGGGGG', 'CCCCCC'],
                   #-command=>sub{print "$model_type \n";},
                   # -command=>sub{print $model_type," \n";},
           #-command=> [\&draw_roc, [$c, @points,\$model_type,0.95,@var_grp]],
         -command=> [\&draw_roc, [$c, @points,\$model_type,\$conf,\$var_grp_ref]],
         -relief=>'raised');
$model->grid(qw/-row 1 -column 1 -sticky ew/);                     
#######################################



MainLoop;






