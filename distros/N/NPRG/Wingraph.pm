#$Id: Wingraph.pm 1.27 1999/01/24 16:53:33 frolcov Exp frolcov $
package Win32::Wingraph;
use Carp;
use Alias;
use integer;

require Exporter;
require DynaLoader;
$VERSION = '0.3';

@ISA = qw(Exporter DynaLoader);

@EXPORT = qw( GDIC drawtext LineTo MoveTo SetBrush SetFont);


# Preloaded methods go here.
use strict;
use vars qw(%GDI_DEFS $VERSION);
use vars qw($dc $savedc %fonts $oldfont %pens $oldpen %brushes $oldbrush 
                $meta $pagew $pageh $maxx $maxy $metafilename $desc);
# Autoload methods go after __END__, and are processed by the autosplit program.

bootstrap Win32::Wingraph $VERSION;

###########################################################################
sub new{
        my $this = shift;
                my(%params)=@_;
        my $class = ref($this) || $this;
        my $self = {
                        dc=>0,
                        savedc=>undef,
                        fonts=>{},
                        oldfont=>undef,
                        brushes=>{},
                        oldbrush=>undef,
                        fonts=>{},
                        pens=>{},
                        oldpen=>0,
                        meta=>0,
                        pagew=>0,
                        pageh=>0,
                        maxx=>1000,
                        maxy=>1000,
                        metafilename=>'',
                        desc=>'',
                  };
        bless $self, $class;
        $self->init(%params);
        return $self;
}

sub init{
        my $self=attr shift;
        my(%params)=@_;
        if(!defined($params{'device'})){
                croak "Device not defined!";
        }

        if($params{metafile}){
#           $savedc=xsCreateDC('WINSPOOL',$params{'device'}) or croak 'Cannot create device DC!';
           $savedc=CreatePrinterDC(%params);
           $metafilename=$params{'metafile'};
           $metafilename=~s/\.[we]mf//i;
           $desc=$params{'desc'}?$params{'desc'}:'NPRG Report';
           $meta=xsCreateEnhMetaFile(0,$metafilename.".emf",0,0,1000,1000,$desc);
           $dc=$meta;
        }else{
#           $dc=xsCreateDC("WINSPOOL",$params{device});
           $dc=CreatePrinterDC(%params);
           xsStartDoc($dc, $params{desc}?$params{'desc'}:'NPRG Report');
           xsStartPage($dc);
        }
        if($meta){
                $pagew=xsGetDeviceCaps($dc,GDIC('HORZRES'));
                $pageh=xsGetDeviceCaps($dc,GDIC('VERTRES'));
        }else{
                xsClipBSize($dc,$pagew,$pageh);
        }
        xsSetBkMode($dc,GDIC('TRANSPARENT'));
}

sub CreatePrinterDC(%){
 my(%par)=@_;
 my($pname, $papersize, $orient);

 if ( $par{'orientation'}=~/L/i ) {
   $orient=GDIC('DMORIENT_LANDSCAPE');
 }else{
   $orient=GDIC('DMORIENT_PORTRAIT');
 }

 if ( exists( $par{'papersize'} ) ) {
    $papersize=GDIC('DMPAPER_'.$par{'papersize'});
 }else{
    $papersize=GDIC('DMPAPER_A4');
 }
 return xsSetDocumetProperties( $par{'device'}, $orient, $papersize);
}

sub DESTROY{
        my $self=attr shift;
        my $mh;

        if ( $meta ) {
                $mh=xsCloseEnhMetaFile($meta);
                xsDeleteEnhMetaFile($mh);
        }else{
                xsEndPage($dc);
                xsEndDoc($dc);
                xsDeleteDC($dc);
        }


        xsDeleteDC($savedc) if $savedc;
        xsSelectObject($dc,$oldfont);
        xsSelectObject($dc,$oldpen);
        xsSelectObject($dc,$oldbrush);

        for ( keys %fonts ) {
                xsDeleteObject($fonts{$_});
        }

        for ( keys %brushes ){
                xsDeleteObject($brushes{$_});
        }

        for ( keys %pens ){
                xsDeleteObject($pens{$_});
        }

}

###########################################################################
sub xl2p{                                                                       
 my $self=attr shift;                                                                
 my $x=shift; 
 return ($pagew*$x/$maxx);                             
}

sub xp2l{
 my $self=attr shift;                                                                
 my $x=shift;                                                                   
 return ($x*$maxx/$pagew);
}
                                                                                
sub yl2p{                                                                       
 my $self=shift;                                                                
 my $x=shift;                                                                   
 return ($pageh*$x/$maxy);                             
}

sub yp2l{                                                                       
 my $self=shift;                                                                
 my $x=shift;                                                                   
 return ($x*$maxy/$pageh);
}


###########################################################################

sub GDIC {
  if( !exists( $GDI_DEFS{"GDI_".$_[0]} ) ){
     croak "Undefined symbol:".$_[0];
  }
  return $GDI_DEFS{"GDI_".$_[0]};
}
###########################################################################

sub NextPage($){
    my $self = attr shift;
    my $mh;

    if($savedc){
       $mh=xsCloseEnhMetaFile($meta);
       xsDeleteEnhMetaFile($mh);
       $metafilename++;
       $dc=$meta=xsCreateEnhMetaFile($savedc,$metafilename.".emf",0,0,
                                 $self->maxx(),
                                 $self->maxy(),
                                 $desc);
    }else{
       xsEndPage($dc);
       xsStartPage($dc);
    }
    xsSetBkMode($dc,GDIC('TRANSPARENT'));
    return;
}

################################################################################
#                               Exported subs                                  #
################################################################################
sub LineTo($$$){
 my $self=attr shift;
 my($x,$y)=@_;
 
 xsLineTo($dc,$self->xl2p($x),$self->yl2p($y));
}

sub MoveTo($$$){
 my $self=attr shift;
 my($x,$y)=@_;

 xsMoveTo($dc,$self->xl2p($x),$self->yl2p($y));
}

sub SetBrush($$){
    my $self=attr shift;
    my $rgb=shift;
    my $ob;

    if (!defined ( $brushes{$rgb} ) ){
        $brushes{$rgb}=xsCreateSolidBrush( xsRGB($rgb, $rgb, $rgb) );
    }

    $ob=xsSelectObject ($dc, $brushes{$rgb});
    $oldbrush=$ob if !defined $oldbrush;
    return $brushes{$rgb};
}

sub SetPen($$){
    my $self=attr shift;
    my $penw=shift;
    my $op;

    if (!defined ( $pens{$penw} ) ){
        $pens{$penw}=xsCreatePen(GDIC('PS_SOLID'),$penw,xsRGB(0,0,0));
    }

    $op=xsSelectObject ($dc, $pens{$penw});
    $oldpen = $op if !defined $oldpen;

    return $pens{$penw};
}

sub SetFont($$){
    my $self=attr shift;
    my $font=shift;
    $font='' if !defined $font;
    my ( $face, $size, $charset ) = $font =~ /^\s*([^,]+),\s*(\d+)\s*(?:,\s*(\d+))?/;
    my $fontname;
    my ($fh, $opt);

    $charset=204 if !defined $charset;
    $face='Arial' if !defined $face;
    $size='10' if !defined $size;
    $opt='' if !defined $opt;
    
    if ( $face =~ /bold/i ){
         $opt='B';
         $face =~ s/\s*bold\s*//i;
    }

    if ( $face =~ /italic/i ){
         $opt.='I';
         $face =~ s/\s*italic\s*//i;
    }
    $face=~s/^\s*//; $face =~ s/\s*$//;
    $fontname="$face,$size,$charset";

    if ( !defined ( $fonts{$fontname} ) ){
         $fonts{$fontname}=xsCreateFont(PointToSize($dc,$size),0,0,0,
                    ($opt=~/B/i?GDIC('FW_BOLD'):GDIC('FW_REGULAR')),
                    ($opt=~/I/i?1:0),#italic
                    ($opt=~/U/i?1:0),#underline
                    ($opt=~/S/i?1:0),#strikeout
                    $charset,
                    GDIC('OUT_DEFAULT_PRECIS'),
                    GDIC('CLIP_DEFAULT_PRECIS'),
                    GDIC('DEFAULT_QUALITY'),
                    GDIC('DEFAULT_PITCH'),
                    $face);
    }
    $fh=xsSelectObject( $dc, $fonts{$fontname} );
    $oldfont = $fh if !defined $oldfont;
}

sub TextOut($$$$){
    my $self=attr shift;
    my ($x, $y, $s)=@_;
    xsTextOut($dc,$self->xl2p($x),$self->yl2p($y),$s);
}

sub TextSize($$){
    my $self=attr shift;
    my($s)=@_;
    my($w,$h)=xsGetTextExtent($dc,$s);
    return ($self->xp2l($w),$self->yp2l($h));
}

sub FillRect($$$$$){
    my $self=attr shift;
    my($x,$y,$w,$h)=@_;
    xsFillRect($dc,
               $self->xl2p($x),
               $self->yl2p($y),
               $self->xl2p($x+$w),
               $self->yl2p($y+$h),
               xsGetCurrentBrush($dc)
    );
}
sub maxy($){
 my $self=shift;
 return $self->{'maxy'};
}
sub maxx($){
 my $self=shift;
 return $self->{'maxx'};
}

################################################################################
#                            Additional functions                              #
################################################################################
sub Ellipse($$$$$){
    my $self=attr shift;
    my($xt,$yt,$xb,$yb)=@_;

    xsEllipse($dc,$self->xl2p($xt),
                  $self->yl2p($yt),
                  $self->xl2p($xb),
                  $self->yl2p($yb)
             );
}

sub Arc($$$$$$$$$){
    my $self=attr shift;
    my($xt,$yt,$xb,$yb,$x1,$y1,$x2,$y2)=@_;
    xsArc($dc,
          $self->xl2p($xt),
          $self->xl2p($yt),
          $self->xl2p($xb),
          $self->xl2p($yb),
          $self->xl2p($x1),
          $self->xl2p($y1),
          $self->xl2p($x2),
          $self->xl2p($y2)
    );
}

sub SetArcDirection($$){
   my $self=attr shift;
   xsSetArcDirection($dc,shift);
}

sub PolyBezier($@){
    my $self=attr shift;
    my(@args)=@_;
    my($cnt)=1;

    @args=map { $cnt++%2? $self->yl2p($_):$self->xl2p($_) } @args;
    xsPolyBezier($dc,@args);
}


################################################################################
sub BEGIN{
%GDI_DEFS=(
    #SetBkMode
    GDI_TRANSPARENT => 1,
    GDI_OPAQUE      => 2,

    #SetTextAlign
    GDI_TA_NOUPDATECP                =>0,
    GDI_TA_UPDATECP                  =>1,
    GDI_TA_LEFT                      =>0,
    GDI_TA_RIGHT                     =>2,
    GDI_TA_CENTER                    =>6,
    GDI_TA_BOTTOM                    =>8,
    GDI_TA_BASELINE                  =>24,
    GDI_TA_RTLREADING                =>256,
    
    #DevCaps
    GDI_DRIVERVERSION =>0     ,
    GDI_TECHNOLOGY    =>2     ,
    GDI_HORZSIZE      =>4     ,
    GDI_VERTSIZE      =>6     ,
    GDI_HORZRES       =>8     ,
    GDI_VERTRES       =>10    ,
    GDI_BITSPIXEL     =>12    ,
    GDI_PLANES        =>14    ,
    GDI_NUMBRUSHES    =>16    ,
    GDI_NUMPENS       =>18    ,
    GDI_NUMMARKERS    =>20    ,
    GDI_NUMFONTS      =>22    ,
    GDI_NUMCOLORS     =>24    ,
    GDI_PDEVICESIZE   =>26    ,
    GDI_CURVECAPS     =>28    ,
    GDI_LINECAPS      =>30    ,
    GDI_POLYGONALCAPS =>32    ,
    GDI_TEXTCAPS      =>34    ,
    GDI_CLIPCAPS      =>36    ,
    GDI_RASTERCAPS    =>38    ,
    GDI_ASPECTX       =>40    ,
    GDI_ASPECTY       =>42    ,
    GDI_ASPECTXY      =>44    ,
    GDI_LOGPIXELSX    =>88    ,
    GDI_LOGPIXELSY    =>90    ,
    GDI_SIZEPALETTE  =>104    ,
    GDI_NUMRESERVED  =>106    ,
    GDI_COLORRES     =>108    ,
    # Printing related DeviceCaps. These replace the appropriate Escapes
    ,
    GDI_PHYSICALWIDTH   =>110 ,
    GDI_PHYSICALHEIGHT  =>111 ,
    GDI_PHYSICALOFFSETX =>112 ,
    GDI_PHYSICALOFFSETY =>113 ,
    GDI_SCALINGFACTORX  =>114 ,
    GDI_SCALINGFACTORY  =>115 ,

    # current objects
    GDI_OBJ_PEN             =>1,
    GDI_OBJ_BRUSH           =>2,
    GDI_OBJ_DC              =>3,
    GDI_OBJ_METADC          =>4,
    GDI_OBJ_PAL             =>5,
    GDI_OBJ_FONT            =>6,
    GDI_OBJ_BITMAP          =>7,
    GDI_OBJ_REGION          =>8,
    GDI_OBJ_METAFILE        =>9,
    GDI_OBJ_MEMDC           =>10,
    GDI_OBJ_EXTPEN          =>11,
    GDI_OBJ_ENHMETADC       =>12,
    GDI_OBJ_ENHMETAFILE     =>13,

  #DrawText flags
    GDI_DT_TOP              =>0x00000000,
    GDI_DT_LEFT             =>0x00000000,
    GDI_DT_CENTER           =>0x00000001,
    GDI_DT_RIGHT            =>0x00000002,
    GDI_DT_VCENTER          =>0x00000004,
    GDI_DT_BOTTOM           =>0x00000008,
    GDI_DT_WORDBREAK        =>0x00000010,
    GDI_DT_SINGLELINE       =>0x00000020,
    GDI_DT_EXPANDTABS       =>0x00000040,
    GDI_DT_TABSTOP          =>0x00000080,
    GDI_DT_NOCLIP           =>0x00000100,
    GDI_DT_EXTERNALLEADING  =>0x00000200,
    GDI_DT_CALCRECT         =>0x00000400,
    GDI_DT_NOPREFIX         =>0x00000800,
    GDI_DT_INTERNAL         =>0x00001000,
    GDI_DT_EDITCONTROL      =>0x00002000,
    GDI_DT_PATH_ELLIPSIS    =>0x00004000,
    GDI_DT_END_ELLIPSIS     =>0x00008000,
    GDI_DT_MODIFYSTRING     =>0x00010000,
    GDI_DT_RTLREADING       =>0x00020000,
    GDI_DT_WORD_ELLIPSIS    =>0x00040000,
  #Pen styles
    GDI_PS_SOLID            =>0,
    GDI_PS_DASH             =>1,#       /* -------  */,
    GDI_PS_DOT              =>2,#       /* .......  */,
    GDI_PS_DASHDOT          =>3,#       /* _._._._ */,
    GDI_PS_DASHDOTDOT       =>4,#       /* _.._.._ */,
    GDI_PS_NULL             =>5,
    GDI_PS_INSIDEFRAME      =>6,

  #brush styles
    GDI_HS_HORIZONTAL       =>0,#       /* ----- */
    GDI_HS_VERTICAL         =>1,#       /* ||||| */
    GDI_HS_FDIAGONAL        =>2,#       /* \\\\\ */
    GDI_HS_BDIAGONAL        =>3,#       /* ///// */
    GDI_HS_CROSS            =>4,#       /* +++++ */
    GDI_HS_DIAGCROSS        =>5,#       /* xxxxx */
  # paper sizes
    GDI_DMPAPER_LETTER               =>1 , #* Letter 8 =>1 , #2 x 11 in               */
    GDI_DMPAPER_LETTERSMALL          =>2 , #* Letter Small 8 =>1 , #2 x 11 in         */
    GDI_DMPAPER_TABLOID              =>3 , #* Tabloid 11 x 17 in                 */
    GDI_DMPAPER_LEDGER               =>4 , #* Ledger 17 x 11 in                  */
    GDI_DMPAPER_LEGAL                =>5 , #* Legal 8 =>1 , #2 x 14 in                */
    GDI_DMPAPER_STATEMENT            =>6 , #* Statement 5 =>1 , #2 x 8 =>1 , #2 in         */
    GDI_DMPAPER_EXECUTIVE            =>7 , #* Executive 7 =>1 , #4 x 10 =>1 , #2 in        */
    GDI_DMPAPER_A3                   =>8 , #* A3 297 x 420 mm                    */
    GDI_DMPAPER_A4                   =>9 , #* A4 210 x 297 mm                    */
    GDI_DMPAPER_A4SMALL             =>10 , #* A4 Small 210 x 297 mm              */
    GDI_DMPAPER_A5                  =>11 , #* A5 148 x 210 mm                    */
    GDI_DMPAPER_B4                  =>12 , #* B4 (JIS) 250 x 354                 */
    GDI_DMPAPER_B5                  =>13 , #* B5 (JIS) 182 x 257 mm              */
    GDI_DMPAPER_FOLIO               =>14 , #* Folio 8 =>1 , #2 x 13 in                */
    GDI_DMPAPER_QUARTO              =>15 , #* Quarto 215 x 275 mm                */
    GDI_DMPAPER_10X14               =>16 , #* 10x14 in                           */
    GDI_DMPAPER_11X17               =>17 , #* 11x17 in                           */
    GDI_DMPAPER_NOTE                =>18 , #* Note 8 =>1 , #2 x 11 in                 */
    GDI_DMPAPER_ENV_9               =>19 , #* Envelope #9 3 =>7 , #8 x 8 =>7 , #8          */
    GDI_DMPAPER_ENV_10              =>20 , #* Envelope #10 4 =>1 , #8 x 9 =>1 , #2         */
    GDI_DMPAPER_ENV_11              =>21 , #* Envelope #11 4 =>1 , #2 x 10 =>3 , #8        */
    GDI_DMPAPER_ENV_12              =>22 , #* Envelope #12 4 \276 x 11           */
    GDI_DMPAPER_ENV_14              =>23 , #* Envelope #14 5 x 11 =>1 , #2            */
    GDI_DMPAPER_CSHEET              =>24 , #* C size sheet                       */
    GDI_DMPAPER_DSHEET              =>25 , #* D size sheet                       */
    GDI_DMPAPER_ESHEET              =>26 , #* E size sheet                       */
    GDI_DMPAPER_ENV_DL              =>27 , #* Envelope DL 110 x 220mm            */
    GDI_DMPAPER_ENV_C5              =>28 , #* Envelope C5 162 x 229 mm           */
    GDI_DMPAPER_ENV_C3              =>29 , #* Envelope C3  324 x 458 mm          */
    GDI_DMPAPER_ENV_C4              =>30 , #* Envelope C4  229 x 324 mm          */
    GDI_DMPAPER_ENV_C6              =>31 , #* Envelope C6  114 x 162 mm          */
    GDI_DMPAPER_ENV_C65             =>32 , #* Envelope C65 114 x 229 mm          */
    GDI_DMPAPER_ENV_B4              =>33 , #* Envelope B4  250 x 353 mm          */
    GDI_DMPAPER_ENV_B5              =>34 , #* Envelope B5  176 x 250 mm          */
    GDI_DMPAPER_ENV_B6              =>35 , #* Envelope B6  176 x 125 mm          */
    GDI_DMPAPER_ENV_ITALY           =>36 , #* Envelope 110 x 230 mm              */
    GDI_DMPAPER_ENV_MONARCH         =>37 , #* Envelope Monarch 3.875 x 7.5 in    */
    GDI_DMPAPER_ENV_PERSONAL        =>38 , #* 6 =>3 , #4 Envelope 3 =>5 , #8 x 6 =>1 , #2 in    */
    GDI_DMPAPER_FANFOLD_US          =>39 , #* US Std Fanfold 14 =>7 , #8 x 11 in      */
    GDI_DMPAPER_FANFOLD_STD_GERMAN  =>40 , #* German Std Fanfold 8 =>1 , #2 x 12 in   */
    GDI_DMPAPER_FANFOLD_LGL_GERMAN  =>41 , #* German Legal Fanfold 8 =>1 , #2 x 13 in */
    GDI_DMPAPER_ISO_B4              =>42 , #* B4 (ISO) 250 x 353 mm              */
    GDI_DMPAPER_JAPANESE_POSTCARD   =>43 , #* Japanese Postcard 100 x 148 mm     */
    GDI_DMPAPER_9X11                =>44 , #* 9 x 11 in                          */
    GDI_DMPAPER_10X11               =>45 , #* 10 x 11 in                         */
    GDI_DMPAPER_15X11               =>46 , #* 15 x 11 in                         */
    GDI_DMPAPER_ENV_INVITE          =>47 , #* Envelope Invite 220 x 220 mm       */
    GDI_DMPAPER_RESERVED_48         =>48 , #* RESERVED--DO NOT USE               */
    GDI_DMPAPER_RESERVED_49         =>49 , #* RESERVED--DO NOT USE               */
    GDI_DMPAPER_LETTER_EXTRA        =>50 , #* Letter Extra 9 \275 x 12 in        */
    GDI_DMPAPER_LEGAL_EXTRA         =>51 , #* Legal Extra 9 \275 x 15 in         */
    GDI_DMPAPER_TABLOID_EXTRA       =>52 , #* Tabloid Extra 11.69 x 18 in        */
    GDI_DMPAPER_A4_EXTRA            =>53 , #* A4 Extra 9.27 x 12.69 in           */
    GDI_DMPAPER_LETTER_TRANSVERSE   =>54 , #* Letter Transverse 8 \275 x 11 in   */
    GDI_DMPAPER_A4_TRANSVERSE       =>55 , #* A4 Transverse 210 x 297 mm         */
    GDI_DMPAPER_LETTER_EXTRA_TRANSVERSE =>56 , #* Letter Extra Transverse 9\275 x 12 in */
    GDI_DMPAPER_A_PLUS              =>57 , #* SuperA/SuperA/A4 227 x 356 mm      */
    GDI_DMPAPER_B_PLUS              =>58 , #* SuperB/SuperB/A3 305 x 487 mm      */
    GDI_DMPAPER_LETTER_PLUS         =>59 , #* Letter Plus 8.5 x 12.69 in         */
    GDI_DMPAPER_A4_PLUS             =>60 , #* A4 Plus 210 x 330 mm               */
    GDI_DMPAPER_A5_TRANSVERSE       =>61 , #* A5 Transverse 148 x 210 mm         */
    GDI_DMPAPER_B5_TRANSVERSE       =>62 , #* B5 (JIS) Transverse 182 x 257 mm   */
    GDI_DMPAPER_A3_EXTRA            =>63 , #* A3 Extra 322 x 445 mm              */
    GDI_DMPAPER_A5_EXTRA            =>64 , #* A5 Extra 174 x 235 mm              */
    GDI_DMPAPER_B5_EXTRA            =>65 , #* B5 (ISO) Extra 201 x 276 mm        */
    GDI_DMPAPER_A2                  =>66 , #* A2 420 x 594 mm                    */
    GDI_DMPAPER_A3_TRANSVERSE       =>67 , #* A3 Transverse 297 x 420 mm         */
    GDI_DMPAPER_A3_EXTRA_TRANSVERSE =>68 , #* A3 Extra Transverse 322 x 445 mm   */

    #Paper orientation
    GDI_DMORIENT_PORTRAIT           =>1,
    GDI_DMORIENT_LANDSCAPE          =>2,


    #Fonts constants here
    GDI_OUT_DEFAULT_PRECIS     =>0,
    GDI_OUT_STRING_PRECIS      =>1,
    GDI_OUT_CHARACTER_PRECIS   =>2,
    GDI_OUT_STROKE_PRECIS      =>3,
    GDI_OUT_TT_PRECIS          =>4,
    GDI_OUT_DEVICE_PRECIS      =>5,
    GDI_OUT_RASTER_PRECIS      =>6,
    GDI_OUT_TT_ONLY_PRECIS     =>7,
    GDI_OUT_OUTLINE_PRECIS     =>8,
    
    GDI_CLIP_DEFAULT_PRECIS    =>0,
    GDI_CLIP_CHARACTER_PRECIS  =>1,
    GDI_CLIP_STROKE_PRECIS     =>2,
    GDI_CLIP_MASK              =>0xf,
    GDI_CLIP_LH_ANGLES          =>(1<<4),
    GDI_CLIP_TT_ALWAYS          =>(2<<4),
    GDI_CLIP_EMBEDDED           =>(8<<4),
    
    GDI_DEFAULT_QUALITY        =>0,
    GDI_DRAFT_QUALITY          =>1,
    GDI_PROOF_QUALITY          =>2,
    
    GDI_NONANTIALIASED_QUALITY =>3,
    GDI_ANTIALIASED_QUALITY    =>4,
    
    
    GDI_DEFAULT_PITCH          =>0,
    GDI_FIXED_PITCH            =>1,
    GDI_VARIABLE_PITCH         =>2,
    
    GDI_MONO_FONT              =>8,
    
    
    GDI_ANSI_CHARSET           =>0,
    GDI_DEFAULT_CHARSET        =>1,
    GDI_SYMBOL_CHARSET         =>2,
    GDI_SHIFTJIS_CHARSET       =>128,
    GDI_HANGEUL_CHARSET        =>129,
    GDI_GB2312_CHARSET         =>134,
    GDI_CHINESEBIG5_CHARSET    =>136,
    GDI_OEM_CHARSET            =>255,
    
    GDI_JOHAB_CHARSET          =>130,
    GDI_HEBREW_CHARSET         =>177,
    GDI_ARABIC_CHARSET         =>178,
    GDI_GREEK_CHARSET          =>161,
    GDI_TURKISH_CHARSET        =>162,
    GDI_VIETNAMESE_CHARSET     =>163,
    GDI_THAI_CHARSET           =>222,
    GDI_EASTEUROPE_CHARSET     =>238,
    GDI_RUSSIAN_CHARSET        =>204,
    
    GDI_MAC_CHARSET            =>77,
    GDI_BALTIC_CHARSET         =>186,
    
    GDI_FS_LATIN1              =>0x00000001,
    GDI_FS_LATIN2              =>0x00000002,
    GDI_FS_CYRILLIC            =>0x00000004,
    GDI_FS_GREEK               =>0x00000008,
    GDI_FS_TURKISH             =>0x00000010,
    GDI_FS_HEBREW              =>0x00000020,
    GDI_FS_ARABIC              =>0x00000040,
    GDI_FS_BALTIC              =>0x00000080,
    GDI_FS_VIETNAMESE          =>0x00000100,
    GDI_FS_THAI                =>0x00010000,
    GDI_FS_JISJAPAN            =>0x00020000,
    GDI_FS_CHINESESIMP         =>0x00040000,
    GDI_FS_WANSUNG             =>0x00080000,
    GDI_FS_CHINESETRAD         =>0x00100000,
    GDI_FS_JOHAB               =>0x00200000,
    GDI_FS_SYMBOL              =>0x80000000,
    
    
    # Font Families =>*/,
    GDI_FF_DONTCARE         =>(0<<4),  # Don't care or don't know. =>*/,
    GDI_FF_ROMAN            =>(1<<4),  # Variable stroke width, serifed. =>*/,
    # Times Roman, Century Schoolbook, etc. =>*/,
    GDI_FF_SWISS            =>(2<<4),  # Variable stroke width, sans-serifed. =>*/,
    # Helvetica, Swiss, etc. =>*/,
    GDI_FF_MODERN           =>(3<<4),  # Constant stroke width, serifed or sans-serifed. =>*/,
    # Pica, Elite, Courier, etc. =>*/,
    GDI_FF_SCRIPT           =>(4<<4),  # Cursive, etc. =>*/,
    GDI_FF_DECORATIVE       =>(5<<4),  # Old English, etc. =>*/,
    
    # Font Weights =>*/,
    GDI_FW_DONTCARE        =>0,
    GDI_FW_THIN            =>100,
    GDI_FW_EXTRALIGHT      =>200,
    GDI_FW_LIGHT           =>300,
    GDI_FW_NORMAL          =>400,
    GDI_FW_MEDIUM          =>500,
    GDI_FW_SEMIBOLD        =>600,
    GDI_FW_BOLD            =>700,
    GDI_FW_EXTRABOLD       =>800,
    GDI_FW_HEAVY           =>900,
    
    GDI_FW_ULTRALIGHT       =>200,
    GDI_FW_REGULAR          =>400,
    GDI_FW_DEMIBOLD         =>600,
    GDI_FW_ULTRABOLD        =>800,
    GDI_FW_BLACK            =>900,


);
}
1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Wingrpah - manipulating of Win32 GDI

=head1 SYNOPSYS

 use Wingraph;
 $dc=new Wingraph(device=>'PS', desc=>'Desc' [, metafile=>'metafilename');

=head2 DESCRIPTION

This module allows you manipulate some subset of Win32 GDI. This subset
includes a some drawing functions and device context related functions.

=over 4

=item
C<new(%params)>

 Create a new Wingrpah object. Parameters are pass as hash and have following
meaning:

=over4

=item C<device>

A name of printer to output or a name of referencing device if we
creating metafile

=item C<desc>

a description of print job or comment in metafile

=item C<metafile>

if this parameters exists, then output do not really printed.
In fact, metafiles with names $param{metafile} will be created, one for each
page. First page will have name $param{metafile}, second - $param{metafile}++
and so on. All functions work with virtual coordinates, from 0 to 1000,
center of coordinates placed in top left corner of drawing area, directed
from left to right and from top to bottom.

=back

=item
C<LineTo($x, $y)>

Set up a virtual pen to position C<($x, $y)>.

=item C<MoveTo($x, $y)>

Draw a line from previous position of virual pen to C<($x, $y)> with current pen.
Also change a current point of pen to C<($x, $y)>.

=item C<SetBrush($int)>

Set current brush to gray brush with intencity C<$int>. 
Intencity may be from 0 (darknest) to 255 (lightest).

=item C<SetPen($w)>

Set current pen width to $w. Width of pen measured in pixels.

=item C<SetFont($fontname)>

Set current font to C<$fontname>. C<$fontname> have the following format:
C<"S<I<font name>, I<size in points>, I<charset>>">. C<I<$charset>> may be
omitted, in this case assumes charset 204.

=item TextOut($x,$y,$s)

Draw using current fonr string C<$s> at position C<$x,$y>.

=item TextSize($s)

Return size of string C<$s> using current font. Height and width return 
as array, first element is width, second - height.

=item FillRect($x,$y,$w,$h)

Draw rectagle with top left cornet at C<($x,$y)> and width equal to C<$w> and
height equal to C<$h>, fill with current brush.

=item NextPage()

Break current page and start new. If output directed to printer then pages
are actually changed, if output directed to metafile, current file closed,
C<$param{$metafile}> incremented and new file created.

=back
