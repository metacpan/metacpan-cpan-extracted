#$Id: NPRG.pm 1.1 2000/10/16 10:27:58 Frolcov Exp Frolcov $
package NPRG;
require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(drawmatrix);
$VERSION = '0.3';

use strict;
use Carp;
use Alias;
use vars qw($dc $ypos @outq $atbreak $newpage $dofooter $footerh $pagenum $onlyhead);

##############################################################################
sub max(@){
 my $val=shift;

 for(@_){
   $val=$val>$_?$val:$_;
 }
 return $val;

}

sub sum(@){
 my $val;

 for(@_){
   $val+=$_;
 }
 return $val;

}

##############################################################################
sub new{
        my $this = shift;
        my(%params)=@_;
        my $class = ref($this) || $this;
        my $self = {
                        dc=>$params{'dc'},
                        ypos=>0,
                        outq=>[],
                        newpage=>1,
                        footerh=>exists($params{'footerh'})?$params{'footerh'}:0,
                        pagenum=>1,
                        dofooter=>0,
                        onlyhead=>0,
                  };
        bless $self, $class;
}
##############################################################################
sub DESTROY{
    my $self=attr shift;

    $self->flushq();
}

##############################################################################
sub pagenum($){
    my $self=attr shift;
    return $pagenum;
}

##############################################################################
sub pushq(@){
    my $self=attr shift;

    my $height= max map { if( ref $_->{'value'} ){
                              &{$_->{'value'}} ($dc, %$_, compute=>1);
                          }else{
                               drawstr ($dc, %$_, compute=>1);
                          }
                        } @_;
    push @outq, { height=>$height, data=>[@_] };
    $onlyhead=0;
}

##############################################################################
sub flushq(){
    my $self= attr shift;
    my ($xpos, $row, $col, @tmpq);

    return if $onlyhead;
    my $height=sum map { $_->{'height'} } @outq;

    $xpos=0;

    if ($height > $dc->maxy() - $ypos - $footerh){
        if(ref($self->{'beforebreak'}) eq 'CODE' and !$dofooter){
           $dofooter=1;
           @tmpq=@outq;
           @outq=();
           if($footerh){
             $ypos=$dc->maxy() - $footerh;
           }
           &{$self->{'beforebreak'}}($self);
           @outq=(@outq);
           $dofooter=0;
        }
        $dc->NextPage();
        $newpage=1;
        $ypos=0;
        $pagenum++;
    }

    if(ref($self->{'atbreak'}) eq 'CODE' and $newpage){
       $newpage=0;
       @tmpq=@outq;
       @outq=();
       &{$self->{'atbreak'}}($self);
       @outq=(@outq, @tmpq);
       $onlyhead=1 if $#tmpq<=0;
       return;
    }


    $newpage=0;

    while( $row = shift @outq){
    $xpos=0;
       for $col ( @{$row->{'data'}} ) {
           if( ref $col->{'value'} ){
                   &{$col->{'value'}} ($dc, %$col, compute=>0, xpos=>$xpos, ypos=>$ypos, height=>$row->{'height'});
           }else{
                   drawstr ($dc, %$col, compute=>0, xpos=>$xpos, ypos=>$ypos, height=>$row->{'height'});
           }
           $xpos+=$col->{'width'};
       }
       $ypos+=$row->{'height'};
    }
}

##############################################################################
sub SplitStr($$$){
  my($dc,$str,$w)=@_;
  my($s, $tval, @retval);

  $s=''; @retval=();
  for(split / +/, $str){
     $tval=($s ne '' ? " $_":$_);
     if(($dc->TextSize($s.$tval))[0]>$w){
        push @retval, $s;
        $s=$_;
     }else{
       $s.=$tval;
     }
  }
  push @retval, $s;
  return @retval;
}

#############################################################################
sub drawstr($%){
    my($dc,%param)=@_;
    my(@str);
    my($x,$y,$w,$h, $font, $opt, $border, $pen);
    my($cx,$cy, $rh, $tmp);


    $x=$param{'xpos'}; $y=$param{'ypos'}; $w=$param{'width'}; $h=$param{'height'};
    $opt=$param{'opt'}; $border=$param{'border'}; $pen=$param{'pen'};


    $font=$param{'font'};
    $dc->SetFont($font);
    my($xdrift,$ydrift)=$dc->TextSize('M');
    $cy=$ydrift;
    ($xdrift,$ydrift)=($xdrift/2, $ydrift/8);

    if($param{'compute'} and (2*$xdrift>=$w or !defined $param{'value'} or $param{'value'} eq '')){
        return $param{'height'};
     };

    if((2*$xdrift>=$w or !defined $param{'value'} or $param{'value'} eq '')  and !defined $param{'brush'}){ return 0;};

    @str=SplitStr($dc,$param{'value'}, $w-2*$xdrift);

    $rh=($#str+1) * $cy + 2 * $ydrift;
    return $rh  if $param{'compute'};

    $h = $h > $rh ? $h : $rh if defined $param{'value'};

    if (defined $param{'brush'}){
          $dc->SetBrush($param{'brush'});
          $dc->FillRect($x,$y,$w,$h);
          if ( !defined ($param{'value'}) or $param{'value'} eq ''){
             return $param{'height'};
          }
    }

    if ( defined $pen ){
          $dc->SetPen($pen);
    }else{
          $dc->SetPen(1);
    }

    if( $border =~ /T/i){
        $dc->MoveTo($x,$y);
        $dc->LineTo($x+$w,$y);
    }
    if( $border =~ /B/i){
        $dc->MoveTo($x, $y+$h);
        $dc->LineTo($x+$w,$y+$h);
    }
    if( $border =~ /L/i){
        $dc->MoveTo($x, $y);
        $dc->LineTo($x, $y+$h);
    }
    if( $border =~ /R/i){
        $dc->MoveTo($x+$w,$y);
        $dc->LineTo($x+$w,$y+$h);
    }

    $x+=$xdrift;$h-=$ydrift/2;
    $tmp=0;
    if ($h > $rh ){
       if ( $opt =~ /-/ ) {
            $y+=($h-$rh)/2
       }elsif( $opt =~ /V/i ){
            $y+=($h-$rh);
       }
    }
    for(@str){
        if($opt =~ /C/i){
          $tmp=($dc->TextSize($_))[0];
          $dc->TextOut( $x +( $w - $tmp - 2 * $xdrift ) / 2, $y, $_ );
        }elsif( $opt =~ /R/i){
          $tmp=($dc->TextSize($_))[0];
          $dc->TextOut( $x + ( $w - $tmp - 2 * $xdrift ), $y, $_ );
        }elsif( $opt =~ /J/i and $tmp ne $#str){
          djstr( $dc, $_, $w - 2 * $xdrift, $x, $y );
        }else{
          $dc->TextOut($x,$y,$_);
        }
        $y+=$cy;
        $tmp++;
    };
    return $rh;
}

##############################################################################
sub djstr($$$$$){
  my($dc,$s,$w,$xpos,$ypos)=@_;

  my(@words)=split / +/,$s;
  return if $#words<=0;
  my($cx,$cy,$drift,$cnt);

  ($cx,$cy)=$dc->TextSize($s);
  $drift=($w-$cx)/$#words;
  $cx=$cy=0;
  for(@words){
    $dc->TextOut($xpos,$ypos,$_);
    ($cx,$cy)=$dc->TextSize("$_ ");
    $xpos+=$cx+$drift;
  }
}

###########################################################################
sub drawmatrix{
 my ($dc, %params)=@_;
 my ($val)=$params{'matrix'};

#$val имеет вид
#[
#  [{},{},{}...{}]
#  [{},{},{}...{}]
#  ....
#  [{},{},{}...{}]
#]
 my($x,$y,$w,$h)=@_;

 my($height,$row,$col, $th, $maxh, $xpos, $ypos, $width, @hs, $koeff, $tx, $ty);

  $height=0;
  for $row (@$val){
         $maxh= max map {drawstr($dc,%$_,
                                width=>($_->{width} ? $_->{width} : $params{'width'}/($#$row+1)),compute=>1)} @$row;
         push @hs, $maxh;
         $height+= $maxh;
   }#for row

   return $height if $params{'compute'};
   
   $xpos   = $params{'xpos'};
   $ypos   = $params{'ypos'};
   $width  = $params{'width'};

   $koeff=$params{'height'}/$height;
   $height = $params{'height'};

   for $row (@$val){
       $maxh=$koeff*$hs[0];
       $tx=$xpos;
       for $col (@$row) {
           drawstr($dc,  %$col,
                         width=> ($col->{width} ? $col->{width} : $width/ ($#$row+1)),
                         compute=>0, height=>$maxh, xpos=>$tx, ypos=>$ypos );
           $tx+=($col->{width} ? $col->{width} : $width / ($#$row+1));
       }#for col
       $ypos+=$maxh; shift @hs;
   }#for row

}#sub drawmatrix


1;
__END__
# Below is the stub of documentation for your module. You better edit it!
=head1 NAME

NPRG - generate reports to graphic output devices

=head1 SYNOPSYS

 use Wingraph;
 use NPRG;

 $dc=new Wingraph(device=>'PS', desc=>'Desc' [, metafile=>'metafilename');
 $rp=new NPRG(dc=>$dc);

 $rp->{'atbreak'}=sub {...}
 $rp->{'beforebeak'}=sub {...}
 $rp->pushq({...},{...}...{...});
 $rp->flushq();

=head2 DESCRIPTION

This module allow you generate reports to graphic outpus deviceses using
objects like Wingraph. The C<$dc> object must have methods, described
in L<Wingraph> documentation.

NPRG methods

=over 4

=item C<new>

Create new NPRG object. Parameter passed by hash, allowed: C<dc> and C<footerh>.
The C<dc> is object like Wingrpah. Description of C<footerh> see below.

=item $rp->{'atbreak'}

Allows you set up callback to proceed page breaking, B<after> page eject. To
function passed only one parameter - the report object itself.

=item $rp->{'beforebreak'}

Like C<'atbreak'>, but only before page eject. You can reserve page
space for footer by creating report object with C<footerh> parameter - the
C<footerh> virtual points will be reserved and every page for footer.

=item $rp->pushq({}...{})>, $rp->flushq()

The C<pushq> functions is core of NPRG. At every call of C<pushq> the
report data pushed into report queue, and at every call of C<flushq()>
data flushed. If no enough space in page then page ejected, calling the
NextPage method of C<$dc> object. Data, pushed together between flushq
calls cannot be splitted between pages. Data passed as array of references
to hashes, where every hash described a column, and this columns will
be equal high and placed from the left to the right in order when they
appear in C<pushq> call. For example, call

=begin text

$rp->pushq( {width=>100, value=>'1.Lala'},
            {width=>200, value=>'1.Dodo'}
     );
$rp->pushq( {width=>100, value=>'2.Lala'},
            {width=>200, value=>'2.Dodo'}
     );
$rp->flushq();

=end text

=begin html
<PRE>
$rp->pushq( {width=>100, value=>'1.Lala'},
            {width=>200, value=>'1.Dodo'}
     );
$rp->pushq( {width=>100, value=>'2.Lala'},
            {width=>200, value=>'2.Dodo'}
     );
$rp->flushq();
</PRE>

=end html

give the something like

=begin text
1.Lala      1.Dodo
2.Lala      2.Dodo

=end text

=begin html
<PRE>
1.Lala      1.Dodo
2.Lala      2.Dodo
</PRE>

=end html

and so on. You can use following hash pairs in column hashes:

begin text

=over 4

=item font

I<optional>. Specifies font for data in format, understanding by C<$dc> object,
<code>'Courier, 12, 0'</code> for example.

=item width

I<required>. Width of column in vitrual points.

=item value

I<optional>. Value to display. If C<value> is scalar then corresponding string 
is displayed. If C<value> is reference to sub, then this sub will be called.
In addition to decribed here params new params C<$dc>, C<xpos>, C<ypos>, C<'height'>,
C<width>, C<compute> will be passed. C<xpos>, C<ypos> defines the coordinates
of top left corner of bounding rectangle, C<width> and C<height> defines
width and height. If parameter C<compute> is defined then sub must return
minimal requred height of rectangle, if not - display the data. See C<drawmatrix>
sub for detail and as example.

=item border

I<optional>. Define a border around displayed data. Must be string with
C<T>, C<B>, C<L>, C<R> chars for border on top, bottom, left and right
side of bounding rectangle. Default is empty string.

=item pen

I<optional>. Define width of pen of border. Default =1.

=item brush

I<optional>. Define the brush to fill background. If not defined then background
is not filled.

=item opt

I<optional>. Define the style used to display data. Must be string of chars.
Horizontal alignment:

=over 4

=item C

Text is centered

=item L

Text is left-ajusted

=item R

Text is right-ajusted

=item J

Text is justified

=back

Vertical alignment:

=over 4

=item -

Text is vertical cenetered

=item V

Text is bottom alignment

=item empty

Text is top alignment

=back

=item height

Minimail height of displayed data

=back

end text

=begin html
<TABLE BORDER=1>
<TR><TH>Hash<TH>Description
<TR><TD>font<TD><i>optional</i>. Specifies font for data in format, understanding by $dc object, <code>'Courier,&nbsp;12,&nbsp;0'</code> for example. 
<TR><TD>width<TD><i>required</i>.Width of column in vitrual points. 
<TR><TD>value<TD><i>optional</i>. Value to display. If value is scalar then
        corresponding string is displayed. If
        value is reference to sub, then this sub will be called. In addition to decribed here
        params new params <code>$dc</code>, <code>xpos</code>, <code>ypos</code>, <code>'height'</code>,
        <code>width</code>, <code>compute</code> will be passed.
        <code>xpos</code>, <code>ypos</code> defines the coordinates of top left corner of
        bounding rectangle, <code>width</code> and <code>height</code> defines width and height. If parameter compute is defined then sub must
        return minimal requred height of rectangle, if not - display the data. See drawmatrix
        sub for detail and as example. 
<TR><TD>border<TD><i>optional</i>. Define a border around displayed data. Must be string with
                         <code>T></code>, <code>B</code>, <code>L</code>, <code>R</code> chars for border on top, bottom, left and right
                         side of bounding rectangle. Default is empty string.
<TR><TD>pen<TD><i>optional</i>. Define width of pen of border. Default =1.
<TR><TD>brush<TD><i>optional</i>. Define the brush to fill background. If not defined then background
is not filled.
<TR><TD>opt<TD><i>optional</i>. Define the style used to display data. Must be string of chars.
      These chars are:
      <CENTER>
      <TABLE BORDER=1>
      <TR><TH COLSPAN=2>Horiz alignment</TH> </TR>
      <TR><TD>L</TD><TD>Left-aligment text   </TR>
      <TR><TD>R</TD><TD>Right-alignment      </TR>
      <TR><TD>J</TD><TD>Justified            </TR>
      <TR><TH COLSPAN=2>Vert alignment</TH>  </TR>
      <TR><TD>-</TD><TD>Center               </TR>
      <TR><TD>V</TD><TD>Bottom               </TR>
      <TR><TD><i>empty</i></TD><TD>Top           </TR>
      </TABLE>
      </CENTER>
      you can use any case.
<TR><TD>height<TD>Minimail height of displayed data
</TABLE>

=end html

=head2
drawmatrix subroutine

C<drawmatrix> sub allow to display structured data into one cell of report.
C<drawmatrix> use C<matrix> hash key, which is a reference to array of references
to array of references to hashes:

=begin text
$val is
[
  [{},{},{}...{}]
  [{},{},{}...{}]
  ....
  [{},{},{}...{}]
]

=end text

=begin html
<PRE>
$val is:
[
  [{},{},{}...{}]
  [{},{},{}...{}]
  ....
  [{},{},{}...{}]
]
</PRE>

=end html

Size of each cell in displayed matrix is 1/n of total width, where n is
a number of columns in matrix row.

=head2 Putting all together

=begin text
use ExtUtils::testlib;
use Wingraph;
use NPRG qw(drawmatrix);

$dc=new Wingraph( device=>"PS",  desc=>'test', metafile=>'tsta.emf') or die; #orientation=>'Landscape',
print "Start\n";
%st1=(font=>'Times New Roman Bold', size=>12, opt=>'C', border=>'TBLR', pen=>2);

$rp=new NPRG(dc=>$dc);
$rp->{'atbreak'}=sub{
                  $rp->pushq({font=>'Times, 6', opt=>'R', border=>'B', value=>'Отчет по чему-то там, стр. '.$rp->pagenum(), width=>980}
                            );
                  $rp->pushq({height=>20, value=>' ', width=>100}
                            );
                  $rp->pushq({font=>'Arial italic, 16', opt=>'-L', border=>'TBLR', value=>'Пушкин', width=>300, brush=>220},
                             {font=>'Courier Bold, 12', opt=>'-C', border=>'TBLR', value=>'Что-то еще', width=>250, brush=>220},
                             {value=>\&NPRG::drawmatrix, width=>400,
                                matrix=>[
                                  [ {font=>'Arial Bold Italic, 12', value=>'Месяцы', border=>'TBLR', opt=>'C'}],
                                  [
                                      {font=>'Times New Roman,8', value=>'I', border=>'TBLR', opt=>'-C'},
                                      {font=>'Times New Roman,8', value=>'II', border=>'TBLR', opt=>'-C'},
                                      {font=>'Times New Roman,8', value=>'III', border=>'TBLR', opt=>'-C'},
                                      {font=>'Times New Roman,8', value=>'IV', border=>'TBLR', opt=>'-C'},
                                  ],
                                  [
                                      {font=>'Times New Roman,7', value=>'I', border=>'TBLR', opt=>'-C'},
                                      {font=>'Times New Roman,7', value=>'II', border=>'TBLR', opt=>'-C'},
                                      {font=>'Times New Roman,7', value=>'III', border=>'TBLR', opt=>'-C'},
                                      {font=>'Times New Roman,7', value=>'IV', border=>'TBLR', opt=>'-C'},
                                      {font=>'Times New Roman,7', value=>'V', border=>'TBLR', opt=>'-C'},
                                      {font=>'Times New Roman,7', value=>'VI', border=>'TBLR', opt=>'-C'},
                                      {font=>'Times New Roman,7', value=>'VII', border=>'TBLR', opt=>'-C'},
                                      {font=>'Times New Roman,7', value=>'VIII', border=>'TBLR', opt=>'-C'},
                                      {font=>'Times New Roman,7', value=>'IX', border=>'TBLR', opt=>'-C'},
                                      {font=>'Times New Roman,7', value=>'X', border=>'TBLR', opt=>'-C'},
                                      {font=>'Times New Roman,7', value=>'XI', border=>'TBLR', opt=>'-C'},
                                      {font=>'Times New Roman,7', value=>'XII', border=>'TBLR', opt=>'-C'},
                                   ]
                                ],
                             }
                            );
                  $rp->pushq({width=>950, height=>3, brush=>0});
                  $rp->flushq();
                  print "Here\n";
               };

$rp->{'beforebreak'}=sub{
                  $rp->pushq({height=>20, value=>' ', width=>100}
                            );
                  $rp->pushq({font=>'Times New Roman, 12', opt=>'R', border=>'T', value=>'Отчет по чему-то там, стр. '.$rp->pagenum(), width=>980}
                            );
                  $rp->flushq();
               };

%st=(font=>'Courier New Bold, 10', opt=>'C-', border=>'TBLR');
for(1..10){
   $rp->pushq({height=>20, value=>' ', width=>100}) if $rp->pagenum == $oldpagenum;
   $oldpagenum=$rp->pagenum;
   for(1..4){
     $rp->pushq( {font=>'Times New Roman, 12', opt=>'JL', border=>'TBLR', value=>'Вот пистолеты уж',
                  width=>300},
                 {font=>'Courier Bold Italic, 12', opt=>'-C', border=>'TBLR', value=>"$_ 12121-1212", width=>250},
                 {width=>400, value=>\&drawmatrix,
                 matrix=>[
                           [{value=>"$_", %st},{value=>"$_", %st},{value=>"$_", %st},{value=>"$_",%st},]
                         ]
                 }
          );
   }
   $rp->flushq();
}
$rp->flushq();
print "End\n";

=end text

=begin html
<PRE>
use ExtUtils::testlib;
use Wingraph;
use NPRG qw(drawmatrix);
$dc=new Wingraph( device=>"PS",  desc=>'test', metafile=>'tsta.emf') or die; #orientation=>'Landscape',
print "Start\n";
%st1=(font=>'Times New Roman Bold', size=>12, opt=>'C', border=>'TBLR', pen=>2);
$rp=new NPRG(dc=>$dc);
$rp->{'atbreak'}=sub{
                  $rp->pushq({font=>'Times, 6', opt=>'R', border=>'B', value=>'Отчет по чему-то там, стр. '.$rp->pagenum(), width=>980}
                            );
                  $rp->pushq({height=>20, value=>' ', width=>100}
                            );
                  $rp->pushq({font=>'Arial italic, 16', opt=>'-L', border=>'TBLR', value=>'Пушкин', width=>300, brush=>220},
                             {font=>'Courier Bold, 12', opt=>'-C', border=>'TBLR', value=>'Что-то еще', width=>250, brush=>220},
                             {value=>\&NPRG::drawmatrix, width=>400,
                                matrix=>[
                                  [ {font=>'Arial Bold Italic, 12', value=>'Месяцы', border=>'TBLR', opt=>'C'}],
                                  [
                                      {font=>'Times New Roman,8', value=>'I', border=>'TBLR', opt=>'-C'},
                                      {font=>'Times New Roman,8', value=>'II', border=>'TBLR', opt=>'-C'},
                                      {font=>'Times New Roman,8', value=>'III', border=>'TBLR', opt=>'-C'},
                                      {font=>'Times New Roman,8', value=>'IV', border=>'TBLR', opt=>'-C'},
                                  ],
                                  [
                                      {font=>'Times New Roman,7', value=>'I', border=>'TBLR', opt=>'-C'},
                                      {font=>'Times New Roman,7', value=>'II', border=>'TBLR', opt=>'-C'},
                                      {font=>'Times New Roman,7', value=>'III', border=>'TBLR', opt=>'-C'},
                                      {font=>'Times New Roman,7', value=>'IV', border=>'TBLR', opt=>'-C'},
                                      {font=>'Times New Roman,7', value=>'V', border=>'TBLR', opt=>'-C'},
                                      {font=>'Times New Roman,7', value=>'VI', border=>'TBLR', opt=>'-C'},
                                      {font=>'Times New Roman,7', value=>'VII', border=>'TBLR', opt=>'-C'},
                                      {font=>'Times New Roman,7', value=>'VIII', border=>'TBLR', opt=>'-C'},
                                      {font=>'Times New Roman,7', value=>'IX', border=>'TBLR', opt=>'-C'},
                                      {font=>'Times New Roman,7', value=>'X', border=>'TBLR', opt=>'-C'},
                                      {font=>'Times New Roman,7', value=>'XI', border=>'TBLR', opt=>'-C'},
                                      {font=>'Times New Roman,7', value=>'XII', border=>'TBLR', opt=>'-C'},
                                   ]
                                ],
                             }
                            );
                  $rp->pushq({width=>950, height=>3, brush=>0});
                  $rp->flushq();
                  print "Here\n";
               };
$rp->{'beforebreak'}=sub{
                  $rp->pushq({height=>20, value=>' ', width=>100}
                            );
                  $rp->pushq({font=>'Times New Roman, 12', opt=>'R', border=>'T', value=>'Отчет по чему-то там, стр. '.$rp->pagenum(), width=>980}
                            );
                  $rp->flushq();
               };
%st=(font=>'Courier New Bold, 10', opt=>'C-', border=>'TBLR');
for(1..10){
   $rp->pushq({height=>20, value=>' ', width=>100}) if $rp->pagenum == $oldpagenum;
   $oldpagenum=$rp->pagenum;
   for(1..4){
     $rp->pushq( {font=>'Times New Roman, 12', opt=>'JL', border=>'TBLR', value=>'Вот пистолеты уж',
                  width=>300},
                 {font=>'Courier Bold Italic, 12', opt=>'-C', border=>'TBLR', value=>"$_ 12121-1212", width=>250},
                 {width=>400, value=>\&drawmatrix,
                 matrix=>[
                           [{value=>"$_", %st},{value=>"$_", %st},{value=>"$_", %st},{value=>"$_",%st},]
                         ]
                 }
          );
   }
   $rp->flushq();
}
$rp->flushq();
print "End\n";
</PRE>
You must got something like:
<A IMG=rep.jpg>

=end html 

It's all, folks!
