#!/usr/bin/perl

use strict;
use warnings;

use SVG;

my $points;
my $path;
my $style;
my $transform;

my $string;
my $gradient;

my $svg = SVG->new(width=>800,height=>600);

my $lg = $svg->gradient(-type=>'linear',
		'id'=>"transparent-sky_1",
		'x1'=>"0%",
		'y1'=>"0%",
		'x2'=>"100%",
		'y2'=>"0%",
		'spreadMethod'=>"pad",
		'gradientUnits'=>"userSpaceOnUse");

	$lg->stop(offset=>"0%",
            style=>{'stop-color'=>'rgb(1,71,1)','stop-opacity'=>1});
	$lg->stop(offset=>"37%",
            style=>{'stop-color'=>'rgb(0,128,0)','stop-opacity'=>1});
	$lg->stop(offset=>"38%",
            style=>{'stop-color'=>'rgb(255,255,255)','stop-opacity'=>1});
	$lg->stop(offset=>"45%",
            style=>{'stop-color'=>'rgb(192,192,255)','stop-opacity'=>1});


$svg->gradient(-type=>'linear',
				id => "custom-paint_1",
				x1=>"0%",
				y1=>"0%",
				x2=>"100%",
				y2=>"0%",
				spreadMethod=>"pad",
				gradientUnits=>"objectBoundingBox");


 $lg = $svg->gradient(-type=>'linear',
                        id =>'red-dark-green',
                        x1=>'0%',
                        y1=>'0%',
                        x2=>'100%',
                        y2=>'0%',
                        spreadMethod=>'pad',
                        gradientUnits=>'userSpaceOnUse');

	$lg->stop(offset=>'0%',
          style=>{'stop-color'=>'rgb(225,0,25)','stop-opacity'=>'0.75'});

	$lg->stop(offset=>"100%", style=>{'stop-color'=>'rgb(0,96,27)','stop-opacity'=>0.5});

my $lg2 = $svg->gradient(-type=>'linear',
				id => 'black-white_1',
				x1=>"0%",
				y1=>"0%",
				x2=>"100%",
				y2=>"0%",
				spreadMethod=>"pad",
				gradientUnits=>"userSpaceOnUse");

	$lg2->stop(offset=>"0%",
            style=>{'stop-color'=>'rgb(0,0,0)','stop-opacity'=>"0.8"});
	$lg2->stop(offset=>"100%",
            style=>{'stop-color'=>'rgb(255,255,255)','stop-opacity'=>"1"});

#XXX Is this the right parent?
my $Argyle_1 = $svg->pattern(id=>"Argyle_1",
				width=>"50",
				height=>"50",
				patternUnits=>"userSpaceOnUse",
				patternContentUnits=>"userSpaceOnUse");


my $Argyle_1_lg = $Argyle_1->gradient(id=>"red-yellow-red",
				x1=>"0%",
				y1=>"0%",
				x2=>"100%",
				y2=>"0%",
				spreadMethod=>"pad",
				gradientUnits=>"objectBoundingBox"	);

	$Argyle_1_lg->stop(offset=>"10%",
					            style=>{'stop-color'=>'rgb(255,0,0)','stop-opacity'=>1});

	$Argyle_1_lg->stop(offset=>"50%",
        					  style=>{'stop-color'=>'rgb(253,215,0)','stop-opacity'=>1});
	$Argyle_1_lg->stop(offset=>"90%",
  			        		style=>{'stop-color'=>'rgb(255,0,0)','stop-opacity'=>1});

  my $argyle_1_1 = $Argyle_1->gradient(-type=>'linear',
    				id=>"black-white",
		    		x1=>"0%",
            y1=>"0%",
            x2=>"100%",
            y2=>"0%",
            spreadMethod=>"pad",
            gradientUnits=>"objectBoundingBox");

	$argyle_1_1->stop(offset=>"0%",
          				style=>{'stop-color'=>'rgb(255,0,0)','stop-opacity'=>'1'});

	$argyle_1_1->stop(offset=>"100%",
          				style=>{'stop-color'=>'rgb(255,255,0)','stop-opacity'=>'1'});

  my $Bumpy = $svg->filter(id=>'Bumpy',filterUnits=>"objectBoundingBox",
              x=>"-10%",y=>"-10%",
              width=>"150%", height=>"150%",
              filterUnits=>'objectBoundingBox',);

  $Bumpy->fe(-type=>'turbulence', baseFrequency=>'0.15',
            numOctaves=>'1', result=>'image0');

  $Bumpy->fe(-type=>"gaussianblur", stdDeviation=>"3",
              in=>"image0", result=>"image1");

  $Bumpy->fe(-type=>"diffuselighting",'in'=>"image1",
              'surfaceScale'=>10,'diffuseConstant'=>"1",'result'=>"image3",
              style=>{'lighting-color'=>'rgb(255,255,255)'})
             ->fe(-type=>'distantlight',azimuth=>"0", elevation=>"45");

  $Bumpy->fe(-type=>"composite",in=>"image3",
            in2=>"SourceGraphic",operator=>"arithmetic",
            k2=>"0.5",k3=>"0.5",result=>"image4");

  $Bumpy->fe(-type=>"composite",in=>"image4",
            in2=>"SourceGraphic", operator=>"in",
            result=>"image5");

my $pointillist = $svg->filter(id=>"pointillist", filterUnits=>"objectBoundingBox",
            x=>"-10%", y=>"-10%", width=>"150%", height=>"150%");
	$pointillist->fe(-type=>'turbulence', baseFrequency=>"0.1",
                  numOctaves=>"2",  result=>'I1');
	$pointillist->fe(-type=>'morphology', in=>"I1", radius=>"5",
              operator=>"dilate", result=>"I2");
	$pointillist->fe(-type=>'colormatrix', in=>"I2", type=>"matrix",
                values=>"1 0 0 0 0 0 1 0 0 0 0 0 1 0 0 0 0 0 0 255",
                result=>"I3");
	$pointillist->fe(-type=>'composite', in=>"I3",
                   in2=>"SourceGraphic", operator=>"in");


  my $arg_1_grad_1 = $Argyle_1->gradient(id=>'custom-paint',
             spreadMethod=>'pad',
             gradientUnits=>'objectBoundingBox',
             x1=>'0%',
             x2=>'100%',
             y1=>'0%',
             y2=>'100%',);

  $arg_1_grad_1->stop(offset=>'0%' ,'stop-color'=>'rgb(128,0,0)',
                      'stop-opacity'=>1);
  $arg_1_grad_1->stop(offset=>'37%','stop-color'=>'rgb(222,0,0)',
                      'stop-opacity'=>.8);
  $arg_1_grad_1->stop(offset=>'43%','stop-color'=>'rgb(255,128,128)',
                      'stop-opacity'=>1);
  $arg_1_grad_1->stop(offset=>'45%','stop-color'=>'rgb(255,0,0)',
                      'stop-opacity'=>1);
  $arg_1_grad_1->stop( offset=>'54%','stop-color'=>'rgb(192,0,0)',
                      'stop-opacity'=>0.7);
  $arg_1_grad_1->stop(offset=>'100%','stop-color'=>'rgb(240,0,175)',
                      'stop-opacity'=>1);

	my $arg_1_g_1 = $Argyle_1->group(id=>'group_inside_pattern_1');
#			$svg->emptyTag('polygon',
#						style=>"stroke:rgb(112,97,66);stroke-width:1;stroke-opacity:1;stroke-miterlimit:30;fill:rgb(215,207,189);fill-opacity:1",
#						points=>"25,10 34,25 25,40 16,25");

	$points = "25,10 34,25 25,40 16,25";

	$style = {	'stroke'			=>	'rgb(112,97,66)',
				'stroke-width'		=>	1,
				'stroke-opacity'	=>	1,
				'stroke-miterlimit'	=>	30,
				'fill'				=>	'rgb(215,207,189)',
				'fill-opacity'		=>	'1'	};

  my  $r_pts = $arg_1_g_1->get_path(x=>[25,34,25,16],y=>[10,25,40,25],-type=>'polygon');
	$arg_1_g_1->polygon(id=>'pg1',%$r_pts,style=>$style);

  $r_pts = $arg_1_g_1->get_path(x=>[50,59,50,41],y=>[10,25,40,25],-type=>'polygon');
	$arg_1_g_1->polygon(id=>'pg2',%$r_pts,style=>$style);

  $r_pts = $arg_1_g_1->get_path(x=>[0,9,0,-9],y=>[10,25,40,25],-type=>'polygon');
	$arg_1_g_1->polygon(id=>'pg3',%$r_pts,style=>$style);

  $r_pts = $arg_1_g_1->get_path(x=>[11,21,11,1],y=>[0,25,50,25],-type=>'polygon');
	$arg_1_g_1->polygon(id=>'pg4',%$r_pts,style=>$style);

  $r_pts = $arg_1_g_1->get_path(x=>[25,34,25,16],y=>[10,25,40,25],-type=>'polygon');
	$arg_1_g_1->polygon(id=>'pg5',%$r_pts,style=>$style);


	$style = {	'stroke'			=>	'rgb(52,48,40)',
				'stroke-width'		=>	1,
				'stroke-opacity'	=>	1,
				'stroke-miterlimit'	=>	30,
				'fill'				=>	'rgb(172,152,112)',
				'fill-opacity'		=>	'1'	};

  $r_pts = $arg_1_g_1->get_path(x=>[20,30,25],y=>[0,0,9],-type=>'polygon');
	$arg_1_g_1->polygon(id=>'pg6',%$r_pts,style=>$style);

  $r_pts = $arg_1_g_1->get_path(x=>[20,25,30],y=>[50,41,50],-type=>'polygon');
	$arg_1_g_1->polygon(id=>'pg7',%$r_pts,style=>$style);


  $svg->rect(x=>"193", y=>"201",
    				width=>"422",	height=>"140",
		    		rx=>"3",ry=>"6",
				    'stroke-miterlimit'=>4,
                     'stroke-linejoin'=>'miter',
                     'stroke-width'=>1,
                     'stroke-opacity'=>1,
                     'stroke'=>'rgb(0,0,0)',
                     'fill-opacity'=>1,
                     'fill'=>'rgb(148,65,175)',
                     'opacity'=>0.31);






	$style = {'stroke-miterlimit'=>4,
			'stroke-linejoin'=>'miter',
			'stroke-linecap'=>'round',
			'stroke-width'=>'11',
			'stroke-opacity'=>1,
			'stroke'=>'rgb(0,0,0)',
			'fill-opacity'=>1,
			'fill'=>'rgb(0,0,0)',
			'opacity'=>'0.5'};


$svg->text(x=>"318", y=>"333",
          transform=>'matrix(1.58041 -0.293543 0.333969 1.3891 -396.141 -55.3847)', style=>{'font-family'=>'Arial Rounded MT Bold',
                  'font-size'=>100,'stroke-width'=>1,'stroke-opacity'=>1,
                  stroke=>'rgb(0,0,0)', 'fill-opacity'=>1,fill=>'rgb(0,0,0)',
                  opacity=>1,visibility=>'inherit'},
          filter=>'url(#pointillist)')
                ->cdata('A');

$svg->polygon(points=>'33.6776,266.425 34.408,266.795 33.6684,267.165 33.8903,266.795',
              'stroke-miterlimit'=>4, 'stroke-linejoin'=>'miter',
              fill=>'rgb(0,0,0)');

$svg->polygon(points=>'75.8931,140.313 -18,268.028 77.0816,395.744 48.5571,268.028',
		          'stroke-linejoin'=>'miter',
              fill=>'url(#red-yellow-red)',
              filter=>'url(#Bumpy)');


$style = {'stroke-miterlimit'=>'4',
		      'stroke-linejoin'=>'miter',
		      'stroke-linecap'=>'round',
		      'stroke-width'=>'11',
		      'stroke-opacity'=>'1',
		      'stroke'=>'url(#Argyle_1)',
		      'fill-opacity'=>'1',
		      'fill'=>'rgb(12,5,1)',
		      'opacity'=>'0.5'};

$path = "M311.591 367.68 L354.854 124.686 L459.18 160.388 L455.469 199.691 L404.735 219.984 L360.521 215.961 L326.636 369.343";

$svg->path(d=>$path,style=>$style);


$transform = 'matrix(0.994363 0.10603 -0.10603 0.994363 32.2186 -53.9305)';

$style = {	'stroke-width'	=>1,
			'stroke-opacity'=>1,
			'stroke'		=>'rgb(241,19,19)',
			'fill-opacity'	=>1,
			'fill'			=>'rgb(243,214,21)',
			'opacity'		=>1	};

my $shape_array = [	{cx=>"474.862" , cy=>"178.408" , rx=>"9.24547" , ry=>"9.61528"},
					{cx=>"478.93" , cy=>"224.266" , rx=>"8.87565" , ry=>"8.13601"},
					{cx=>"477.081" , cy=>"260.878" , rx=>"9.9851" , ry=>"10.7247"},
					{cx=>"481.519" , cy=>"319.309" , rx=>"11.4644" , ry=>"11.4644"},
					{cx=>"479.3" , cy=>"366.646" , rx=>"10.7247" , ry=>"10.7247"},
					{cx=>"559.181" , cy=>"183.955" , rx=>"9.9851" , ry=>"9.9851"},
					{cx=>"561.03" , cy=>"231.662" , rx=>"9.61528" , ry=>"9.61528"},
					{cx=>"568.796" , cy=>"283.067" , rx=>"12.204" , ry=>"12.204"},
					{cx=>"563.988" , cy=>"332.992" , rx=>"8.13601" , ry=>"8.13601"},
					{cx=>"563.619" , cy=>"375.521" , rx=>"7.76619" , ry=>"7.76619"},
					{cx=>"508.885" , cy=>"270.493" , rx=>"5.54728" , ry=>"5.54728"},
					{cx=>"525.527" , cy=>"266.425" , rx=>"4.43782" , ry=>"4.43782"},
					{cx=>"521.459" , cy=>"278.629" , rx=>"2.58873" , ry=>"2.58873"},
					{cx=>"532.184" , cy=>"276.04" , rx=>"2.21891" , ry=>"2.21891"},
					{cx=>"541.06" , cy=>"268.644" , rx=>"5.9171" , ry=>"5.9171"},
					{cx=>"544.018" , cy=>"283.437" , rx=>"2.95855" , ry=>"2.95855"},
					{cx=>"482.628" , cy=>"285.655" , rx=>"8.13601" , ry=>"8.13601"},
					{cx=>"476.341" , cy=>"338.54" , rx=>"6.28692" , ry=>"6.28692"},
					{cx=>"478.19" , cy=>"202.816" , rx=>"6.65674" , ry=>"6.65674"},
					{cx=>"561.4" , cy=>"207.624" , rx=>"7.76619" , ry=>"7.76619"},
					{cx=>"548.826" , cy=>"199.118" , rx=>"2.58873" , ry=>"2.21891"},
					{cx=>"562.509" , cy=>"255.33" , rx=>"5.9171" , ry=>"5.9171"},
					{cx=>"555.113" , cy=>"269.383" , rx=>"2.21891" , ry=>"2.21891"},
					{cx=>"565.468" , cy=>"313.022" , rx=>"8.13601" , ry=>"8.13601"},
					{cx=>"558.811" , cy=>"300.448" , rx=>"3.69819" , ry=>"3.69819"},
					{cx=>"560.66" , cy=>"351.853" , rx=>"5.54728" , ry=>"5.54728"},
					{cx=>"574.713" , cy=>"349.634" , rx=>"2.58873" , ry=>"2.58873"},
					{cx=>"569.905" , cy=>"358.88" , rx=>"2.21891" , ry=>"2.21891"},
					{cx=>"487.806" , cy=>"347.785" , rx=>"2.21891" , ry=>"2.21891"},
					{cx=>"488.915" , cy=>"337.06" , rx=>"2.58873" , ry=>"2.58873"},
					{cx=>"474.122" , cy=>"299.339" , rx=>"4.80764" , ry=>"4.80764"},
					{cx=>"485.957" , cy=>"303.037" , rx=>"2.58873" , ry=>"2.58873"},
					{cx=>"472.643" , cy=>"275.67" , rx=>"2.58873" , ry=>"2.58873"},
					{cx=>"488.176" , cy=>"272.712" , rx=>"2.58873" , ry=>"2.58873"},
					{cx=>"473.383" , cy=>"237.949" , rx=>"3.32837" , ry=>"3.32837"},
					{cx=>"487.806" , cy=>"239.798" , rx=>"5.17746" , ry=>"5.17746"},
					{cx=>"471.164" , cy=>"191.352" , rx=>"3.32837" , ry=>"3.32837"},
					{cx=>"489.655" , cy=>"192.831" , rx=>"4.06801" , ry=>"4.06801"},
					{cx=>"501.489" , cy=>"285.286" , rx=>"3.32837" , ry=>"3.32837"} ];

#Draw the ellipses for the H
my $ellipse_group = $svg->group(id=>'ellipse_group',transform=>$transform,style=>$style);

foreach my $shape (@{$shape_array}) {
	$svg->ellipse(%$shape,style=>$style);
}

$points = "617.074,364.474 663.435,173 671.162,173 616.371,379 596,327.5 610.751,327.5";

$style = {	'stroke-miterlimit'	=>4,
            'stroke-linejoin'	=>'miter',
            'stroke-width'		=>1,
            'stroke-opacity'	=>1,
            'stroke'			    =>'inherit',
            'fill-opacity'		=>1,
            'fill'				    =>'rgb(0,0,0)',
            'opacity'			    =>1};

my $font_style = {'font-family'=>'Arial','font-size'=>24,'stroke-width'=>'1.2',
              'stroke-opacity'=>0.9,stroke=>'url(#custom-paint)',
              'fill-opacity'=>0.8, fill=>'rgb(0,0,0)',opacity=>0.8};

$svg->polygon(points=>$points,style=>$style);

$svg->anchor(-href => "http://burks.brighton.ac.uk/burks/foldoc/49/60.htm",id=>'a_1');
	my $ytg = $svg->group(id=>'yaph_text_group',style=>$font_style);

		$ytg->text(x=>"441",y=>"302",style=>$font_style,
					transform => 'matrix(0.767738 -0.769086 0.91578 0.644758 80.4565 534.986)'
					)->cdata('Yet Another');

		$ytg->text(x=>441,y=>302,style=>$font_style,
					transform => 'matrix(0.774447 0.760459 0 0.924674 357.792 -428.792)',
					)->cdata('PERL Hack');


my $j_style = {'stroke-miterlimit'=>4,

        'stroke-width'    =>10,
        'stroke-opacity'  =>1,
        'stroke'          =>'url(#red-dark-green)',
        'fill-opacity'    =>0.85,
        'opacity'         =>0.70,
        'font-family'=>'Arial monospaced for SAP',
        'font-size'=>250,
        'stroke'=>'url(#custom-paint_1)',
        'fill'=>'rgb(71,254,130)',};

my $j_trans = 'matrix(1.58041 0.293543 0.333969 1.3891 -396.141 -55.3847)';

$svg->text(id=>'big_J',x=>217,y=>270,style=>$j_style,transform=>$j_trans)->cdata('J');

$path = "M128 130 L202 130";
$style={'stroke-miterlimit'=>4,
        'stroke-linejoin'=>'miter',
        'stroke-linecap'=>'round',
        'stroke-width'=>11,
        'stroke-opacity'=>1,
        'stroke'=>'url(#transparent-sky_1)',
        'fill-opacity'=>1,
        'fill'=>'rgb(0,0,0)',
        'opacity'=>0.5};

$svg->path(d=>$path,style=>$style);

$string = '( Well..., almost )';

$style = {'font-family'=>'Arial monospaced for SAP',
          'font-size'=>32,
          'stroke-width'=>1,
          'stroke-opacity'=>1,
          'stroke'=>'url(#custom-paint_1)',
          'fill-opacity'=>1,
          'fill'=>'rgb(74,214,130)',
          'opacity'=>1};


$svg->text(x=>273,y=>437,style=>$style)->cdata($string);

print $svg->xmlify;

