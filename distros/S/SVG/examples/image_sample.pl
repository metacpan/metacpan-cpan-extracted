#!/usr/bin/perl

use strict;
use warnings;

#
# Incorporating an SVG image into another SVG image as an image object.
#
#

use SVG;
use CGI ':new :header';
my $p = CGI->new;
$| = 1;

my $svg = SVG->new(width=>800,height=>400); 

$svg->desc( id=>'root-desc')->cdata('hello this is a description');

$svg->title( id=>'root-title')->cdata('Dynamic SVG - Image usage within SVG using Perl');

#use another SVG component as an image inside our image

$svg->image(id=>'image_1',
                      -href=>'SVG_02_sample.pl',
                      x=>150,
                      y=>150,
                      width=>100,
                      height=>100);  



#create a link to an other site through a png image
#We must first generate an anchor tag, give it agroup as a child, 
#and put the image as a child in it.

$svg->anchor('-href'=>"http://www.hackmare.com/",target=>'new_window')
    ->group(id=>'png_group')
    ->image(id=>'image_2',
            -href=>'http://www.hackmare.com/icons/logo/hackmaresplash600_1.png',
            x=>10,
            y=>10,
            width=>600,
            height=>94,);  

$svg->text(x=>20,y=>280)->cdata('EXPLANATION');  
$svg->text(x=>20,y=>310)->cdata('One image is imported as a full SVG image');  
$svg->text(x=>20,y=>325)->cdata('The second (hackmare) image is imported is an .png image');  
$svg->text(x=>20,y=>340)->cdata('Notice that the hackmare image contains a url anchor');  
$svg->text(x=>20,y=>355,style=>{fill=>'red'})->cdata('Actually, the link anchor contains a group which contains the image');  
$svg->text(x=>200,y=>385,style=>{fill=>'red','fill-opacity'=>0.2})->cdata("This image was generated with perl using Ronan Oger's SVG module");  
print $p->header('image/svg-xml');

print $svg->xmlify;
print "\n";
