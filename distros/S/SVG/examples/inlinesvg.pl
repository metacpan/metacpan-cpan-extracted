#!/usr/bin/perl -w

use strict;
use CGI;

BEGIN {
  push @INC , '../';  
  push @INC , '../SVG';
}

use SVG;

my $VERSION = 3;

#---------Create the CGI object which is required to handle the header
my $p = CGI->new();

$| = 1;


#---------print the header just before outputting to screen




#---------

#---------Create the svg object

my $height = $p->param('h') || 400;
my $width = $p->param('w') || 800;

my $svg= SVG->new(width=>$width,height=>$height,-inline=>1,
                  -namespace=>'abc'); 

my $y=$svg->group( id=>'group_generated_group',style=>{ stroke=>'red', fill=>'green' });

my $z=$svg->tag('g',  id=>'tag_generated_group',style=>{ stroke=>'red', fill=>'black' });


my $ya = $y -> anchor(
		-href   => 'http://somewhere.org/some/line.html',
		-target => 'new_window_0');


my $line_transform = 'matrix(0.774447 0.760459 0 0.924674 357.792 -428.792)';

my $line = $svg->line(id=>'l1',x1=>(rand()*$width+5),
          y1=>(rand()*$height+5),
          x2=>(rand()*$width-5),
          y2=>(rand()*$height-5),
          style=>&obj_style,);

#---------
foreach  (1..&round_up(rand(20))) {
    my $myX = $width-rand(2*$width);
    my $myY = $height-rand(2*$height);

    my $rect = $y->rectangle (x=>$width/2,
                   y=>$height/2,
                   width=>(50+50*rand()),
                   height=>(50+50*rand()),
                   rx=>20*rand(),
                   ry=>20*rand(),
                   id=>'rect_1',
                   style=>&obj_style);

    $rect->animate(attributeName=>'transform', 
                attributeType=>'XML',
                from=>'0 0',
                to=>$myX.' '.$myY,
                dur=>&round_up(rand(20),2).'s',
                repeatCount=>&round_up(rand(30)),
                restart=>'always',
                -method=>'Transform',);
}
my $a = $z -> anchor(
		-href   => 'http://somewhere.org/some/other/page.html',
		-target => 'new_window_0',
        id=>'anchor a');

my $a1 = $z -> anchor(
		-href   => '/index.html',
		-target => 'new_window_1',
        id=>'anchor a1');

my $a2 = $z -> anchor(
		-href   => '/svg/index.html',
		-target => 'new_window_2',
        id=>'anchor a2');

#---------

my $c;
foreach  (1..&round_up(rand(5))) {

    $c= $a->circle(cx=>($width-20)*rand(),
                    cy=>($height-20)*rand(),
                    r=>100*rand(), 
                    id=>'c1',
                    style=>&obj_style);

    $c = $a1->circle(cx=>($width-20)*rand(),
                    cy=>($height-20)*rand(),
                    r=>100*rand(), 
                    id=>'c2',
                    style=>&obj_style);
}
#---------

my $xv = [$width*rand(), $width*rand(), $width*rand(), $width*rand()];

my $yv = [$height*rand(), $height*rand(), $height*rand() ,$height*rand()];

my $points = $a->get_path(x=>$xv,
                          y=>$yv,
                        -type=>'polyline',
                        -closed=>'true',);
                     

$c = $a1->polyline (%$points,
                    id=>'pline1',
                    style=>&obj_style);

#---------

$xv = [$width*rand(), $width*rand(), $width*rand(), $width*rand()];

$yv = [$height*rand(), $height*rand(), $height*rand() ,$height*rand()];

$points = $a->get_path(x=>$xv,
                          y=>$yv,
                        -type=>'polygon',);


$c = $a->polygon (%$points,
                    id=>'pgon1',
                    style=>&obj_style);
#---------


my $t=$a2->text(id=>'t1',
                transform=>'rotate(-45)',
                style=>&text_style);
#---------


my $u=$a2->text(id=>'t3',
              x=>$width/2*rand(),
              y=>($height-80)*rand(),
              transform=>'rotate('.(-2.5*5*rand()).')',
              style=>&text_style);



my $v=$a2->tag('text',
              id=>'t5',
              x=>$width/2*rand(),
              y=>$height-40+5*rand(),
              transform=>'rotate('.(-2.5*5*rand()).')',
              style=>&text_style);

my $w=$a2->text(id=>'t5',
              x=>$width/2*rand(),
              y=>$height-20+5*rand(),
              transform=>'rotate('.(-2.5*5*rand()).')',
              style=>&text_style);


$t->cdata('Text generated using the high-level "text" tag');
$t->cdata('Courtesy of RO IT Systems GmbH');
$v->cdata('Text generated using the low-level "tag" tag');
$w->cdata('But what about inline SVG? Yes, we do that too');
$w->cdata('All this with SVG.pm? Wow.');

print $p->header('image/svg-xml');
print $svg->render(-inline=>1);

exit;


#################
# Subroutine to round up the value of a number or of a text representation of number
# 
sub round_up {
    my ($x, $precision) = shift;
    $x =~ s/^\s+//g;
    $x =~ s/\s+$//g;
    $x =~ s/,//g;

    my $y;
    $precision = 0 unless $precision;
    ($x, $y) =  split( /\./, $x) if $x =~ /\./;
    my $y1 = substr($y, 0, $precision);
    my $y2 = substr($y, $precision, 1);

    if ($y2 >= 5) {
        $precision?$y1++:$x++;
    }

    return "$x$y1";

} # sub round_val

sub obj_style {

    my $style = {'stroke-miterlimit'=>(4*rand()),
          'stroke-linejoin'=>'miter',
          'stroke-linecap'=>'round',
          'stroke-width'=>(0.1+0.5*rand()),
          'stroke-opacity'=>(0.5+0.5*rand()),
          'stroke'=>'rgb('.255*round_up(rand()).','.255*round_up(rand()).','.255*round_up(rand()).')',
          'fill-opacity'=>(0.5+0.5*rand()),
          'fill'=>'rgb('.255*round_up(rand()).','.255*round_up(rand()).','.255*round_up(rand()).')',
          'opacity'=>(0.5+0.5*rand()) };

    return $style;

}

sub text_style {

    my $style = {'font-family'=>'Arial',
          'font-size'=>8+5*rand(),
          'stroke-width'=>1+2*rand(),
          'stroke-opacity'=>(0.2+0.5*rand()),
          'stroke'=>'rgb('.255*round_up(rand()).','.255*round_up(rand()).','.255*round_up(rand()).')',
          'fill-opacity'=>1,
          'fill'=>'rgb('.255*round_up(rand()).','.255*round_up(rand()).','.255*round_up(rand()).')',
          'opacity'=>(0.5+0.5*rand()) };

    return $style;

}

#---------
