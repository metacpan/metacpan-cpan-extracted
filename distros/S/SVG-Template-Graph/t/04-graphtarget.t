# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Template-Graph-SVG.t'

#########################
use Test::More tests => 14;
use SVG::Template::Graph;
#########################
my $outfile = "/tmp/".rand(100000000).".svg";

# defin a 1-trace drawing structure
my $data = 
[
	{

        'title'=> '1: Trace 1',
        'data' => #hash ref containing x-val and y-val array refs
                {
                'x_val' =>
                        [-5, 2, 4, 6, 8, 10,12,14,16,18,20],
                'y_val' =>
                        [-4, 2, 5, 3, 7, 4 , 9, 9, 2, 4, 3],
                },
        'format' =>
                { #note that these values could change for *each* trace
                'x_max' =>      20, #or for your case, the date value of the 1st point
                'x_min' =>      -10, #or for your case, the date value of the last point
                'y_max' =>      10,
                'y_min' =>      -10,
                'x_title' =>    'Calendar Year',
                'y_title' =>    '% Annual Performance',

                #define the labels that provide the data context.

                'labels' =>
                        {
                        #for year labels, we have to center the axis markers
                        'x_ticks' =>
                                {
                                'label'         =>[2001,2002,2003,2005],
                                'position'      =>[100,200,300,500],
                                },
                        'y_ticks' =>
                                {
                                #tick mark labels
                                'label' => [ 
					'-10.00', 
					'-5.00', 
					'0.00', 
					'5.00', 
					'10.00', 
					'15.00', 
					'20.00', 
					'25.00', 
					'30.00', 
					'35.00' 
					],
				'units'=>'%',
                                #tick mark location in the data space
                                'position' => [-0.10,-0.5,0,-.5,.10,.15,.20,.25,.30,.35],
                                },
                        },
                },
	},
];


###################################################


my $tt;
my $svg;
my $out;
ok(scalar @{$data->[0]->{data}->{x_val}} == scalar @{$data->[0]->{data}->{y_val}},'Source data arrays match lengths');
my $file = 't/template1.svg';
ok(-r $file,'test template file exists'); 
ok($tt = SVG::Template::Graph->new($file),'load SVG::Template::Graph object');
ok($tt->setGraphTarget('rectangle.graph.data.space','rect', width=>100,height=>100,x=>10,y=>10),'set graph target');
ok($tt->setGraphTitle(['Hello svg graphing world','I am a subtitle']),'set graph title');
ok($tt->setYAxisTitle(1,['I am Y-axis One','Subtitle - % of total length']),'set graph title');
ok($tt->setYAxisTitle(2,['I am Y-axis Two','More text lives here']),'set Y Axis title 2');
ok($tt->setXAxisTitle(1,['I am X-axis One','Subtitle - % of total length']),'set X Axis title');
ok($tt->setTraceTitle(1,'I am trace one'),'set Trace 1 title');
ok($tt->setXAxisTitle(2,'I am X-axis Two'),'set X axis two title');
ok($out = $tt->burn(-elsep=>'',-indent=>''),'serialise');
ok(1==1,'generated one line');
ok($out =~ /Hello\ssvg\sgraphing\sworld/gs,'check that graph title showed up in output');
ok($out =~ /rectangle\.graph\.data\.space/gs,'graph target shows up in output');
open OUT,"> $outfile";
print OUT $out;
close OUT;
unlink $outfile;
