package PSGRAPH;

use 5.8.8;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use PSGRAPH ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

			) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

		);

our $VERSION = '0.05';

# This is the default class for the CGI object to use when all else fails.
my $DefaultClass = 'PSGRAPH' unless defined $PSGRAPH::DefaultClass;

sub new
{
	my $class = shift;
	my $self = {};
	bless $self, $class;
	return $self;
}
sub setData{
	my ( $self, $Data) = @_;
	$self->{Data} = $Data if defined($Data);
	return $self->{Data};
}
sub getData {
	my( $self ) = @_;
	return $self->{Data};
}
sub setGraphic{
	my ( $self, $Graphic) = @_;
	$self->{Graphic} = $Graphic if defined($Graphic);
	return $self->{Graphic};
}
sub getGraphic {
	my( $self ) = @_;
	return $self->{Graphic};
}
sub setLabelandColor{
	my ( $self, $LabelandColor) = @_;
	$self->{LabelandColor} = $LabelandColor if defined($LabelandColor);
	return $self->{LabelandColor};
}
sub getLabelandColor {
	my( $self ) = @_;
	return $self->{LabelandColor};
}

sub setPS {
	my( $self, $graphic ) = @_;
	my $subtype;
	if(defined($self->getSubtype)){$subtype=$self->getSubtype; print "subtype is defined\n";}
	if($graphic eq '2Dpie'){
		if((defined($subtype) && $subtype==1) || !defined($subtype)){
			$self->{PS} = 'gsave /radius 125 def /slicecount 1 def /pieslice {/label exch def /endangle exch def /startangle exch def /k exch def /y exch def /m exch def /c exch def /calloutline 29 def /labelpos 33 def 0 0 0 1 setcmykcolor .5 setlinewidth gsave 0 0 moveto /halfangle startangle endangle add 2 div def slicecount 2 mod 0 eq{/calloutline 15 def /labelpos 19 def}if halfangle startangle eq {halfangle rotate} {halfangle startangle gt {halfangle rotate}{/halfangle halfangle 180 add def halfangle rotate}ifelse}ifelse /checkangle halfangle def checkangle 360 gt {/checkangle checkangle cvi 360 mod def}if checkangle 90 gt { checkangle 110 lt{ /labelpos labelpos 4 add def }if checkangle 250 lt {checkangle 110 gt {/labelpos labelpos 8 add def}if}if}if checkangle 250 gt {/labelpos labelpos 14 add def}if radius calloutline add 0 lineto stroke grestore halfangle cos radius labelpos add mul typesize 3 checkangle 70 le {mul add}{div sub}ifelse halfangle sin radius labelpos add mul typesize 3 div sub moveto /Helvetica-Bold findfont typesize scalefont setfont  ';
		}elsif($subtype==2){
			$self->{PS} = 'gsave /radius 125 def /slicecount 1 def /pieslice { /percent1 exch def /label1 exch def /endangle exch def /startangle exch def /k exch def /y exch def /m exch def /c exch def /calloutline 29 def /labelpos 33 def 0 0 0 1 setcmykcolor .5 setlinewidth /Helvetica-Bold findfont dup length dict begin {1 index /FID ne {def} {pop pop} ifelse}forall /Encoding ISOLatin1Encoding def currentdict end /Helvetica-Bold-ISOLatin1 exch definefont pop /Helvetica-Bold-ISOLatin1 findfont typesize scalefont setfont gsave 0 0 moveto /halfangle startangle endangle add 2 div def halfangle startangle eq {halfangle rotate} {halfangle startangle gt  {halfangle rotate}{/halfangle halfangle 180 add def halfangle rotate}ifelse}ifelse radius calloutline add 0 lineto stroke grestore 0 0 0 1	setcmykcolor halfangle cos radius 45 add mul  halfangle sin radius 45 add mul moveto gsave label1 dup stringwidth pop 2 div -1 mul 0 rmoveto show  grestore gsave /percentline 1.2 def percent1 dup stringwidth pop  2 div -1 mul typesize percentline mul -1 mul rmoveto show  grestore c m y k setcmykcolor 2 setlinejoin 0 0 moveto 0 0 radius startangle endangle arc closepath gsave fill grestore endangle startangle sub 360 ne { 0 0 0 0 setcmykcolor 1.5 setlinewidth stroke}if /slicecount slicecount 1 add def } def';
		}elsif($subtype==3){
			$self->{PS} = 'gsave /radius 125 def /typesize 8 def /slicecount 1 def /legendtype 16 def /legendbox 21 def /pieslice { /label exch def /endangle exch def /startangle exch def /k exch def /y exch def /m exch def /c exch def /calloutline 29 def /labelpos 33 def c m y k setcmykcolor 2 setlinejoin 0 0 moveto 0 0 radius startangle endangle arc closepath gsave fill grestore 0 0 0 0 setcmykcolor 1.5 setlinewidth stroke /slicecount slicecount 1 add def } def  /legend { /vsize exch def /hsize exch def /leftright exch def /ystart exch def /xstart exch def /label exch def /k exch def /y exch def /m exch def /c exch def gsave xstart ystart moveto /legendtype1 legendtype vsize mul def /Helvetica findfont legendtype1 scalefont setfont leftright 1 eq { label stringwidth pop neg legendbox 2 mul sub 0 rmoveto } if /xstart currentpoint pop def 0 legendbox hsize mul rlineto legendbox vsize mul 0  rlineto /minuslegendbox{legendbox -1 mul} def 0 minuslegendbox hsize mul rlineto closepath c m y k setcmykcolor fill 0 0 0 1 setcmykcolor xstart legendbox 2 mul add ystart moveto gsave 1 hsize div 1 vsize div scale label show grestore grestore } def /legend_right { /vsize exch def /hsize exch def /ystart exch def /xstart exch def /label exch def /k exch def /y exch def /m exch def /c exch def gsave xstart ystart moveto /legendtype1 legendtype vsize mul def /Helvetica findfont legendtype1 scalefont setfont /xstart currentpoint pop def 0 legendbox hsize mul rlineto legendbox vsize mul 0  rlineto /minuslegendbox{legendbox -1 mul} def 0 minuslegendbox hsize mul rlineto closepath c m y k setcmykcolor fill 0 0 0 1 setcmykcolor xstart legendbox vsize mul 2 mul add ystart moveto gsave 1 hsize div 1 vsize div scale label show grestore grestore } def /legend_left { /vsize exch def /hsize exch def /ystart exch def /xstart exch def /label exch def /k exch def /y exch def /m exch def /c exch def gsave /xstart xstart 20 sub def xstart ystart moveto gsave 1 hsize div 1 vsize div scale  /legendtype1 legendtype vsize mul def /Helvetica findfont legendtype1 scalefont setfont 0 0 0 1 setcmykcolor xstart hsize mul legendbox sub 10 sub label dup stringwidth pop -1 mul 0 rmoveto  show 10 0 rmoveto legendbox vsize mul 0 rlineto 0 legendbox vsize mul rlineto /minuslegendbox{legendbox -1 mul} def minuslegendbox vsize mul 0 rlineto closepath c m y k setcmykcolor fill grestore grestore} def';
		}elsif($subtype==31){
			$self->{PS} = 'gsave /radius 125 def /typesize 14 def /slicecount 1 def /legendbox legendtype 3 add def /pieslice { /endangle exch def  /startangle exch def /k exch def  /y exch def /m exch def  /c exch def /labelpos 39 def 0 0 0 1 setcmykcolor .5 setlinewidth c m y k setcmykcolor 2 setlinejoin 0 0 moveto 0 0 radius startangle endangle arc closepath gsave fill grestore 0 0 0 0 setcmykcolor 1.5 setlinewidth stroke /slicecount slicecount 1 add def } def /legend { /percent1 exch def /vsize exch def /hsize exch def /leftright exch def /ystart exch def /xstart exch def /label exch def /k exch def /y exch def /m exch def /c exch def gsave xstart ystart moveto /Helvetica-Bold findfont legendtype scalefont setfont leftright 1 eq { label stringwidth neg legendbox 2 mul sub 0 rmoveto } if /xstart currentpoint pop def 0 legendbox  hsize mul rlineto legendbox  vsize mul 0 rlineto /minuslegendbox{legendbox -1 mul} def 0 minuslegendbox hsize mul rlineto closepath c m y k setcmykcolor fill 0 0 0 1 setcmykcolor xstart legendbox vsize mul 2 mul add ystart moveto label show  percent1 show grestore } def /legend_right { /percent1 exch def /vsize exch def /hsize exch def /ystart exch def /xstart exch def /label exch def /k exch def /y exch def /m exch def /c exch def gsave xstart ystart moveto /legendtype1 legendtype vsize mul def /Helvetica-Bold findfont legendtype1 scalefont setfont /xstart currentpoint pop def 0 legendbox hsize mul rlineto legendbox vsize mul 0  rlineto /minuslegendbox{legendbox -1 mul} def 0 minuslegendbox hsize mul rlineto closepath c m y k setcmykcolor fill 0 0 0 1 setcmykcolor xstart legendbox vsize mul 2 mul add ystart moveto gsave 1 hsize div 1 vsize div scale gsave label show percent1 show grestore grestore grestore } def grestore	';
		}elsif($subtype==4){
			$self->{PS} = 'gsave /radius 125 def /slicecount 1 def /legendtype 16 def /legendbox 21 def /pieslice { /percent1 exch def /endangle exch def /startangle exch def /k exch def /y exch def /m exch def /c exch def /calloutline 29 def /labelpos 33 def 0 0 0 1 setcmykcolor .5 setlinewidth /Helvetica findfont dup length dict begin {1 index /FID ne {def} {pop pop} ifelse}forall /Encoding ISOLatin1Encoding def currentdict end /Helvetica-ISOLatin1 exch definefont pop /Helvetica-ISOLatin1 findfont typesize scalefont setfont gsave 0 0 moveto /halfangle startangle endangle add 2 div def halfangle startangle eq {halfangle rotate} {halfangle startangle gt  {halfangle rotate}{/halfangle halfangle 180 add def halfangle rotate}ifelse}ifelse radius calloutline add 0 lineto stroke grestore 0 0 0 1	setcmykcolor halfangle cos radius 45 add mul  halfangle sin radius 45 add mul moveto gsave percent1 dup stringwidth pop 2 div -1 mul 0 rmoveto show c m y k setcmykcolor 2 setlinejoin 0 0 moveto 0 0 radius startangle endangle arc closepath gsave fill grestore endangle startangle sub 360 ne { 0 0 0 0 setcmykcolor 1.5 setlinewidth stroke}if /slicecount slicecount 1 add def } def /legend { /vsize exch def /hsize exch def /leftright exch def /ystart exch def /xstart exch def /label exch def /k exch def /y exch def /m exch def /c exch def gsave xstart ystart moveto /legendtype1 legendtype vsize mul def /Helvetica findfont legendtype1 scalefont setfont leftright 1 eq { label stringwidth pop neg legendbox 2 mul sub 0 rmoveto } if /xstart currentpoint pop def 0 legendbox hsize mul rlineto legendbox vsize mul 0  rlineto /minuslegendbox{legendbox -1 mul} def 0 minuslegendbox hsize mul rlineto closepath c m y k setcmykcolor fill 0 0 0 1 setcmykcolor xstart legendbox 2 mul add ystart moveto gsave 1 hsize div 1 vsize div scale label show grestore grestore } def /legend_right { /vsize exch def /hsize exch def /ystart exch def /xstart exch def /label exch def /k exch def /y exch def /m exch def /c exch def gsave xstart ystart moveto /legendtype1 legendtype vsize mul def /Helvetica findfont legendtype1 scalefont setfont /xstart currentpoint pop def 0 legendbox hsize mul rlineto legendbox vsize mul 0  rlineto /minuslegendbox{legendbox -1 mul} def 0 minuslegendbox hsize mul rlineto closepath c m y k setcmykcolor fill 0 0 0 1 setcmykcolor xstart legendbox vsize mul 2 mul add ystart moveto gsave 1 hsize div 1 vsize div scale label show grestore grestore } def /legend_left { /vsize exch def /hsize exch def /ystart exch def /xstart exch def /label exch def /k exch def /y exch def /m exch def /c exch def gsave /xstart xstart 20 sub def xstart ystart moveto gsave 1 hsize div 1 vsize div scale  /legendtype1 legendtype vsize mul def /Helvetica findfont legendtype1 scalefont setfont 0 0 0 1 setcmykcolor xstart hsize mul legendbox sub 10 sub label dup stringwidth pop -1 mul 0 rmoveto  show 10 0 rmoveto legendbox vsize mul 0 rlineto 0 legendbox vsize mul rlineto /minuslegendbox{legendbox -1 mul} def minuslegendbox vsize mul 0 rlineto closepath c m y k setcmykcolor fill grestore grestore} def';
		}elsif($subtype==41){
			$self->{PS} = 'gsave /radius 125 def /typesize 18 def /slicecount 1 def /pieslice { /percent1 exch def /endangle exch def /startangle exch def /k exch def /y exch def /m exch def /c exch def /calloutline 29 def /labelpos 33 def 0 0 0 1 setcmykcolor .5 setlinewidth /Helvetica-Bold findfont dup length dict begin {1 index /FID ne {def} {pop pop} ifelse}forall /Encoding ISOLatin1Encoding def currentdict end /Helvetica-Bold-ISOLatin1 exch definefont pop /Helvetica-Bold-ISOLatin1 findfont typesize scalefont setfont gsave 0 0 moveto /halfangle startangle endangle add 2 div def halfangle startangle eq {halfangle rotate} {halfangle startangle gt  {halfangle rotate}{/halfangle halfangle 180 add def halfangle rotate}ifelse}ifelse radius calloutline add 0 lineto stroke grestore 0 0 0 1    setcmykcolor halfangle cos radius 45 add mul  halfangle sin radius 45 add mul moveto gsave percent1 dup stringwidth pop 2 div -1 mul 0 rmoveto show c m y k setcmykcolor 2 setlinejoin 0 0 moveto 0 0 radius startangle endangle arc closepath gsave fill grestore endangle startangle sub 360 ne { 0 0 0 0 setcmykcolor 1.5 setlinewidth stroke}if /slicecount slicecount 1 add def } def';
		}elsif($subtype==5){
			$self->{PS} = ' gsave  /radius 125 def  /slicecount 1 def  /pieslice { /sectionanchor exch def /explodeoffset exch def /label exch def  /endangle exch def  /startangle exch def  /k exch def  /y exch def  /m exch def  /c exch def  gsave sectionanchor cos explodeoffset mul sectionanchor sin explodeoffset mul translate  0 0 moveto  /Helvetica-Bold findfont typesize scalefont setfont '
#		}elsif((defined($subtype) && $subtype==6) || !defined($subtype)){
		}elsif($subtype==6){
			$self->{PS} = 'gsave /radius 125 def /slicecount 1 def /pieslice {/label exch def /endangle exch def /startangle exch def /k exch def /y exch def /m exch def /c exch def c m y k setcmykcolor 2 setlinejoin 0 0 moveto 0 0 radius startangle endangle arc closepath gsave fill grestore 0 0 0 0 setcmykcolor 1.5 setlinewidth stroke /slicecount slicecount 1 add def} def '
		}else{
			$self->{PS} = 'ERROR: Unsupported subtype.';
		}
	}elsif($graphic eq '2Dbar'){
		if((defined($subtype) && $subtype==1) || !defined($subtype)){
			$self->{PS} = '/typecolor {0 setgray} def /straighttype {/stst exch def gsave 1 hsize div 1 vsize div scale stst show grestore} def /rectoffset 2 def /Helvetica findfont 9 scalefont setfont /centertype { /hpos exch def  /cpos exch def /ctstring exch def ctstring stringwidth pop 2 div cpos exch sub  hpos moveto ctstring straighttype} def /fillrect { /rectheight exch def /rectwidth exch def /lly exch def /llx exch def llx lly moveto 0 rectheight rlineto rectwidth 0 rlineto 0 rectheight neg rlineto closepath fill }def /outlinerect {/rectheight exch def /rectwidth exch def /lly exch def /llx exch def llx lly moveto 0 rectheight rlineto rectwidth 0 rlineto 0 rectheight neg rlineto closepath stroke } def  /bar {    /barwidth exch def    /barstart exch def   /l2 exch def   /l1 exch def    /barvalue exch def    /barlength exch def    /pos exch def    /k exch def    /y exch def    /m exch def    /c exch def    /st barstart def    headertype l1 0 st barwidth 3 div add 12 add moveto straighttype l2 0 st barwidth 3 div add moveto straighttype valuecolor valuetype barvalue 80 barlength add barstart barwidth 3 div add moveto straighttype c m y k setcmykcolor 72 st barlength barwidth fillrect   } def /bkgroundbox {   /bheight exch def  /bwidth exch def  /by exch def  /bx exch def  bkground  bx by bwidth bheight fillrect   .5 setlinewidth typecolor  bx by moveto  0 bheight rlineto  bwidth 0 rlineto  0 bheight neg rlineto  closepath  stroke   } def    /chartscale {   /vsize exch def  /hsize exch def  /barwidth exch def /bardepth exch def /val5 exch def  /val4 exch def  /val3 exch def  /val2 exch def  /val1 exch def  /val0 exch def axistype typecolor .5 setlinewidth /fifthline {barwidth 5 div} def   0 fifthline barwidth {  /x exch def 71 x add 0 moveto gsave 0 bardepth rlineto stroke grestore } for  val0 71 -12 centertype  val1 71 fifthline add -12 centertype val2 71 fifthline 2 mul add -12 centertype  val3 71 fifthline 3 mul add -12 centertype val4 71 fifthline 4 mul add -12 centertype val5 71 fifthline 5 mul add -12 centertype } def';
		}else{
			$self->{PS} = 'ERROR: Unsupported subtype.';
		}
	}elsif($graphic eq '2Dcolumn'){
		if((defined($subtype) && $subtype==1) || !defined($subtype)){
			$self->{PS} = '/shadowblk 0.5 def /typecolor {0 setgray} def /straighttype {/stst exch def gsave 1 hsize div 1 vsize div scale stst show grestore} def/rectoffset 2 def /Helvetica findfont 9 scalefont setfont /centertype { /hpos exch def  /cpos exch def /ctstring exch def ctstring stringwidth pop 2 div cpos exch sub  hpos moveto ctstring straighttype} def /fillrect { /rectheight exch def /rectwidth exch def /lly exch def /llx exch def llx lly moveto 0 rectheight rlineto rectwidth 0 rlineto 0 rectheight neg rlineto closepath fill }def /column { /ccwidth exch def /cstart exch def /l2 exch def /l1 exch def /cvalue exch def /height exch def /pos exch def /k exch def /y exch def /m exch def /c exch def /st cstart def headertype l1 st ccwidth 2 div add 262 vsize mul 12 add centertype l2 st ccwidth 2 div add 262 vsize mul centertype typecolor valuetype cvalue st ccwidth 2 div add 226 vsize mul centertype /blkstep{  shadowblk k sub ccwidth 3 div div } def /shadowblk1 shadowblk def 1 1 ccwidth 3 div{ c m y shadowblk1 setcmykcolor st 0 1 height fillrect /st st 1 add def /shadowblk1 shadowblk1 blkstep sub def }for c m y shadowblk1 setcmykcolor st 0 ccwidth 3 div height fillrect /st st ccwidth 3 div add def 1 1 ccwidth 3 div{ c m y shadowblk1 setcmykcolor st 0 1 height fillrect /st st 1 add def /shadowblk1 shadowblk1 blkstep add def }for } def /bkgroundbox { /bheight exch def /bwidth exch def /by exch def /bx exch def bkground bx by bwidth bheight fillrect .5 setlinewidth typecolor bx by moveto 0 bheight rlineto bwidth 0 rlineto 0 bheight neg rlineto closepath stroke } def  /chartscale { /vsize exch def /hsize exch def /cwidth exch def /val5 exch def /val4 exch def /val3 exch def /val2 exch def /val1 exch def /val0 exch def axistype typecolor .5 setlinewidth 0 43 vsize mul 214 vsize mul 1 sub { /y exch def 71 y moveto cwidth 0 rlineto } for stroke val0 dup gsave 1 hsize div 1 scale stringwidth grestore pop 69 exch sub 0 moveto straighttype val1 dup gsave 1 hsize div 1 scale stringwidth grestore pop 69 exch sub 41 vsize mul moveto straighttype val2 dup gsave 1 hsize div 1 scale stringwidth grestore pop 69 exch sub 84 vsize mul moveto straighttype val3 dup gsave 1 hsize div 1 scale stringwidth grestore pop 69 exch sub 127 vsize mul moveto straighttype val4 dup  gsave 1 hsize div 1 scale stringwidth grestore pop 69 exch sub 170 vsize mul moveto straighttype val5 dup gsave 1 hsize div 1 scale stringwidth grestore pop 69 exch sub 213 vsize mul moveto straighttype } def';
		}else{
			$self->{PS} = 'ERROR: Unsupported subtype.';
		}
	}else{
		$self->{PS} = 'ERROR: Unsupported graphic.';
	}
	return $self->{PS};
}
sub getPS{
	my($self)=@_;
	return $self->{PS};
}
sub setSubtype{
	my ( $self, $Subtype) = @_;
    $self->{Subtype} = $Subtype if defined($Subtype);
    return $self->{Subtype};
}
sub getSubtype {
    my( $self ) = @_;
    return $self->{Subtype};
}
sub setHscale{
	my ( $self, $hscale) = @_;
    $self->{Hscale} = $hscale if defined($hscale);
    return $self->{Hscale};
}
sub getHscale {
    my( $self ) = @_;
    return $self->{Hscale};
}
sub setVscale{
	my ( $self, $vscale) = @_;
    $self->{Vscale} = $vscale if defined($vscale);
    return $self->{Vscale};
}
sub getVscale {
    my( $self ) = @_;
    return $self->{Vscale};
}
sub setInitialdegree{
	my ( $self, $initialdegree) = @_;
    $self->{Initialdegree} = $initialdegree if defined($initialdegree);
    return $self->{Initialdegree};
}
sub getInitialdegree {
    my( $self ) = @_;
    return $self->{Initialdegree};
}
sub setGexport{
	my ( $self, $gexport) = @_;
    $self->{Gexport} = $gexport if defined($gexport);
    return $self->{Gexport};
}
sub getGexport {
    my( $self ) = @_;
    return $self->{Gexport};
}
sub setLegend{
	my ( $self, $legend) = @_;
    $self->{Legend} = $legend if defined($legend);
    return $self->{Legend};
}
sub getLegend {
    my( $self ) = @_;
    return $self->{Legend};
}
sub setColumnwidth {
	my ( $self, $columnwidth) = @_;
    $self->{Columnwidth} = $columnwidth if defined($columnwidth);
    return $self->{Columnwidth};
}
sub getColumnwidth {
    my( $self ) = @_;
    return $self->{Columnwidth};
}
sub setFormat {
	my ( $self, $format) = @_;
    $self->{Format} = $format if defined($format);
    return $self->{Format};
}
sub getFormat {
    my( $self ) = @_;
    return $self->{Format};
}
sub setHeadertype {
	my ( $self, $headertype) = @_;
    $self->{Headertype} = $headertype if defined($headertype);
    return $self->{Headertype};
}
sub getHeadertype {
    my( $self ) = @_;
    return $self->{Headertype};
}
sub setAxistype {
	my ( $self, $axistype) = @_;
    $self->{Axistype} = $axistype if defined($axistype);
    return $self->{Axistype};
}
sub getAxistype {
    my( $self ) = @_;
    return $self->{Axistype};
}
sub setValuetype {
	my ( $self, $valuetype) = @_;
    $self->{Valuetype} = $valuetype if defined($valuetype);
    return $self->{Valuetype};
}
sub getValuetype {
    my( $self ) = @_;
    return $self->{Valuetype};
}
sub setValuecolor {
	my ( $self, $valuetype) = @_;
    $self->{Valuecolor} = $valuetype if defined($valuetype);
    return $self->{Valuecolor};
}
sub getValuecolor {
    my( $self ) = @_;
    return $self->{Valuecolor};
}
sub setBackgroundcolor {
	my ( $self, $backgroundcolor) = @_;
    $self->{Backgroundcolor} = $backgroundcolor if defined($backgroundcolor);
    return $self->{Backgroundcolor};
}
sub getBackgroundcolor {
    my( $self ) = @_;
    return $self->{Backgroundcolor};
}
sub setHeadercolor {
	my ( $self, $headercolor) = @_;
    $self->{Headercolor} = $headercolor if defined($headercolor);
    return $self->{Headercolor};
}
sub getHeadercolor {
    my( $self ) = @_;
    return $self->{Headercolor};
}
sub setExplodeoffset{
	my ( $self, $explodeoffset) = @_;
    $self->{Explodeoffset} = $explodeoffset if defined($explodeoffset);
    return $self->{Explodeoffset};
}
sub getExplodeoffset {
    my( $self ) = @_;
    return $self->{Explodeoffset};
}
sub showInfo{
    my( $self ) = @_;
	print "LabelandColor: " . $self->getLabelandColor . "\n";
	print "Data: " . $self->getData . "\n";	
	print "Graphic: " . $self->getGraphic . "\n";	
	print "PS: " . $self->getPS . "\n";	
	if(defined($self->getSubtype)){print "Subtype: " . $self->getSubtype . "\n";}else{print "Subtype: Not Defined\n";}	
	if(defined($self->getHscale)){print "Hscale: " . $self->getHscale . "\n";}else{print "Hscale: Not Defined\n";}	
	if(defined($self->getVscale)){print "Vscale: " . $self->getVscale . "\n";}else{print "Vscale: Not Defined\n";};	
	if(defined($self->getGexport)){print "Gexport: " . $self->getGexport . "\n";}else{print "Gexport: Not Defined\n";}
	if(defined($self->getLegend)){print "Legend: " . $self->getLegend . "\n";}else{print "Legend: Not Defined\n";}
	if(defined($self->getColumnwidth)){print "Columnwidth: " . $self->getColumnwidth . "\n";}else{print "Columnwidth: Not Defined\n";}
	if(defined($self->getFormat)){print "Format: " . $self->getFormat . "\n";}else{print "Format: Not Defined\n";}
	if(defined($self->getHeadertype)){print "Headertype: " . $self->getHeadertype . "\n";}else{print "Headertype: Not Defined\n";}
	if(defined($self->getAxistype)){print "Axistype: " . $self->getAxistype . "\n";}else{print "Axistype: Not Defined\n";}
	if(defined($self->getValuetype)){print "Valuetype: " . $self->getValuetype . "\n";}else{print "Valuetype: Not Defined\n";}
	if(defined($self->getBackgroundcolor)){print "Backgroundcolor: " . $self->getBackgroundcolor . "\n";}else{print "Backgroundcolor: Not Defined\n";}
	if(defined($self->getHeadercolor)){print "Headercolor: " . $self->getHeadercolor . "\n";}else{print "Headercolor: Not Defined\n";}
	if(defined($self->getExplodeoffset)){print "Explodeoffset: " . $self->getExplodeoffset . "\n";}else{print "Explodeoffset: Not Defined\n";}
	if(defined($self->getInitialdegree)){print "Initialdegree: " . $self->getInitialdegree . "\n";}else{print "Initialdegree: Not Defined\n";}
}
sub writeGraphic {
	my( $self ) = @_;
	if($self->{Graphic} eq '2Dpie'){
		#translate data into degrees in a circle for pie
		my $transdata=&data2degrees($self->{Data});
		if(defined($self->{Data}) && defined($self->{LabelandColor})){
			if(!defined($self->{Hscale})){$self->{Hscale}=1;}
			if(!defined($self->{Vscale})){$self->{Vscale}=1;}
			if(!defined($self->{Gexport})){$self->{Gexport}='';}
			if(!defined($self->{Valuetype})){$self->{Valuetype}=8;}
			if(!defined($self->{Explodeoffset})){$self->{Expoldeoffset}=12;}
			if(!defined($self->{Initialdegree})){$self->{Initialdegree}=120;}
			if((defined($self->{Subtype}) && $self->{Subtype}==1) || !defined($self->{Subtype})){
				return &pie1($self->{Initialdegree},$self->{PS}, $transdata, $self->{LabelandColor}, $self->{Hscale}, $self->{Vscale}, $self->{Gexport}, $self->{Valuetype});
			}elsif((defined($self->{Subtype}) && $self->{Subtype}==2)){
				return &pie2($self->{Initialdegree},$self->{PS}, $transdata, $self->{LabelandColor}, $self->{Hscale}, $self->{Vscale}, $self->{Gexport}, $self->{Valuetype});
			}elsif(defined($self->{Subtype}) && ($self->{Subtype}==3 || $self->{Subtype}==31 || $self->{Subtype}==4)){
				if(!defined($self->{Legend})){$self->setLegend('right');}
				my $leg=$self->getLegend;
				if($leg eq 'right' || $leg eq 'left' || $leg eq 'bottom'){
					if($self->{Subtype}==3){
                 		return &pie3($self->{Initialdegree},$self->{PS}, $transdata, $self->{LabelandColor}, $self->{Hscale}, $self->{Vscale}, $self->{Gexport}, $self->getLegend, $self->{Valuetype});
					}elsif($self->{Subtype}==31){
						return &pie31($self->{Initialdegree},$self->{PS}, $transdata, $self->{LabelandColor}, $self->{Hscale}, $self->{Vscale}, $self->{Gexport}, $self->getLegend, $self->{Valuetype});
					}elsif($self->{Subtype}==4){
						return &pie4($self->{Initialdegree},$self->{PS}, $transdata, $self->{LabelandColor}, $self->{Hscale}, $self->{Vscale}, $self->{Gexport}, $self->getLegend, $self->{Valuetype});
					}
				}else{
					return "Legend must be right, left or bottom.";
				}
			}elsif($self->{Subtype}==41){
				return &pie41($self->{Initialdegree},$self->{PS}, $transdata, $self->{LabelandColor}, $self->{Hscale}, $self->{Vscale}, $self->{Gexport}, $self->{Valuetype});
			}elsif((defined($self->{Subtype}) && $self->{Subtype}==5)){
				#set centers for section translations for exploded pies
				#step through slices and add degrees to combine them into sections
				my $sectionends="";
				my @sectionarray="";
				my $sectionend;
				my $sectioncenters;
				my $currentsection=1;
				my $currentslice=0;
				my @lc;
				my @da;
				my $dalength;
				my $transdata1='trans1';
				#create an string, comma delimited, with the field numbers of the end sections
				open(LC,$self->{LabelandColor}) || die "Cannot open LabelAndColor!\n";
				while(<LC>){
					@lc = split/\t/;
					chomp;
					$currentslice++;
					if($lc[5] != $currentsection){
						$sectionend=int($currentslice)-1;
						if(length($sectionends)>0){$sectionends.=",";}
						$sectionends.=$sectionend;
						$currentsection=$lc[5];
					}
				}
				$sectionends.="," . $currentslice;
				#add the halfangles of the sections in a comma delimited string to the end of the row in transdata
				open(TRANS, "<$transdata") || die "Cannot open transdata for reading!\n";
				open(TRANSPLUS, ">$transdata1") || die "Cannot open transdata1 for writing!\n";
				my $sectionmiddle="";
				while(<TRANS>){
					chomp;
					my $dataline=$_;
					@da = split/\t/;
					$dalength=@da;
					@sectionarray=split/,/,$sectionends;
					my $salength=@sectionarray;
					my $secdegrees=0;
					my $lastsection=0;
					my $thissection=0;
					my $jj=$sectionarray[$thissection];
					for(my $ii=0; $ii<$dalength ; $ii++){
						if($ii==$jj){
							if(length($sectionmiddle)>0){$sectionmiddle.=',';}
							$sectionmiddle.=(.5)*($secdegrees+$lastsection);
							$lastsection=$secdegrees;
							$thissection++;
							$jj=$sectionarray[$thissection];
							if($thissection==($salength-1)){
								$sectionmiddle.="," . (.5)*(360+$secdegrees);
								last;
							}
						}
						$secdegrees+=$da[$ii];
					}
					print TRANSPLUS $dataline . "\t$sectionmiddle\n";
					$sectionmiddle="";
				}
				close TRANSPLUS;
				return &pie5($self->{Initialdegree},$self->{PS}, $transdata1, $self->{LabelandColor}, $self->{Hscale}, $self->{Vscale}, $self->{Gexport}, $self->{Valuetype}, $self->{Explodeoffset}, $sectionends);
			}elsif((defined($self->{Subtype}) && $self->{Subtype}==6) || !defined($self->{Subtype})){
				return &pie6($self->{Initialdegree},$self->{PS}, $transdata, $self->{LabelandColor}, $self->{Hscale}, $self->{Vscale}, $self->{Gexport}, $self->{Valuetype});
			}
		}else{
					return "Both the data file (setData) and the color file (setLabelandColor) must be defined.";
		}
	}elsif($self->{Graphic} eq '2Dcolumn'){
		if(defined($self->{Data}) && defined($self->{LabelandColor})){
			if(!defined($self->{Hscale})){$self->{Hscale}=1;}
			if(!defined($self->{Vscale})){$self->{Vscale}=1;}
			if(!defined($self->{Gexport})){$self->{Gexport}='';}
			if(!defined($self->{Columnwidth})){$self->{Columnwidth}=36;}
			if(!defined($self->{Format})){$self->{Format}="money";}
			if(!defined($self->{Headertype})){$self->{Headertype}=9;}
			if(!defined($self->{Valuetype})){$self->{Valuetype}=9;}
			if(!defined($self->{Axistype})){$self->{Axistype}=8;}
			if(!defined($self->{Backgroundcolor})){$self->{Backgroundcolor}='.3 0 .15 .09';}
			if(!defined($self->{Headercolor})){$self->{Headercolor}='0 0 0 1';}
			if((defined($self->{Subtype}) && $self->{Subtype}==1) || !defined($self->{Subtype})){
				return &column1($self->{PS}, $self->{Data}, $self->{LabelandColor}, $self->{Hscale}, $self->{Vscale}, $self->{Gexport},$self->{Columnwidth}, $self->{Format}, $self->{Headertype}, $self->{Axistype}, $self->{Valuetype}, $self->{Backgroundcolor}, $self->{Headercolor});
			}
		}else{
            return "Both the data file (setData) and the color file (setLabelandColor) must be defined.";
        }
	}elsif($self->{Graphic} eq '2Dbar'){
		if(defined($self->{Data}) && defined($self->{LabelandColor})){
			if(!defined($self->{Hscale})){$self->{Hscale}=1;}
			if(!defined($self->{Vscale})){$self->{Vscale}=1;}
			if(!defined($self->{Gexport})){$self->{Gexport}='';}
			if(!defined($self->{Columnwidth})){$self->{Columnwidth}=36;}
			if(!defined($self->{Format})){$self->{Format}="money";}
			if(!defined($self->{Headertype})){$self->{Headertype}=9;}
			if(!defined($self->{Valuetype})){$self->{Valuetype}=9;}
			if(!defined($self->{Valuecolor})){$self->{Valuecolor}=0;}
			if(!defined($self->{Axistype})){$self->{Axistype}=8;}
			if(!defined($self->{Backgroundcolor})){$self->{Backgroundcolor}='.3 0 .15 .09';}
			if(!defined($self->{Headercolor})){$self->{Headercolor}='0 0 0 1';}
			if((defined($self->{Subtype}) && $self->{Subtype}==1) || !defined($self->{Subtype})){
				return &bar1($self->{PS}, $self->{Data}, $self->{LabelandColor}, $self->{Hscale}, $self->{Vscale}, $self->{Gexport},$self->{Columnwidth}, $self->{Format}, $self->{Headertype}, $self->{Axistype}, $self->{Valuetype}, $self->{Backgroundcolor}, $self->{Headercolor}, $self->{Valuecolor});
			}
		}else{
            return "Both the data file (setData) and the color file (setLabelandColor) must be defined.";
        }
	}else{
		return "Cannot write undefined graphic!"; 
	}
}
sub data2degrees {
	my ($data) = @_;
	my $trans="trans";
	my @totaldata;
	open(DATA, "./" . $data) || die "Could not open ./$data file!\n";
	open(TRANS, ">$trans") || die "Could not open trans file for writing!\n";
	open(DATA1, "+>data1") || die "Could not open data1 file for writing!\n";
	#sum the slices to create a totals field
	my @sum;
	my @drow1;
	while(<DATA>){
		my @drow=split ("\t", $_);
		my $total=0;
		my $drow1='';
		my $ddd=@drow-1;
		chomp($ddd);
		#find the largest slice
		for(my $a=0; $a<@drow-1; $a++){
			$sum[$a]+=$drow[$a];
			$total+=$drow[$a];
			if($drow1 eq ''){
				$drow1.=$drow[$a];
			}else{
				$drow1.="\t" . $drow[$a];
			}
		}
		#chomp($drow[@drow-1]);
		$drow1.="\t" .  $drow[$ddd];
		chomp($drow1);
		$drow1.="\t" .  $total;
		print DATA1 $drow1 . "\n";
	}	
	my $largest;
	my $lvalue=0;
	for($b=0; $b<@sum; $b++){
		if($sum[$b]>$lvalue){
			$lvalue=$sum[$b];
			$largest=$b;
		}
	}
	seek DATA1, 0, 0;
	while(<DATA1>){
		my @crow=split ("\t", $_);
		my @d;
		my $otherdegrees=0;
		for(my $c=0; $c<@crow-2; $c++){
			if($c!=$largest){
				$d[$c]=360*$crow[$c]/$crow[@crow-1];
				if($d[$c]>0){
					if($d[$c]<3.6){$d[$c]=3.6;}
					$otherdegrees+=$d[$c];
				}
			}
		}
		$d[$largest]=360-$otherdegrees;
		push @d, $crow[@crow-2];
		print TRANS join("\t",@d) . "\n";
print join("\t",@d) . "\n";
	}
	close TRANS;
	return $trans;
}
sub pie1{
	my ($startingangle,$ps, $data, $labelandcolor, $hscale, $vscale, $gexport, $valuetype) = @_; 
	my $slicecounter; my $piefile; my $piececount; my $thisdate = scalar localtime; my $piedirectory="pies/"; my @slice; my $slicecnt; my $piefileextension="eps"; my $hsize=$hscale; my $vsize=$vscale;  my $yend; my $labelmax=0; my $labelx; open(LABELANDCOLOR, "<$labelandcolor") or die("Couldn't open $labelandcolor\n"); while(<LABELANDCOLOR>) {$_=~s/\t.*//; $_=~s/ *$//; chomp; $labelx=length($_)+10; if($labelx>$labelmax){$labelmax=$labelx; } $piececount++;} close(LABELANDCOLOR); my $xstart=int(306-($hsize*350/2)-($labelmax*$hsize)); my $xend=int(306+($hsize*350/2)+($labelmax*$hsize)); my $ystart=int(396-($vsize*350/2)-($labelmax*$vsize)); $yend=int(396+($vsize*350/2)+($labelmax*$vsize)); my @lclines; my $lclines; my $label; my $c; my $m; my $y; my $k; my $thisendangle; my $thisslice; my $thisstartangle; my $filewithdir; my $thispiefile; open(PIECHARTDATA, "<$data") || die "Couldn't open $data\n"; while(<PIECHARTDATA>) {chomp; @slice=split/\t/,$_; $slicecnt=@slice; $piefile=$slice[$slicecnt-1]; $thisslice=$slice[0]; $slicecounter=0; $thispiefile=$piefile.".".$piefileextension; $filewithdir=$piedirectory.$thispiefile; open(PIE, ">$filewithdir") or die("Couldn't create output file: ".$thispiefile); print PIE "%!PS-ADOBE 3.0 EPSF-3.0\n"; print PIE "%%Title: ".$thispiefile."\n"; print PIE "%%Creator: createpies.pl (c)Ken Owen 1999-2016\n"; print PIE "%%Creationdate: ".$thisdate."\n"; print PIE "%%BoundingBox: $xstart $ystart $xend $yend\n\n"; print PIE "/typesize " . $valuetype . " def\n"; print PIE $ps; print PIE "gsave 1 $hscale div 1 $vscale div scale label dup stringwidth pop checkangle 110 lt {2 div}if checkangle 250 gt {2 div}if -1 mul 2 rmoveto show grestore c m y k setcmykcolor 2 setlinejoin 0 0 moveto 0 0 radius startangle endangle arc closepath gsave fill grestore 0 0 0 0 setcmykcolor 1.5 setlinewidth stroke /slicecount slicecount 1 add def} def\n"; print PIE "\n%%set scale and translation\n"; print PIE "306 396 translate $hsize $vsize scale\n"; $thisstartangle=$startingangle; open(LABELANDCOLOR, "<$labelandcolor") or die("Couldn't open $labelandcolor"); my $counter=0; while (<LABELANDCOLOR>) { chomp; $lclines[$counter]=$_; $counter++; } foreach $lclines(@lclines){ ($label, $c, $m, $y, $k)=split/\t/,$lclines; print PIE "%%draw pie chart\n"; $thisendangle=$thisstartangle+eval($thisslice); if(eval($thisslice)>0){ print PIE "$c $m $y $k $thisstartangle $thisendangle ($label) pieslice\n"; } $thisstartangle=$thisendangle; $slicecounter++; $thisslice=$slice[$slicecounter]; } my $exportstr="convert $filewithdir -density 1200x1200 $piedirectory$piefile.$gexport"; print PIE "\n"; print PIE "showpage\n"; print PIE "grestore\n"; print PIE "%%trailer\n"; print PIE "%%EOF"; close LABELANDCOLOR; close PIE; if(length($gexport)>0){`$exportstr`;} 
}}
sub pie2{
my ($startingangle, $ps, $data, $labelandcolor, $hsize, $vsize, $gexport, $valuetype) = @_;
my $piefileextension="eps"; my $xstart=int(306-($hsize*385/2)); my $xend=int(306+($hsize*385/2 + 10)); my $ystart=int(396-($vsize*350/2) - 8); my $yend=int(396+($vsize*350/2)); my @slice; my $slice; my $piefile; my $piedirectory="pies/"; my $thisdate = scalar localtime; my $thisslice; my $slicecounter; my $filewithdir; my $thisstartangle; my $thisendangle; my $percent1; my $no_slices; my $piename; open(PIECHARTDATA, "<$data") or die("Couldn't open $data"); while (<PIECHARTDATA>) {chomp; @slice=split(/\t/,$_); $no_slices=@slice; $piefile=$slice[$no_slices-1]; $piename=$piefile; $piefile.="\.".$piefileextension; $thisslice=$slice[0]; $slicecounter=0; $filewithdir=$piedirectory.$piefile; open(PIE, ">$filewithdir") or die("Couldn't create output file: ".$piefile); print PIE "%!PS-ADOBE 3.0 EPSF-3.0\n"; print PIE "%%Title: ".$piefile."\n"; print PIE "%%Creator: createpies.pl (c)Ken Owen 1999-2016\n"; print PIE "%%Creationdate: ".$thisdate."\n"; print PIE "%%BoundingBox: $xstart $ystart $xend $yend\n\n"; print PIE "/typesize " . $valuetype . " def\n"; print PIE $ps; print PIE "%%set scale and translation\n"; print PIE "306 396 translate $hsize $vsize scale\n"; $thisstartangle=$startingangle; open(LABELANDCOLOR, "<$labelandcolor") or die("Couldn't open $labelandcolor"); my $counter=0; my @lclines; my $lclines; while (<LABELANDCOLOR>) {chomp; $lclines[$counter]=$_; $counter++; } $counter=@lclines; my $labelx=0; my $labely=$counter*$vsize*9+50; $counter=0; my $wholepercent=0; my $percent1num=0; foreach $lclines(@lclines){my ($label, $c, $m, $y, $k)=split(/\t/,$lclines); print PIE "%%draw pie chart\n"; $thisendangle=$thisstartangle+eval($thisslice); if(eval($thisslice)>0){$percent1num=int(100*eval($thisslice)/360); if(((100*eval($thisslice)/36) % 10) >= 5){$percent1num++;} $percent1=substr($percent1num,0)."%"; if($percent1num == 0){$percent1num=1;} $wholepercent+=$percent1num; if($wholepercent == 101){$percent1num--; $percent1=substr($percent1num,0) . "%"; } print PIE "$c $m $y $k $thisstartangle $thisendangle ($label) ($percent1) pieslice\n"; } $thisstartangle=$thisendangle; $slicecounter++; $thisslice=$slice[$slicecounter]; } my $exportstr="convert $filewithdir -density 1200x1200 $piedirectory$piename.$gexport";  print PIE "\n"; print PIE "showpage\n"; print PIE "grestore\n"; print PIE "%%trailer\n"; print PIE "%%EOF"; close LABELANDCOLOR; close PIE; if(length($gexport)>0){`$exportstr`;} }
}
sub pie3{
	my ($startingangle, $ps, $data, $labelandcolor, $hsize, $vsize, $gexport, $legend, $valuetype) = @_; my $piececount=0; my @slice; my $piename; my $slicecnt; my $filecounter; my @pclines;  my $c; my $y; my $m; my $k; my $pclines; my $piefile; my $piedirectory; my $thisslice; my $thispiefile; my $leftright;  my $lclines; my @lclines; my $slicecounter; my $thisdate; my $filewithdir; my $thisstartangle; my $thisendangle;  my $label; my $piefileextension="eps"; my $legend_right;  my $boundingxend; my $boundingxstart;  my $xstart; my $xend; my $ystart; my $yend; my $labelmax=0; my $labelx;  open(LABELANDCOLOR, "<$labelandcolor") or die("Couldn't open $labelandcolor\n");  while(<LABELANDCOLOR>) { $_=~s/\t.*//; $_=~s/ *$//;  chomp;  $labelx=length($_);  if($labelx>$labelmax){$labelmax=$labelx; } $piececount++;} close(LABELANDCOLOR);  if($legend eq "right"){  $boundingxend=int(306+($hsize*321/2)+($labelmax*9)*$hsize);  $boundingxstart=int(306-($hsize*321/2));  $xstart=int(306-($hsize*260/2));  $xend=int(306+($hsize*260/2));  $ystart=int(396-($vsize*308/2)); $yend=int(396+($vsize*308/2));  }elsif($legend eq "left"){ $boundingxstart=int(306-($hsize*321/2)-($labelmax*9)*$hsize);  $boundingxend=int(306+($hsize*321/2)*$hsize);  $xstart=int(306-($hsize*260/2));  $xend=int(306+($hsize*260/2));  $ystart=int(396-($vsize*308/2));  $yend=int(396+($vsize*308/2));  }elsif($legend eq "bottom"){ $boundingxstart=int(306-($hsize*315/2));  $boundingxend=int(306+($hsize*315/2));  $xstart=int(306-($hsize*315/2));  $xend=int(306+($hsize*315/2));  $ystart=int(396-150-($piececount)*($vsize*25));  $yend=int(396+($vsize*130));  }else{  $xstart=int(306-($hsize*315/2));  $xend=int(306+($hsize*315/2));  $ystart=int(396-($vsize*315/2)-30);  $yend=int(396+($vsize*350/2)); }  open(PIECHARTDATA, "<$data") or die("Couldn't open $data");  my $counter=0;  while (<PIECHARTDATA>) {  $pclines[$counter]=$_;  $counter++;  }  foreach $pclines(@pclines){@slice=split(/\t/,$pclines);  chomp($slice[2]);  $slicecnt=@slice;  $piefile=$slice[$slicecnt-1];  chomp($piefile);  $piename=$piefile;  $piefile.="\.".$piefileextension;  $piedirectory="pies/";  $thisdate = scalar localtime;  $thisslice=$slice[0];  $slicecounter=0;  $filewithdir=$piedirectory.$piefile;  open(PIE, ">$filewithdir") or die("Couldn't create output file: ".$thispiefile);  print PIE "%!PS-ADOBE 3.0 EPSF-3.0\n";  print PIE "%%Title: ".$piefile."\n";  print PIE "%%Creator: createpies.pl (c)Ken Owen 1999-2016\n";  print PIE "%%Creationdate: ".$thisdate."\n";  if($legend eq "right" || $legend eq "left") {      print PIE "%%BoundingBox: $boundingxstart $ystart $boundingxend $yend\n\n";  }elsif($legend eq "bottom") {  print PIE "%%BoundingBox: $boundingxstart $ystart $boundingxend $yend\n\n";  }else{  print PIE "%%BoundingBox: $xstart $ystart $xend $yend\n\n";  } print PIE "<< /PageSize [1000 1000] >> setpagedevice \n gsave\n";  print PIE $ps;  print PIE "%%set scale and translation\n";  print PIE "306 396 translate $hsize $vsize scale\n";  $thisstartangle=$startingangle;  open(LABELANDCOLOR, "<$labelandcolor") or die("Couldn't open $labelandcolor\n");  $counter=0;  while (<LABELANDCOLOR>) {  chomp;  $lclines[$counter]=$_;  $counter++;  }  $counter=@lclines;  $labelx=0;  my $labely=$counter*$vsize*$valuetype;  $counter=0;  foreach $lclines(@lclines){  ($label, $c, $m, $y, $k)=split(/\t/,$lclines);  print PIE "%%draw pie chart\n";     $thisendangle=$thisstartangle+eval($thisslice);  if(eval($thisslice)>0){  print PIE "$c $m $y $k $thisstartangle $thisendangle ($label) pieslice\n";   if($legend eq "bottom"){  $leftright=0;  $labelx=-100;  $labely=-150-($slicecounter*25);  print PIE "$c $m $y $k ($label) $labelx $labely $leftright  $hsize $vsize legend\n";  $thisstartangle=$thisendangle; $thisslice=$slice[$slicecounter];  }elsif($legend eq "right"){  $labelx=(260/2) + 10;  $labely=$labely-28;  $counter++;  print PIE "$c $m $y $k ($label) $labelx $labely $hsize $vsize legend_right\n";  }elsif($legend eq "left"){ $labelx=-((260/2) + 10);  $labely=$labely-28; $counter++;  print PIE "$c $m $y $k ($label) $labelx $labely $hsize $vsize legend_left\n";  }  } $thisstartangle=$thisendangle; $slicecounter++; $thisslice=$slice[$slicecounter];  }  my $exportstr="convert $filewithdir -density 1200x1200 $piedirectory$piename.$gexport";  print PIE "\n";  print PIE "showpage\n";  print PIE "grestore\n";  print PIE "%%trailer\n";  print PIE "%%EOF";  if(length($gexport)>0){ `$exportstr`;  } }  close LABELANDCOLOR;  close PIE;
}
sub pie31{
my ($startingangle, $ps, $data, $labelandcolor, $hsize, $vsize, $gexport, $legend, $valuetype) = @_; my $piececount=0; my @slice; my $piename; my $slicecnt; my $filecounter; my @pclines; my $c; my $y; my $m; my $k; my $pclines; my $piefile; my $piedirectory; my $thisslice; my $thispiefile; my $leftright; my $lclines; my @lclines; my $slicecounter; my $thisdate; my $filewithdir; my $thisstartangle; my $thisendangle; my $label; my $piefileextension="eps"; my $legend_right; my $boundingxend; my $boundingxstart; my $xstart; my $xend; my $ystart; my $yend; my $labelmax=0; my $labelx; my $percent1num; my $percent1; my $wholepercent; open(LABELANDCOLOR, "<$labelandcolor") or die("Couldn't open $labelandcolor\n"); while(<LABELANDCOLOR>) { $_=~s/\t.*//; $_=~s/ *$//; chomp; $labelx=length($_); if($labelx>$labelmax){ $labelmax=$labelx; } $piececount++; } close(LABELANDCOLOR); if($legend eq "right"){ $boundingxend=int(306+130+($labelmax*9)*$hsize); $boundingxstart=int(306-($hsize*200)); $xstart=int(306-($hsize*260/2)); $xend=int(306+($hsize*260/2)); $ystart=int(396-($vsize*308/2)-($vsize*30)); $yend=int(396+($vsize*308/2)+($vsize*30)); }elsif($legend eq "left"){ $boundingxstart=int(306-120-($labelmax*9)*$hsize); $boundingxend=int(306+(321/2)*$hsize); $xstart=int(306-($hsize*280/2)); $xend=int(306+($hsize*260/2)); $ystart=int(396-($vsize*308/2)-($vsize*30)); $yend=int(396+($vsize*308/2)+($vsize*30)); print "labelmax=$labelmax boundingxstart=$boundingxstart xstart=$xstart\n"; }elsif($legend eq "bottom"){ $boundingxstart=int(306-($hsize*315/2)-30); $boundingxend=int(306+($hsize*315/2)+30); $xstart=int(306-($hsize*315/2)); $xend=int(306+($hsize*315/2)); $ystart=int(396-100-($piececount)*($vsize*25)); $yend=int(396+($vsize*180)); }else{ $xstart=int(306-($hsize*315/2)); $xend=int(306+($hsize*315/2)); $ystart=int(396-($vsize*315/2)-30); $yend=int(396+($vsize*350/2)); } open(PIECHARTDATA, "<$data") or die("Couldn't open $data"); my $counter=0; while (<PIECHARTDATA>) { $pclines[$counter]=$_; $counter++; } foreach $pclines(@pclines){ @slice=split(/\t/,$pclines); chomp($slice[2]); $slicecnt=@slice; $piefile=$slice[$slicecnt-1]; chomp($piefile); $piename=$piefile; $piefile.="\.".$piefileextension; $piedirectory="pies/"; $thisdate = scalar localtime; $thisslice=$slice[0]; $slicecounter=0; $filewithdir=$piedirectory.$piefile; open(PIE, ">$filewithdir") or die("Couldn't create output file: ".$thispiefile); print PIE "%!PS-ADOBE 3.0 EPSF-3.0\n"; print PIE "%%Title: ".$piefile."\n"; print PIE "%%Creator: createpies.pl (c)Ken Owen 1999-2016\n"; print PIE "%%Creationdate: ".$thisdate."\n"; if($legend eq "right" || $legend eq "left") { print PIE "%%BoundingBox: $boundingxstart $ystart $boundingxend $yend\n\n"; }elsif($legend eq "bottom") { print PIE "%%BoundingBox: $boundingxstart $ystart $boundingxend $yend\n\n"; }else{ print PIE "%%BoundingBox: $xstart $ystart $xend $yend\n\n"; } print PIE "<< /PageSize [1000 1000] >> setpagedevice \n gsave\n"; print PIE "/typesize " . $valuetype . " def\n"; print PIE "/legendtype " . $valuetype . " def\n"; print PIE $ps; print PIE "%%set scale and translation\n"; print PIE "306 396 translate $hsize $vsize scale\n"; $thisstartangle=$startingangle; open(LABELANDCOLOR, "<$labelandcolor") or die("Couldn't open $labelandcolor\n"); $counter=0; while (<LABELANDCOLOR>) { chomp; $lclines[$counter]=$_; $counter++; } $counter=@lclines; $labelx=0; my $labely=$counter*$vsize*9; $counter=0; foreach $lclines(@lclines){ ($label, $c, $m, $y, $k)=split(/\t/,$lclines); print PIE "%%draw pie chart\n"; $thisendangle=$thisstartangle+eval($thisslice); if(eval($thisslice)>0){ $percent1num=int(100*eval($thisslice)/360); if(((100*eval($thisslice)/36) % 10) >= 5){ $percent1num++; } $percent1=substr($percent1num,0)."%"; if($percent1num == 0){ $percent1num=1; } $wholepercent+=$percent1num; if($wholepercent == 101){ $percent1num--; $percent1=substr($percent1num,0) . "%"; } print "percent1=$percent1\n"; print PIE "$c $m $y $k $thisstartangle $thisendangle pieslice\n"; if($legend eq "bottom"){ $leftright=0; $labelx=-100; $labely=-200-($slicecounter*$vsize*$valuetype*3); print PIE "$c $m $y $k ($label) $labelx $labely $leftright  $hsize $vsize ( " . $percent1 . ") legend\n"; $thisstartangle=$thisendangle; $thisslice=$slice[$slicecounter]; }elsif($legend eq "right"){ $labelx=(260/2) + 55; $labely=$labely-28; $counter++; print PIE "$c $m $y $k ($label) $labelx $labely $hsize $vsize ( " . $percent1 . ") legend_right\n"; }elsif($legend eq "left"){ $leftright=1; $labelx=-((260/2) + 140); $labely=$labely-28; $counter++; print PIE "$c $m $y $k ($label) $labelx $labely $leftright $hsize $vsize ( " . $percent1 . ") legend\n"; } } $thisstartangle=$thisendangle; $slicecounter++; $thisslice=$slice[$slicecounter]; } my $exportstr="convert $filewithdir -density 1200x1200 $piedirectory$piename.$gexport"; print PIE "\n"; print PIE "showpage\n"; print PIE "grestore\n"; print PIE "%%trailer\n"; print PIE "%%EOF"; if(length($gexport)>0){ `$exportstr`; } } close LABELANDCOLOR; close PIE;
}
sub pie41{
my ($startingangle, $ps, $data, $labelandcolor, $hsize, $vsize, $gexport, $valuetype) = @_; my $piececount=0; my @slice; my $piename; my $slicecnt; my $filecounter; my @pclines; my $c; my $y; my $m; my $k; my $pclines; my $piefile; my $piedirectory; my $thisslice; my $thispiefile; my $leftright; my $lclines; my @lclines; my $slicecounter; my $thisdate; my $filewithdir; my $thisstartangle; my $thisendangle; my $label; my $piefileextension="eps"; my $boundingxend; my $boundingxstart; my $labelmax=0; my $labelx; my $percent1num; my $percent1; my $wholepercent; my $xstart=int(306-($hsize*350/2)-($labelmax*$hsize)); my $xend=int(306+($hsize*350/2)+($labelmax*$hsize)); my $ystart=int(396-($vsize*350/2)-($labelmax*$vsize)); my $yend=int(396+($vsize*350/2)+($labelmax*$vsize)); open(LABELANDCOLOR, "<$labelandcolor") or die("Couldn't open $labelandcolor\n"); while(<LABELANDCOLOR>) { $_=~s/\t.*//; $_=~s/ *$//; chomp; $labelx=length($_); if($labelx>$labelmax){$labelmax=$labelx; } $piececount++; } close(LABELANDCOLOR); open(PIECHARTDATA, "<$data") or die("Couldn't open $data"); my $counter=0; while (<PIECHARTDATA>) { $pclines[$counter]=$_; $counter++; } foreach $pclines(@pclines){ @slice=split(/\t/,$pclines); chomp($slice[2]); $slicecnt=@slice; $piefile=$slice[$slicecnt-1]; chomp($piefile); $piename=$piefile; $piefile.="\.".$piefileextension; $piedirectory="pies/"; $thisdate = scalar localtime; $thisslice=$slice[0]; $slicecounter=0; $filewithdir=$piedirectory.$piefile; open(PIE, ">$filewithdir") or die("Couldn't create output file: ".$thispiefile); print PIE "%!PS-ADOBE 3.0 EPSF-3.0\n"; print PIE "%%Title: ".$piefile."\n"; print PIE "%%Creator: createpies.pl (c)Ken Owen 1999-2016\n"; print PIE "%%Creationdate: ".$thisdate."\n"; print PIE "%%BoundingBox: $xstart $ystart $xend $yend\n\n"; print PIE "<< /PageSize [1000 1000] >> setpagedevice \n gsave\n"; print PIE "/typesize " . $valuetype . " def\n"; print PIE $ps; print PIE "%%set scale and translation\n"; print PIE "306 396 translate $hsize $vsize scale\n"; $thisstartangle=$startingangle; open(LABELANDCOLOR, "<$labelandcolor") or die("Couldn't open $labelandcolor\n"); $counter=0; while (<LABELANDCOLOR>) { chomp; $lclines[$counter]=$_; $counter++; } $counter=@lclines; $labelx=0; my $labely=$counter*$vsize*9; $counter=0; foreach $lclines(@lclines){ ($label, $c, $m, $y, $k)=split(/\t/,$lclines); print PIE "%%draw pie chart\n"; $thisendangle=$thisstartangle+eval($thisslice); if(eval($thisslice)>0){ $percent1num=int(100*eval($thisslice)/360); if(((100*eval($thisslice)/36) % 10) >= 5){ $percent1num++; } $percent1=substr($percent1num,0)."%"; if($percent1num == 0){$percent1num=1;} $wholepercent+=$percent1num; if($wholepercent == 101){ $percent1num--;  $percent1=substr($percent1num,0) . "%";  } print PIE "$c $m $y $k $thisstartangle $thisendangle ($percent1) pieslice\n"; } $thisstartangle=$thisendangle; $slicecounter++; $thisslice=$slice[$slicecounter]; } my $exportstr="convert $filewithdir -density 1200x1200 $piedirectory$piename.$gexport"; print PIE "\n"; print PIE "showpage\n"; print PIE "grestore\n"; print PIE "%%trailer\n"; print PIE "%%EOF"; if(length($gexport)>0){`$exportstr`;} } close LABELANDCOLOR; close PIE;
}
sub pie4{
my ($startingangle, $ps, $data, $labelandcolor, $hsize, $vsize, $gexport, $legend, $valuetype) = @_; my $piececount=0; my @slice; my $piename; my $slicecnt; my $filecounter; my @pclines; my $c; my $y; my $m; my $k; my $pclines; my $piefile; my $piedirectory; my $thisslice; my $thispiefile; my $leftright; my $lclines; my @lclines; my $slicecounter; my $thisdate; my $filewithdir; my $thisstartangle; my $thisendangle; my $label; my $piefileextension="eps"; my $legend_right; my $boundingxend; my $boundingxstart; my $xstart; my $xend; my $ystart; my $yend; my $labelmax=0; my $labelx; my $percent1num; my $percent1; my $wholepercent; open(LABELANDCOLOR, "<$labelandcolor") or die("Couldn't open $labelandcolor\n"); while(<LABELANDCOLOR>) { $_=~s/\t.*//; $_=~s/ *$//; chomp; $labelx=length($_); if($labelx>$labelmax){$labelmax=$labelx; } $piececount++; } close(LABELANDCOLOR); if($legend eq "right"){ $boundingxend=int(306+($hsize*321/2)+($labelmax*9+30)*$hsize); $boundingxstart=int(306-(30+$hsize*321/2)); $xstart=int(306-($hsize*260/2)); $xend=int(306+($hsize*260/2)); $ystart=int(396-($vsize*308/2)-($vsize*30)); $yend=int(396+($vsize*308/2)+($vsize*30)); }elsif($legend eq "left"){ $boundingxstart=int(306-($hsize*321/2)-($labelmax*9+30)*$hsize); $boundingxend=int(306+(30+$hsize*321/2)*$hsize); $xstart=int(306-($hsize*280/2)); $xend=int(306+($hsize*260/2)); $ystart=int(396-($vsize*308/2)-($vsize*30)); $yend=int(396+($vsize*308/2)+($vsize*30)); }elsif($legend eq "bottom"){ $boundingxstart=int(306-($hsize*315/2)-30); $boundingxend=int(306+($hsize*315/2)+30); $xstart=int(306-($hsize*315/2)); $xend=int(306+($hsize*315/2)); $ystart=int(396-200-($piececount)*($vsize*25)); $yend=int(396+($vsize*180)); }else{ $xstart=int(306-($hsize*315/2)); $xend=int(306+($hsize*315/2)); $ystart=int(396-($vsize*315/2)-30); $yend=int(396+($vsize*350/2)); } open(PIECHARTDATA, "<$data") or die("Couldn't open $data"); my $counter=0; while (<PIECHARTDATA>) { $pclines[$counter]=$_; $counter++; } foreach $pclines(@pclines){ @slice=split(/\t/,$pclines); chomp($slice[2]); $slicecnt=@slice; $piefile=$slice[$slicecnt-1]; chomp($piefile); $piename=$piefile; $piefile.="\.".$piefileextension; $piedirectory="pies/"; $thisdate = scalar localtime; $thisslice=$slice[0]; $slicecounter=0; $filewithdir=$piedirectory.$piefile; open(PIE, ">$filewithdir") or die("Couldn't create output file: ".$thispiefile); print PIE "%!PS-ADOBE 3.0 EPSF-3.0\n"; print PIE "%%Title: ".$piefile."\n"; print PIE "%%Creator: createpies.pl (c)Ken Owen 1999-2016\n"; print PIE "%%Creationdate: ".$thisdate."\n"; if($legend eq "right" || $legend eq "left") { print PIE "%%BoundingBox: $boundingxstart $ystart $boundingxend $yend\n\n"; }elsif($legend eq "bottom") { print PIE "%%BoundingBox: $boundingxstart $ystart $boundingxend $yend\n\n"; }else{ print PIE "%%BoundingBox: $xstart $ystart $xend $yend\n\n"; } print PIE "<< /PageSize [1000 1000] >> setpagedevice \n gsave\n"; print PIE "/typesize " . $valuetype . " def\n"; print PIE $ps; print PIE "%%set scale and translation\n"; print PIE "306 396 translate $hsize $vsize scale\n"; $thisstartangle=$startingangle; open(LABELANDCOLOR, "<$labelandcolor") or die("Couldn't open $labelandcolor\n"); $counter=0; while (<LABELANDCOLOR>) { chomp; $lclines[$counter]=$_; $counter++; } $counter=@lclines; $labelx=0; my $labely=$counter*$vsize*9; $counter=0; foreach $lclines(@lclines){ ($label, $c, $m, $y, $k)=split(/\t/,$lclines); print PIE "%%draw pie chart\n"; $thisendangle=$thisstartangle+eval($thisslice); if(eval($thisslice)>0){ $percent1num=int(100*eval($thisslice)/360); if(((100*eval($thisslice)/36) % 10) >= 5){ $percent1num++; } $percent1=substr($percent1num,0)."%"; if($percent1num == 0){$percent1num=1;} $wholepercent+=$percent1num; if($wholepercent == 101){ $percent1num--;  $percent1=substr($percent1num,0) . "%";  } print PIE "$c $m $y $k $thisstartangle $thisendangle ($percent1) pieslice\n"; if($legend eq "bottom"){ $leftright=0; $labelx=-100; $labely=-220-($slicecounter*$vsize*25); print PIE "$c $m $y $k ($label) $labelx $labely $leftright  $hsize $vsize legend\n"; $thisstartangle=$thisendangle; $thisslice=$slice[$slicecounter]; }elsif($legend eq "right"){ $labelx=(260/2) + 55; $labely=$labely-28; $counter++; print PIE "$c $m $y $k ($label) $labelx $labely $hsize $vsize legend_right\n"; }elsif($legend eq "left"){ $labelx=-((260/2) + 70); $labely=$labely-28; $counter++; print PIE "$c $m $y $k ($label) $labelx $labely $hsize $vsize legend_left\n"; } } $thisstartangle=$thisendangle; $slicecounter++; $thisslice=$slice[$slicecounter]; } my $exportstr="convert $filewithdir -density 1200x1200 $piedirectory$piename.$gexport"; print PIE "\n"; print PIE "showpage\n"; print PIE "grestore\n"; print PIE "%%trailer\n"; print PIE "%%EOF"; if(length($gexport)>0){`$exportstr`;} } close LABELANDCOLOR; close PIE;
}
sub pie5{
my ($startingangle, $ps, $data, $labelandcolor, $hscale, $vscale, $gexport, $valuetype, $explodeoffset, $sections) = @_; my $slicecounter; my $piefile; my $piececount; my $thisdate = scalar localtime; my $piedirectory="pies/"; my @slice; my $slicecnt; my $piefileextension="eps"; my $hsize=$hscale; my $vsize=$vscale; my $yend; my $labelmax=0; my $labelx; open(LABELANDCOLOR, "<$labelandcolor") or die("Couldn't open $labelandcolor\n"); while(<LABELANDCOLOR>) { $_=~s/\t.*//; $_=~s/ *$//; chomp; $labelx=length($_); if($labelx>$labelmax){ $labelmax=$labelx; } $piececount++; } close(LABELANDCOLOR); my $xstart=int(306-($hsize*350/2)-($labelmax*$hsize)-(2*$explodeoffset)); my $xend=int(306+($hsize*350/2)+($labelmax*$hsize)+(2*$explodeoffset)); my $ystart=int(396-($vsize*321/2)-($labelmax*$vsize)); $yend=int(396+($vsize*321/2)+($labelmax*$vsize)); my @lclines; my $lclines; my $label; my $c; my $m; my $y; my $k; my $sectionnum; my $oldsectionnum=0; my $sectionoffset=0; my $thisendangle; my $thisslice; my $thisstartangle; my $filewithdir; my $thispiefile; my $sectionanchor=0; my @anchors; my $anchorcnt=0; my @sectionarray; my $sectionarr; my $sectioncnt=0; my $initialangle=$startingangle; open(PIECHARTDATA, "<$data") || print "Cannot open data for reading\n"; while(<PIECHARTDATA>) { chomp; @slice=split/\t/,$_; @anchors=split/,/,$slice[6]; @sectionarray=split/,/,$sections; $sectionarr=@sectionarray; $sectioncnt=0; $slicecnt=@slice; $piefile=$slice[$slicecnt-2]; $thisslice=$slice[0]; $slicecounter=0; $thispiefile=$piefile . "." . $piefileextension; $filewithdir=$piedirectory.$thispiefile; open(PIE, ">$filewithdir") || print ("Couldn't create output file: ".$thispiefile); print PIE "%!PS-ADOBE 3.0 EPSF-3.0\n"; print PIE "%%Title: ".$thispiefile."\n"; print PIE "%%Creator: createpies.pl (c)Ken Owen 1999-2016\n"; print PIE "%%Creationdate: ".$thisdate."\n"; print PIE "%%BoundingBox: $xstart $ystart $xend $yend\n\n"; print PIE "/typesize " . $valuetype . " def\n"; print PIE $ps; print PIE "c m y k setcmykcolor 2 setlinejoin 0 0 moveto 0 0 radius startangle endangle arc closepath gsave fill grestore "; print PIE "0 0 0 0 setcmykcolor 1.5 setlinewidth stroke "; print PIE "/slicecount slicecount 1 add def} def\n"; print PIE "\n%%set scale and translation\n"; print PIE "306 396 translate $hsize $vsize scale\n"; $thisstartangle=$startingangle; open(LABELANDCOLOR, "<$labelandcolor") or die("Couldn't open $labelandcolor"); my $counter=0; while (<LABELANDCOLOR>) { chomp; $lclines[$counter]=$_; $counter++; } foreach $lclines(@lclines){ ($label, $c, $m, $y, $k, $sectionnum)=split/\t/,$lclines; print PIE "%%draw pie chart\n"; $thisendangle=$thisstartangle+eval($thisslice); if($slicecounter<$sectionarray[$sectioncnt]){ $sectionanchor=$anchors[$sectioncnt]+$initialangle; }else{ $sectioncnt++; $sectionanchor=$anchors[$sectioncnt]+$initialangle; } if(eval($thisslice)>0){ print PIE "$c $m $y $k $thisstartangle $thisendangle ($label) $explodeoffset $sectionanchor pieslice\n"; print PIE "grestore\n"; } $thisstartangle=$thisendangle; $slicecounter++; $thisslice=$slice[$slicecounter]; } $sectionanchor=""; my $exportstr="convert $filewithdir -density 1200x1200 $piedirectory$piefile.$gexport"; print PIE "\n"; print PIE "showpage\n"; print PIE "grestore\n"; print PIE "%%trailer\n"; print PIE "%%EOF"; close LABELANDCOLOR; close PIE; if(length($gexport)>0){`$exportstr`;}}
}
sub pie6{
my ($startingangle,$ps, $data, $labelandcolor, $hscale, $vscale, $gexport, $valuetype) = @_; 
my $slicecounter; my $piefile; my $piececount; my $thisdate = scalar localtime; my $piedirectory="pies/"; my @slice; my $slicecnt; my $piefileextension="eps"; my $hsize=$hscale; my $vsize=$vscale;  my $yend; my $labelmax=0; my $labelx; open(LABELANDCOLOR, "<$labelandcolor") or die("Couldn't open $labelandcolor\n"); while(<LABELANDCOLOR>) {$_=~s/\t.*//; $_=~s/ *$//; chomp; $labelx=length($_)+10; if($labelx>$labelmax){$labelmax=$labelx; } $piececount++;} close(LABELANDCOLOR); my $xstart=int(306-($hsize*350/2)-($labelmax*$hsize)); my $xend=int(306+($hsize*350/2)+($labelmax*$hsize)); my $ystart=int(396-($vsize*350/2)-($labelmax*$vsize)); $yend=int(396+($vsize*350/2)+($labelmax*$vsize)); my @lclines; my $lclines; my $label; my $c; my $m; my $y; my $k; my $thisendangle; my $thisslice; my $thisstartangle; my $filewithdir; my $thispiefile; open(PIECHARTDATA, "<$data") || die "Couldn't open $data\n"; while(<PIECHARTDATA>) {chomp; @slice=split/\t/,$_; $slicecnt=@slice; $piefile=$slice[$slicecnt-1]; $thisslice=$slice[0]; $slicecounter=0; $thispiefile=$piefile.".".$piefileextension; $filewithdir=$piedirectory.$thispiefile; open(PIE, ">$filewithdir") or die("Couldn't create output file: ".$thispiefile); print PIE "%!PS-ADOBE 3.0 EPSF-3.0\n"; print PIE "%%Title: ".$thispiefile."\n"; print PIE "%%Creator: createpies.pl (c)Ken Owen 1999-2016\n"; print PIE "%%Creationdate: ".$thisdate."\n"; print PIE "%%BoundingBox: $xstart $ystart $xend $yend\n\n"; print PIE "/typesize " . $valuetype . " def\n"; print PIE $ps; print PIE "\n%%set scale and translation\n"; print PIE "306 396 translate $hsize $vsize scale\n"; $thisstartangle=$startingangle; open(LABELANDCOLOR, "<$labelandcolor") or die("Couldn't open $labelandcolor"); my $counter=0; while (<LABELANDCOLOR>) { chomp; $lclines[$counter]=$_; $counter++; } foreach $lclines(@lclines){ ($label, $c, $m, $y, $k)=split/\t/,$lclines; print PIE "%%draw pie chart\n"; $thisendangle=$thisstartangle+eval($thisslice); if(eval($thisslice)>0){ print PIE "$c $m $y $k $thisstartangle $thisendangle ($label) pieslice\n"; } $thisstartangle=$thisendangle; $slicecounter++; $thisslice=$slice[$slicecounter]; } my $exportstr="convert $filewithdir -density 1200x1200 $piedirectory$piefile.$gexport"; print PIE "\n"; print PIE "showpage\n"; print PIE "grestore\n"; print PIE "%%trailer\n"; print PIE "%%EOF"; close LABELANDCOLOR; close PIE; if(length($gexport)>0){`$exportstr`;} }
}
sub column1{
my ($ps, $data, $labelandcolor, $hsize, $vsize, $gexport, $columnwidth, $format, $headertype, $axistype, $valuetype, $backgroundcolor, $headercolor) = @_;
my $l1; my $l2; my $number; my $colfileextension="eps"; my $roundto; my $topscale=0; my $coldirectory="columns/"; my $thisdate; my @cols; my $cols; my $number_columns=0; $columnwidth=$columnwidth; my $thiscolfile; my $colname; my $filewithdir; my $xstart; my $xend; my $ystart; my $yend; my $labeldepth=36; my $valuedepth=36; my $chartdepth=217; my $totaldepth; my $chartwidth; my $labelpos; my $i; my $maxval; my $yaxis=72; my $c; my $m; my $y; my $k; my $label; my $cstart; open(COLCHARTDATA, "<$data") or die("Couldn't open $data"); while (<COLCHARTDATA>) { chomp; @cols=split/\t/,$_;  $number_columns=@cols - 1; $labelpos=@cols; $chartwidth=$yaxis + $columnwidth/2 + 1.5*$number_columns*$columnwidth; my $cwidth=$columnwidth*$hsize; $xstart=int(306 - $hsize*$chartwidth/2); $xend=int(306 + $hsize*$chartwidth/2); $totaldepth=($chartdepth+$valuedepth+$labeldepth) * $vsize + 1; $ystart=int(396 - $vsize*$totaldepth/2 - 2); $yend=int(396 + $vsize*$totaldepth/2 + 1); $thisdate = scalar localtime; $colname=$cols[$number_columns]; $thiscolfile=$colname . "." . $colfileextension; $filewithdir=$coldirectory.$thiscolfile; open(COL, ">$filewithdir") || die "Couldn't create output file: " . $thiscolfile . "\n"; print COL "%!PS-ADOBE 3.0 EPSF-3.0\n"; print COL "%%Title: ".$thiscolfile."\n"; print COL "%%Creator: createcolumns.pl (c)Ken Owen 2001 - 2014\n"; print COL "%%Creationdate: ".$thisdate."\n"; print COL "%%BoundingBox: $xstart $ystart $xend $yend\n"; print COL "<< /PageSize [1000 1000] >> setpagedevice \n gsave\n"; print COL "$xstart $ystart translate $hsize $vsize scale\n"; print COL "/cwidth $cwidth def\n" . $ps; print COL "%%background areas\n"; print COL "/bkground {$backgroundcolor setcmykcolor} def\n";print COL "0 $yaxis add 2 sub $chartdepth $valuedepth add $vsize mul $chartwidth $yaxis sub $labeldepth bkgroundbox\n"; print COL "0 $yaxis add 2 sub 0 $chartwidth $yaxis sub $chartdepth $vsize mul bkgroundbox\n"; print COL "/headertype {$headercolor setcmykcolor /Helvetica-Bold findfont $headertype vsize mul scalefont setfont} def\n/axistype {/Helvetica-Bold findfont $axistype vsize mul scalefont setfont} def\n/valuetype {/Helvetica-Bold findfont $valuetype vsize mul scalefont setfont} def\n"; open(LABELANDCOLOR, "<$labelandcolor") or die("Couldn't open $labelandcolor\n"); print COL "%%draw column chart\n"; $maxval=0; for ($i=0; $i<@cols-1;$i++){ if($cols[$i]>$maxval){$maxval=$cols[$i];} } if($maxval<10){ $roundto=1; }elsif($maxval<100){ $roundto=10; }elsif($maxval<1000){ $roundto=100; }elsif($maxval<10000){ $roundto=1000; }elsif($maxval<100000){ $roundto=10000; }else{ $roundto=25000; } if(($maxval%$roundto)==0){ $topscale=$maxval; }else{ $topscale=($roundto-($maxval%$roundto)+$maxval); } print  COL "gsave (".&makedollars(0, $format, 1).") (".&makedollars($topscale/5, $format, 1).") (".&makedollars($topscale*2/5, $format, 1).") (".&makedollars($topscale*3/5, $format, 1).") (".&makedollars($topscale*4/5, $format, 1).") (".&makedollars($topscale, $format, 1).") $chartwidth $yaxis sub $hsize $vsize chartscale grestore\n"; $i=0; while(<LABELANDCOLOR>){ chomp; ($label, $c, $m, $y, $k)=split/\t/,$_; $l1=""; $l2=""; if(length($label)>15){ $l1=$label; $l2=$label; $l1=~s/ \S*$//; $l2=substr($label, length($l1)); }else{ $l2=$label; } $cstart=$yaxis + $columnwidth/2 + $i*1.5*$columnwidth; print COL "$c $m $y $k $i " . 215*$vsize*$cols[$i]/$topscale . " (" . &makedollars($cols[$i], $format, 0) . ") ($l1) ($l2) $cstart $columnwidth column\n"; $i++; } my $exportstr="convert $filewithdir -density 1200x1200 $coldirectory$colname.$gexport"; print COL "showpage\n"; print COL "grestore\n"; print COL "%%trailer\n"; print COL "%%EOF"; if(length($gexport)>0){`$exportstr`; }} close LABELANDCOLOR; close COL; 
}
sub bar1{
my ($ps, $data, $labelandcolor, $hsize, $vsize, $gexport, $columnwidth, $format, $headertype, $axistype, $valuetype, $backgroundcolor, $headercolor, $valuecolor) = @_; my $l1; my $l2; my $number; my $colfileextension="eps"; my $roundto; my $topscale=0; my $coldirectory="bars/"; print "coldirectory=$coldirectory\n"; my $thisdate; my @cols; my $cols; my $number_columns=0; $columnwidth=$columnwidth; my $thiscolfile; my $colname; my $filewithdir; my $xstart; my $xend; my $ystart; my $ystartb; my $yend; my $labeldepth=36; my $valuedepth=36; my $chartdepth; my $totaldepth; my $chartwidth; my $labelpos; my $i; my $maxval; my $yaxis=72; my $c; my $m; my $y; my $k; my $label; my $cstart; my $extrawidth=0; my $barwidth; my $chartscale; open(BARCHARTDATA, "<$data") or die("Couldn't open $data"); while (<BARCHARTDATA>) { chomp; @cols=split/\t/,$_; $number_columns=@cols - 1; $labelpos=@cols; $chartdepth=$columnwidth/2 + 1.5*$number_columns*$columnwidth; $totaldepth=$chartdepth * $vsize + 1; $ystart=int(396 - $vsize*$totaldepth/2); $ystartb=int($ystart - 24); $yend=int(396 + $vsize*$totaldepth/2 + 1); $thisdate = scalar localtime; $colname=$cols[$number_columns]; $thiscolfile=$colname . "." . $colfileextension; $filewithdir=$coldirectory.$thiscolfile; $maxval=0; $extrawidth=0; for ($i=0; $i<@cols-1;$i++){ if($cols[$i]>$maxval){$maxval=$cols[$i];} } if($maxval<10){ $roundto=1; }elsif($maxval<100){ $roundto=10; }elsif($maxval<1000){ $roundto=100; }elsif($maxval<10000){ $roundto=1000; }elsif($maxval<100000){ $roundto=10000; }else{ $roundto=25000; } if(($maxval%$roundto)==0){ $topscale=$maxval; }else{ $topscale=($roundto-($maxval%$roundto)+$maxval); } $extrawidth=35; $chartscale=259/$topscale; $chartwidth=$yaxis + $chartscale * $topscale + $extrawidth; $barwidth=$chartwidth-$yaxis; $xstart=int(306 - $hsize*$chartwidth/2); $xend=int(306 + $hsize*$chartwidth/2 + $extrawidth); open(BAR, ">$filewithdir") || die "Couldn't create output file: " . $thiscolfile . "\n"; print BAR "%!PS-ADOBE 3.0 EPSF-3.0\n"; print BAR "%%Title: ".$thiscolfile."\n"; print BAR "%%Creator: createbars.pl (c)Ken Owen 2014\n"; print BAR "%%Creationdate: ".$thisdate."\n"; print BAR "%%BoundingBox: $xstart $ystartb $xend $yend\n"; print BAR "%%%Debug maxval=$maxval topscale=$topscale extrawidth=$extrawidth chartwidth=$chartwidth chartscale=$chartscale\n"; print BAR "<< /PageSize [1000 1000] >> setpagedevice \n gsave\n"; print BAR "$xstart $ystart translate $hsize $vsize scale\n"; print BAR "/bwidth $columnwidth def\n"; print BAR $ps; print BAR "%%background areas\n"; print BAR "/bkground {$backgroundcolor setcmykcolor} def\n"; print BAR "0 $yaxis add 2 sub 0 $chartwidth $extrawidth add $yaxis sub $chartdepth bkgroundbox\n"; print BAR "/headertype {$headercolor setcmykcolor /Helvetica-Bold findfont $headertype vsize mul scalefont setfont} def\n/axistype {/Helvetica-Bold findfont $axistype vsize mul scalefont setfont} def\n/valuetype {/Helvetica-Bold findfont $valuetype vsize mul scalefont setfont} def\n"; print BAR "/valuecolor {$valuecolor setgray} def\n"; open(LABELANDCOLOR, "<$labelandcolor") or die("Couldn't open $labelandcolor\n"); print BAR "%%draw bar chart\n"; print  BAR "gsave (".&makedollars(0, $format, 1).") (".&makedollars($topscale/5, $format, 1).") (".&makedollars($topscale*2/5, $format, 1).") (".&makedollars($topscale*3/5, $format, 1).") (".&makedollars($topscale*4/5, $format, 1).") (".&makedollars($topscale, $format, 1).") $chartdepth $chartwidth $yaxis sub $hsize $vsize chartscale grestore\n"; $i=0; while(<LABELANDCOLOR>){ chomp; ($label, $c, $m, $y, $k)=split/\t/,$_; $l1=""; $l2=""; if(length($label)>15){ $l1=$label; $l2=$label; $l1=~s/ \S*$//; $l2=substr($label, length($l1)); }else{ $l2=$label; } $cstart=$columnwidth/2 + $i*1.5*$columnwidth; print BAR "$c $m $y $k $i " . $barwidth*$cols[$i]/$topscale . " (" . &makedollars($cols[$i], $format, 0) . ") ($l1) ($l2) $cstart $columnwidth bar\n"; print BAR "% barwidth=$barwidth cstart=$cstart\n"; $i++; } my $exportstr="convert $filewithdir -density 1200x1200 $coldirectory$colname.$gexport"; print BAR "showpage\n"; print BAR "grestore\n"; print BAR "%%trailer\n"; print BAR "%%EOF"; if(length($gexport)>0){`$exportstr`; } } close LABELANDCOLOR; close BAR;
}
sub makedollars{ my $number=shift; my $format=shift; my $scale=shift; my $decimal=0; my $decimal1=0; if($number < 1000000){ if($number<100000){ if($number<10000){ if($number<1000){}else{ $number=substr($number,0,1).",".substr($number,1); }}else{ $number=substr($number,0,2).",".substr($number,2); } }else{ $number=substr($number,0,3).",".substr($number,3); } }else{ $number=substr($number,0,1).",".substr($number,1,3).",".substr($number,4);} if($scale==1){$number=int($number); if($format eq "money"){$number="\$".$number;}}else{if($format eq "money"){$number=int($number);$number="\$".$number;}elsif(substr($format,0,1) eq "d"){$decimal1=substr($format,1,1);$decimal=10**$decimal1; $number=$number*$decimal; $number=int($number);$number=$number/$decimal;$decimal1="%." . $decimal1 . "f";$number=sprintf($decimal1, $number);}else{$number="Illegal Format!";}} return $number; 
}
1;


sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&PSGRAPH::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('PSGRAPH', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

PSGRAPH - Perl extension for batch creation of charts and graphs

=head1 SYNOPSIS

  use PSGRAPH;
  my $psgraph = PSGRAPH->new();

  #for pie charts, setInitialdegree sets the starting point for data. The default is 120.
  $psgraph->setInitialdegree(integer);
  
  #label and color files must be tab delimited with a string for the label and CMYK color numbers
  #example: Salary	.23	.46	.73	0
  #for pie5 (exploded pie) include the string for the label, CMYK number and integer for the exploded section
  #example: Salary	.23	.46	.73	0	1 
  #There must be a line for each data element for each record
  $psgraph->setLabelandColor('your label and color file');

  #data files must be tab delimited populated with the value for each data element
  #pie slice, bar, column, etc)
  #the last element in each row is the identifying index (employee number, SSN or any unique string) No spaces.
  $psgraph->setData('your data file');

  #must be one of the supported graphic types
  #as of May 2014 the supported types are 2Dpie, 2Dcolumn and 2Dbar
  $psgraph->setGraphic('type of graphic');

  #set the subtype (or take the default)
  #Valid subtypes currently are, for 2Dpie:
    #1 pie with callout lines with labels at the end of the lines (default)
    #2 pie with callout lines with percentages and labels at the end of the lines
       The percentages are calculated by the program
    #3 pie with legend
    #31 pie with legend with percentages
    #4 pie with percentages in callouts and legend
	#41 pie with percentages in callouts
    #5 exploded pie
	#6 plain pie
  #Valid subtypes currently are, for 2Dcolumn:
    #1 (default)
  #Valid subtypes currently are, for 2Dbar:
    #1 (default)
  $psgraph->setSubtype(subtype);

  #set the legend position for graphics with legends (or take the default)
  #valid positions are right (default), bottom and left
  $psgraph->setLegendpos('position');

  #set the scale of the graphic
  #all graphics are initially written in Postcript, so they may be scaled to any size without loss of detail.
  #type is not distorted when the graphic is, as in an oval shaped pie
  #the basic size of the graphics are:
    #Pie: 412 points (5.72") To make the plain pie fill the boundingbos, multiply the scales by 1.75
    #Bar: The height is dependent on the number of bars in the data, calculated by:
        #24 + bar height (set by setColumnwidth) * 1.5 + .5 * bar height. The width is 401 points (5.57").
    #Column: The height is 220.75 points (3.07") The width is dependent on the number of columns in the data, calculated by:
		#72 + column width * number of columns * 1.5 + .5 * column width  
  #Horizontal Scale (1 is 100% of the base size):
  $psgraph->setHscale(horizontal scale)
  #Vertical Scale (1 is 100% of the base size):
  $psgraph->setVscale(vertical scale)
  #Set the explode offset in points (default is 12)
  $psgraph->setExplodeoffset(offset in points)  

  #Set the column width for column charts or bar height for bar charts or take the default width of 36 points (1/2 inch)
  $psgraph->setColumnwidth

  #Set the number format for column charts or take the default (money)
  #Valid formats: money (whole dollars starting with a $) or d<number> for the number of decimal places. 
  #d0 is an integer. d3 creates three decimal places
  $psgraph->setFormat

  #Set the type size for the headers (column and bar charts)
  #The type size is not scaled with the graphic so that uneven scaling of horizontal and vertical dimensions 
  #does not skew the type. The headers are in bold type. The default size is 9 point.
  $psgraph->setHeadertype(point size)

  #Set the type color for the headers. Default is black (0 0 0 1) (column and bar charts)
  ##The color is CMKY, entered as 4 numbers between zero and one, space delimited
  $psgraph->setHeadercolor('C M Y K')

  #Set the type size for the axis type (column and bar charts)
  #As with the headers, the type size is not scaled with the graphic
  #The default size is 8 points.
  $psgraph->setAxistype(point size)

  #Set the type size for the value type (column and bar charts) and callouts on pies.
  #As with the headers, the type size is not scaled with the graphic
  #The default size is 9 points for column and bar charts. 8 points for callouts on pies.
  $psgraph->setValuetype(point size)

  #Set the grayscale type color for values in bar charts
  #Usually black (0) for light-colored backgrounds and white (1) for dark-color backgrounds
  $psgraph->setValuecolor(grayscale value)

  #Set the background color (column and bar charts)
  #The color is CMKY, entered as 4 numbers between zero and one, space delimited
  #The default color is .3 0 .15 .09 (a light blue).
  $psgraph->setBackgroundcolor('C M Y K')

  #Export graphic
  #If you have
  #ImageMagick you can also generate any format that ImageMagick supports using its convert program. By default,
  #any export to a bitmap format (jpg, png, etc.) will be generated at 1200 dpi so that the rasterizaion of the
  #fonts is of good quality. To use one of these formats, set Gexport to the extension of that format:
  $psgraph->setGexport(extension) 

  #write the graphic files
  #pies are written to a pies subdirectory, column charts to a column subdirectory and bar charts to a bars subdirectory
  #the subdirectories must be created before running the writeGraphic method
  #the return value is either 1 (for successful completion) or an error.
  #both eps files, and, if Gexport is set, the exported will be in the same directory
  $psgraph->writeGraphic

=head1 DESCRIPTION

PSGRAPH is a module designed for mass creation of data charts for printing or on-line use.

=head2 EXPORT

None by default.



=head1 SEE ALSO


=head1 AUTHOR

Ken Owen, E<lt>kenowen@eowen.comE<gt>

=head1 COPYRIGHT AND LICENSE

For more details, see the full text of the licenses at
http://www.perlfoundation.org/artistic_license_2_0

Copyright (C) 2013-2016 by Ken Owen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

This program is distributed in the hope that it will be
useful, but it is provided “as is” and without any express
or implied warranties. For details, see the full text of
the license in the file LICENSE.

=cut
