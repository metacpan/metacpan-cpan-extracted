#!/usr/bin/perl

BEGIN {
  push @INC , '../';  
  push @INC , '../SVG';
}

use SVG;
use strict;
use CGI  ':header';

my $p = CGI->new;
print $p->header(-type=>'image/svg+xml');

my $svg = SVG->new(width=>500,height=>500);
$svg->desc()->cdata('This example shows some more features of SVG Text');
$svg->title()->cdata('Sample 3: text');

$svg->comment(
'hello I am a dog. Actually, I am an SVG demo of the perl SVG.pm module',
'While the original static example was done by SUN, this is a 100% dynamic',
'sample. Case in point. Last time I looked, the SUN sample did not work on any',
'of my browser implementations.',
'=========================================================================',
'SVG Sample Pool : Text',
'This sample shows some powerful features of SVG Text elements ',
'among which are the "text" element; "tspan" element; "textPath" element;',
'text orientation management using "writing-mode" and text alignment',
'using property of "text-anchor".  Some font-related features are also',
'Sun @author        Sheng Pei, Vincent Hardy ',
'Copyright Sun Microsystems Inc., 2000-2002 ',
'Notice that the copyright is next year!! Today is 13.10.01 (editor)',
'I wondef if the copyright includes machine-generated renditions of',
'the content, like I am doing. Awfully presumptuous to copyright',
'content that is being offered as a sample of SVG application',
'=========================================================================',
);

my $defg_m = $svg->defs()->group(id=>'marker',style=>{"stroke-width"=>1});
$defg_m->line(x1=>-15,y1=>0,x2=>15,y2=>0,style=>{'stroke'=>'currentColor'});
$defg_m->line(y1=>-15,x1=>0,y2=>15,x2=>0,style=>{'stroke'=>'currentColor'});

$svg->comment(
'=====================================================================',
'Simple text element, for the graphics title.                         ',
'This illustrates a very simple text element where text is centered   ',
'about its anchor.                                                    ',
'=====================================================================',
'Draw simple text');
$svg->text(x=>200, y=>80, style=>
  {'text-anchor'=>'middle', 'font-size'=>60, 'font-weight'=>800, 'font-family'=>'Verdana', 'font-style'=>'italic'})->cdata('hello, Sun.');

$svg->comment('Display marker for the anchor point');
$svg->use(-href=>"#marker", style=>"color:black", transform=>'translate(200, 80)');

$svg->comment(
'=====================================================================',
"The first part of the picture: 'SVG' following the upper curved line",
'defs / xlink:href in textPath is the way to achieve text on a path.',
'This illustrates: text, textPath and tspan',
'=====================================================================',
'Define the path on which text is laid out');
my $path = $svg->get_path(x=>[-100,0, 200,200],y=>[0,-100,-100,0]);
$svg->defs()->path(id=>"Path1",%$path);



my $textLayout1 = $svg->group(id=>"textLayout1", transform=>"translate(200, 250)");

		$textLayout1->comment('Draw the path on which text is laid out');
  	$textLayout1->use(-href=>"#Path1", style=>{stroke=>'yellow','stroke-width'=>40, 'fill'=>'none'});
  	$textLayout1->use(-href=>"#Path1", style=>{stroke=>'black','stroke-width'=>1, fill=>'none'});

		$textLayout1->comment('Layout text on path');
  	$textLayout1->text(style=>{'font-family'=>'Verdana',
                  'font-size'=>80, 'font-weight'=>800,
                  fill=>'blue', 'text-anchor'=>'middle'});

		my $textLayoutpath1 = $textLayout1->text(-type=>'path', -href=>"#Path1", startOffset=>"0");
    $textLayoutpath1->text(-type=>'span', style=>"fill:black")->cdata('S');
    $textLayoutpath1->text(-type=>'span', style=>{stroke=>'black',fill=>'white'})->cdata('V');
    $textLayoutpath1->text(-type=>'span', style=>"fill:red")->cdata('G');

$svg->comment('textLayout1',
'=======================================================================',
"The second part of the picture: 'is' following the right vertical line ",
'This illustrates glyph layout capabilities, here top to bottom layout.',
'======================================================================='
);

  $svg->defs()->path(id=>"Path2", d=>"M 100 0 l 0 150");




 my $tl2 = $svg->group(id=>"textLayout2" ,transform=>"translate(200, 250)");

  	$tl2->use(-href=>"#Path2", style=>{stroke=>'red', 'stroke-width'=>40});


		$tl2->comment("Here we change the writing-mode of the text element to 'tb' (for 'top to bottom')");
  
    $tl2->text( x=>"100", y=>"75", style=>{'font-family'=>'Verdana', 'font-weight'=>800, 'font-size'=>50,fill=>'white', 'writing-mode'=>'tb', 'text-anchor'=>'middle'})->cdata('is');

		$tl2->use( -href=>"#marker", style=>"color:black;", transform=>"translate(100, 75)" );

  

$svg->comment('======================================================================',
"Third part of the picture: 'very' following the bottom horizontal line",
'This illustrates one way of displaying text upside down.              ',
'======================================================================',
'Define the path where the text is laid out');

  $svg->defs()->path(id=>"Path3", d=>"M 100 150 l -200 0");


$svg->comment('Draw the path on which text is laid out');
my $tl3 = $svg->group( id=>"textLayout3", transform=>"translate(200, 250)");
$tl3->use(-href=>"#Path3", style=>"stroke:yellow; stroke-width:40");
$tl3->use( -href=>"#Path3", style=>{stroke=>'black','stroke-width'=>1});
$tl3->text(style=>{ 'font-family'=>'Verdana', 'font-size'=>40,
                    'font-weight'=>900, fill=>'black',
                    stroke=>'none', 'text-anchor'=>'middle'} );
$tl3->text(type=>'path', -href=>"#Path3", 'xml:space'=>"default")->cdata('very');

$svg->comment('textLayout3');





$svg->comment('========================================================================',
"The fourth part of the picture: 'cool' following the left vertical line",
'This further illustrates tspan, this time directly in a text element.',
'========================================================================');

$svg->defs()->path(id=>"Path4", d=>"M -100 150 l 0 -150" );


my $tl4 = $svg->group(id=>"textLayout4", transform=>"translate(200, 250)");

  	$tl4->use( -href=>"#Path4", style=>"stroke:red; stroke-width:40");

  	my $tl4_t = $tl4->text( x=>"0", y=>"0", 
                style=>{'font-family'=>'Verdana', 'font-size'=>50, 
                        'font-style'=>'italic',fill=>'white',
                         stroke=>'black', 'writing-mode'=>'lr',
                         'text-anchor'=>"middle"},
					      transform=>"translate(-100, 75) rotate(-90)");
$tl4_t->tspan(dy=>"0")->cdata('cool!');
$tl4_t->tspan(dy=>"-25", 
              style=>{'font-size'=>10, stroke=>'none', fill=>'black'})
              ->cdata('SVG');
$tl4_t->tspan(dy=>"0",style=>{'font-size'=>10, stroke=>'none', fill=>'black'})->cdata('SVG');

$tl4->use(transform=>"translate(-100, 75)", -href=>"#marker", style=>"color:black;");

$svg->comment(
'=============================================================================',
"Below are steps to produce the 'SVG' in the box, mainly using the text-anchor",
'to align the three glyphs                                          				  ',
'This illustrates the various text anchors.                                   ',
'=============================================================================');

	my $tl5 = $svg->group( id=>"textLayout5", transform=>"translate(180, 290)", style=>"font-weight:800");

		$tl5->use( -href=>"#marker", style=>{fill=>'black', stroke=>'black',transform=>'translate(30, 50)'});

		$tl5->comment('Anchored to the end');
  	$tl5->text( x=>"30", y=>"50", style=>{'font-family'=>'Verdana','font-size'=>100, 
					stroke=>'black', fill=>'none', 'text-anchor'=>'end'})->cdata('S');
      

		$tl5->comment('Anchored to the start');
  	$tl5->text( x=>"30", y=>"50", 
                style=>{'font-family'=>'Verdana', 'font-size'=>40, 
        	              'font-weight'=>700, stroke=>'black',fill=>'none',
                        'text-anchor'=>'start'})
                ->cdata('G');
      

		$tl5->comment("When the orientation is 'top_bottom' using 'start' as the anchor makes",
    'the glyph aligns to the upper line',);

		$tl5->use(-href=>"#marker", style=>"color:red", transform=>"translate(48, -30)");

		$tl5->comment('Anchored to the start, with top to bottom text layout');
  	$tl5->text( x=>"48", y=>"-30", 
                style=>{'font-family'=>'Verdana',
                        'font-size'=>50,stroke=>'red',
                        fill=>'none','writing-mode'=>'tb', 
                        'text-anchor'=>'start'})
                ->cdata('V');


$svg->anchor(-href=>"http://roitsystems.com/")->text(x=>200, y=>160, style=>
  {'text-anchor'=>'middle', 'font-size'=>30, 'font-weight'=>800, 'font-family'=>'Verdana', 'font-style'=>'italic', opacity=>0.3})->cdata('Use SVG.pm');

print $svg->xmlify;


__END__



<?xml version="1.0" encoding="iso-8859-1"?>


<!-- ========================================================================= -->
<!-- SVG Sample Pool : Text                                                    -->
<!--                                                                           -->
<!-- This sample shows some powerful features of SVG Text elements             -->
<!-- among which are the "text" element; "tspan" element; "textPath" element;  -->
<!-- text orientation management using "writing-mode" and text alignment       -->
<!-- using property of "text-anchor".  Some font-related features are also     -->
<!-- exercised.                                                                -->
<!--               							                                               -->
<!-- @author        Sheng Pei, Vincent Hardy                                   -->
<!--                XML Technology Center, Sun Microsystems Inc.               -->
<!-- @version       1.1, July 5 2000                                           -->
<!-- @version       1.0, June 27  2000                                         -->
<!--                                                                           -->
<!-- Copyright Sun Microsystems Inc., 2000-2002                                -->
<!-- ========================================================================= -->


<svg width="500" height="500" xml:space="default"> 

  <desc> This example shows some more features of SVG Text. </desc>
  <title> Sample 3: text </title>
		<defs>
			<g id="marker" style="stroke-width:1">
				<line x1="-15" y1="0" x2="15" y2="0" style="stroke:currentColor" />
				<line y1="-15" x1="0" y2="15" x2="0" style="stroke:currentColor" />
				<circle cx="0" cy="0" r="3" style="fill:currentColor" />
			</g>
		</defs>

<!-- ===================================================================== -->
<!-- Simple text element, for the graphics title.                          -->
<!-- This illustrates a very simple text element where text is centered    -->
<!-- about its anchor.                                                     -->
<!-- ===================================================================== -->

<!-- Draw simple text -->
<text x="200" y="80" style="text-anchor:middle; font-size:60; font-weight:800; font-family:Verdana; font-style:italic">SVG Text</text>

<!-- Display marker for the anchor point -->
<use xlink:href="#marker" style="color:black" transform="translate(200, 80)"/>

<!-- ===================================================================== -->
<!-- The first part of the picture: 'SVG' following the upper curved line  -->
<!-- defs / xlink:href in textPath is the way to achieve text on a path.   -->
<!-- This illustrates: text, textPath and tspan                            -->
<!-- ===================================================================== -->

	<!-- Define the path on which text is laid out -->
  <defs>
    <path id="Path1"
          d="M -100 0 c 0 -100 200 -100 200 0" />
  </defs>

	<g id="textLayout1" transform="translate(200, 250)">

		<!-- Draw the path on which text is laid out -->
  	<use xlink:href="#Path1" style="stroke:yellow; stroke-width:40; fill:none;" />
  	<use xlink:href="#Path1" style="stroke:black; stroke-width:1; fill:none;" />

		<!-- Layout text on path -->
  	<text style="font-family:Verdana; font-size:80; font-weight:800; fill:blue; text-anchor:middle">
			<textPath xlink:href="#Path1" startOffset="0" >
<tspan style="fill:black">S</tspan>
<tspan style="stroke:black; fill:white;">V</tspan>
<tspan style="fill:red">G</tspan>  
    	</textPath>
  	</text>

	</g> <!-- textLayout1 -->

<!-- ======================================================================= -->
<!-- The second part of the picture: 'is' following the right vertical line  -->
<!-- This illustrates glyph layout capabilities, here top to bottom layout.  -->
<!-- ======================================================================= -->

  <defs>
    <path id="Path2"
          d="M 100 0 l 0 150" />
  </defs>

	<g id="textLayout2" transform="translate(200, 250)" >

  	<use xlink:href="#Path2" style="stroke:red; stroke-width:40" />


		<!-- Here we change the writing-mode of the text element to 'tb' (for 'top to bottom') -->
  	<text x="100" y="75" style="font-family:Verdana; font-weight:800; font-size:50; 
																fill:white; writing-mode:tb; text-anchor:middle">is</text>

		<use xlink:href="#marker" style="color:black;" transform="translate(100, 75)" />
	</g>


<!-- ====================================================================== -->
<!-- Third part of the picture: 'very' following the bottom horizontal line -->
<!-- This illustrates one way of displaying text upside down.               -->
<!-- ====================================================================== -->

	<!-- Define the path where the text is laid out -->
  <defs>
    <path id="Path3"
          d="M 100 150 l -200 0" />
  </defs>

	<!-- Draw the path on which text is laid out -->

	<g id="textLayout3" transform="translate(200, 250)">
  	<use xlink:href="#Path3" style="stroke:yellow; stroke-width:40" />
  	<use xlink:href="#Path3" style="stroke:black; stroke-width:1" />

  	<text style="font-family:Verdana; font-size:40; font-weight:900; fill:black; stroke:none; text-anchor:middle">
    	<textPath xlink:href="#Path3" xml:space="default">very</textPath>
  	</text>

	</g> <!-- textLayout3 -->

<!-- ======================================================================== -->
<!-- The fourth part of the picture: 'cool' following the left vertical line  -->
<!-- This further illustrates tspan, this time directly in a text element.    -->
<!-- ======================================================================== -->

  <defs>
    <path id="Path4"
          d="M -100 150 l 0 -150" />
  </defs>

	<g id="textLayout4" transform="translate(200, 250)">
  	<use xlink:href="#Path4" style="stroke:red; stroke-width:40" />

  	<text x="0" y="0" style="font-family:Verdana; font-size:50; 
                               font-style:italic; fill:white; stroke:black; writing-mode:lr; text-anchor:middle;"
					transform="translate(-100, 75) rotate(-90)">
<tspan dy="0">
cool!
</tspan>
<tspan dy="-25" style="font-size:10; stroke:none; fill:black;">
SVG
</tspan>
  	</text>

  	<use transform="translate(-100, 75)" xlink:href="#marker" style="color:black;" />
	</g>

<!-- ============================================================================= -->
<!-- Below are steps to produce the 'SVG' in the box, mainly using the text-anchor -->
<!-- to align the three glyphs                                          				   -->
<!-- This illustrates the various text anchors.                                    -->
<!-- ============================================================================= -->

	<g id="textLayout5" transform="translate(180, 290)" style="font-weight:800">

		<use xlink:href="#marker" style="fill:black; stroke:black" transform="translate(30, 50)" />

		<!-- Anchored to the end -->
  	<text x="30" y="50" style="font-family:Verdana; font-size:100; 
					stroke:black; fill:none; text-anchor:end">S</text>
      

		<!-- Anchored to the start -->
  	<text x="30" y="50" style="font-family:Verdana; font-size:40; 
        	font-weight:700; stroke:black; fill:none; text-anchor:start">G</text>
      

<!-- When the orientation is 'top_bottom' using 'start' as the anchor makes -->
<!-- the glyph aligns to the upper line                                     -->

		<use xlink:href="#marker" style="color:red" transform="translate(48, -30)" />

		<!-- Anchored to the start, with top to bottom text layout -->
  	<text x="48" y="-30" style="font-family:Verdana; font-size:50; 
        	stroke:red; fill:none; writing-mode:tb; text-anchor:start">
      	V
  	</text>

	</g>

</svg>
