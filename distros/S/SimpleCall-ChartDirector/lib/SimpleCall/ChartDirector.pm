# ABSTRACT: simple use chart director
package SimpleCall::ChartDirector;

require Exporter;

@ISA    = qw(Exporter);
@EXPORT = qw(
  chart_bar 
  chart_pyramid chart_pie
  chart_spline chart_line
  chart_percentage_bar chart_stacked_bar chart_multi_bar
  chart_percentage_area chart_stacked_area
  chart_scatter
);

use Encode;
use POSIX qw/strtod/;

our $VERSION=0.06;

#需要微软雅黑字体，放到chart_director的fonts目录下
our $CHART_FONT      = 'msyh.ttf';
our $CHART_BOLD_FONT = 'msyhbd.ttf';

#颜色表，支持指定<DATA>中的颜色名，或者16进制值
my @COLOR_HEXCODE = <DATA>;
our %COLOR_HEXCODE = map { chomp; split; } @COLOR_HEXCODE;
our @DEFAULT_COLORLIST = qw/LightBlue1 Green Yellow Red1 Purple 
LightGoldenrod Pink4 LemonChiffon2 LightCoral Salmon3
IndianRed4 Khaki3 Chartreuse2 SeaGreen3 LightCyan3
PaleVioletRed3
/;
our @DEFAULT_DATA_SYMBOL = (
    $perlchartdir::DiamondSymbol,       $perlchartdir::TriangleSymbol,
    $perlchartdir::CircleSymbol,        $perlchartdir::SquareSymbol,
    $perlchartdir::LeftTriangleSymbol,  $perlchartdir::InvertedTriangleSymbol,
    $perlchartdir::RightTriangleSymbol, $perlchartdir::StarSymbol,
    $perlchartdir::PolygonSymbol,       $perlchartdir::Polygon2Symbol,
    $perlchartdir::CrossSymbol,         $perlchartdir::Cross2Symbol,
    $perlchartdir::GlassSphereSymbol,   $perlchartdir::GlassSphere2Symbol,
    $perlchartdir::SolidSphereSymbol,
);
our @DEFAULT_BAR_SHAPE = (
$perlchartdir::SquareShape,
$perlchartdir::DiamondShape,
$perlchartdir::TriangleShape, 
$perlchartdir::RightTriangleShape, 
$perlchartdir::LeftTriangleShape, 
$perlchartdir::InvertedTriangleShape, 
$perlchartdir::CircleShape, 
$perlchartdir::GlassSphereShape, 
$perlchartdir::GlassSphere2Shape, 
$perlchartdir::SolidSphereShape, 
perlchartdir::StarShape(6), # 3 .. 10, 
perlchartdir::PolygonShape(6), #5 .. 6, 
perlchartdir::Polygon2Shape(6), # 5..6
perlchartdir::CrossShape(0.3), # 0.1 .. 0.7
perlchartdir::Cross2Shape(0.3), # 0.1 .. 0.7
);

use perlchartdir;

sub set_data_label {
    my ( $layer, $opt ) = @_;

    if($opt->{with_data_label}){
        ##描点的旁边加上具体数据
        $layer->setDataLabelFormat( $opt->{data_label_format} );

        #画图区域内数据标识的字体
        $layer->setDataLabelStyle( $opt->{data_label_font}, 
            $opt->{data_label_font_size} );
    }

    #总数
    $layer->setAggregateLabelFormat($opt->{data_label_format}) 
        if($opt->{with_aggregate_data_label});
}

sub set_legend {
    my ( $c, $opt ) = @_;

    return unless ( $opt->{with_legend} );

    my $c_legend =
      $c->addLegend( $opt->{legend_pos_x}, $opt->{legend_pos_y},
        $opt->{legend_is_vertical} , 
        $opt->{legend_font}, $opt->{legend_font_size}, 
    );

    #图例背景
    $c_legend->setBackground($perlchartdir::Transparent);

    $c_legend->setText( $opt->{legend_text} ) if ( exists $opt->{legend_text} );

}

sub set_color {
    my ($opt) = @_;

    my $c =
        ( exists $opt->{color} ) ? $opt->{color}
      : ( exists $opt->{label_to_color} )
      ? [ map { $opt->{label_to_color}{$_} } @{ $opt->{label} } ]
      : ( exists $opt->{legend_to_color} )
      ? [ map { $opt->{legend_to_color}{$_} } @{ $opt->{legend} } ]
      : \@DEFAULT_COLORLIST;

    my @color = map { map_color_to_hexcode($_) } @$c;
    return \@color;
} ## end sub specify_label_color

sub set_default_option {
    my ($opt) = @_;
    $opt->{width}             ||= 800;
    $opt->{height}            ||= 330;
    $opt->{plot_area}         ||= [ 75, 70, 700, 200 ];
    $opt->{title_font_size}   ||= 12;
    $opt->{title_font}        ||= $CHART_BOLD_FONT;
    $opt->{default_font}      ||= $CHART_FONT;
    $opt->{default_font_bold} ||= $CHART_BOLD_FONT;
    $opt->{label_font_size}   ||= 10;
    $opt->{label_font}        ||= $CHART_FONT;
    $opt->{legend}            ||= $opt->{label};
    $opt->{legend_font_size}   ||= 10;
    $opt->{legend_font}        ||= $CHART_FONT;
    $opt->{line_width}        ||= 1;

    $opt->{data_label_font_size} ||= 10;
    $opt->{data_label_font}      ||= $CHART_FONT;
    $opt->{data_label_format}    ||= '{value|0}',

      $opt->{y_axis_font_size} ||= 10;
    $opt->{y_axis_font} ||= $CHART_FONT;

    $opt->{x_axis_font_size}    ||= 10;
    $opt->{x_axis_font}         ||= $CHART_FONT;
    $opt->{x_axis_font_color}   ||= $perlchartdir::TextColor,
    $opt->{x_axis_font_angle} ||= 0,

    $opt->{data_symbol} ||= \@DEFAULT_DATA_SYMBOL;
    $opt->{data_symbol_size} ||= 9;

    $opt->{bar_shape} ||= \@DEFAULT_BAR_SHAPE, 

    #层内标签
    $opt->{center_label_format} ||= "{percent}%";

    #层右拉一条线出来，写字
    $opt->{right_label_format} ||= "{label}, {value}";

    #各层间隔高度
    $opt->{layer_gap} ||= 0.01;

    #横坐标，纵坐标，半径
    $opt->{pie_size} ||= [ 450, 290, 180 ];

    #图层内 3d 形状深度
    $opt->{layer_3d_depth} ||= undef, 
}

sub set_axis_mark {

    #X/Y轴划线
    my ( $axis, $mark_list ) = @_;
    for my $r (@$mark_list) {
        my $c = $r->{color};
        my $m = $axis->addMark( $r->{offset}, $c, $r->{info} );
        $m->setLineWidth( $r->{line_width} );
    }
}

sub chart_bar {
    my ( $data, %opt ) = @_;
    set_default_option( \%opt );

    my $c = new XYChart( $opt{width}, $opt{height} );
    $c->setDefaultFonts( $opt{default_font}, $opt{default_font_bold} );
    $c->addTitle( $opt{title}, $opt{title_font}, $opt{title_font_size} );
    $c->setPlotArea( @{ $opt{plot_area} } );

    set_axis_option($c, %opt);

    $c->swapXY() if ( $opt{is_horizontal} );

    my $color = set_color( \%opt );
    my $layer = $c->addBarLayer3( $data, $color );
    $layer->setAggregateLabelFormat($opt{data_label_format}) if($opt{with_data_label});
    $layer->setBorderColor( -1, 1 );

    $c->makeChart( $opt{file} );
    return $opt{file};
} ## end sub draw_pie

sub chart_pyramid {
    my ( $data, %opt ) = @_;
    set_default_option( \%opt );

    my $c = new PyramidChart( $opt{width}, $opt{height} );

    $c->setPyramidSize( @{ $opt{plot_area} } );
    $c->setDefaultFonts( $opt{default_font}, $opt{default_font_bold} );
    $c->addTitle( $opt{title}, $opt{title_font}, $opt{title_font_size} );
    $c->setData( $data, $opt{label} );

    my $color = set_color( \%opt );
    $c->setColors2( $perlchartdir::DataColor, $color );

    $c->setCenterLabel( $opt{center_label_format} );
    $c->setRightLabel( $opt{right_label_format} );
    $c->setLayerGap( $opt{layer_gap} );

    $c->makeChart( $opt{file} );
    return $opt{file};
}


sub map_color_to_hexcode {
    my ($color) = @_;

    $! = 0;
    my ( $num, $unparsed ) = strtod($color);
    my $is_hex = ( ( $unparsed != 0 ) || $! ) ? 0 : 1;

    return $color if ($is_hex);

    return hex( $COLOR_HEXCODE{$color} );
} ## end sub map_color_to_hexcode

sub chart_pie {    #饼图
    my ( $data, %opt ) = @_;
    set_default_option( \%opt );

    my $c = new PieChart( $opt{width}, $opt{height} );
    $c->setPieSize( @{ $opt{pie_size} } );
    $c->setDefaultFonts( $opt{default_font}, $opt{default_font_bold} );

    $c->setLabelFormat( $opt{label_format} );
    $c->setLabelPos( $opt{label_pos}, $perlchartdir::LineColor );
    $c->setLabelStyle( $opt{label_font}, $opt{label_font_size} );

    $c->setLabelLayout($perlchartdir::SideLayout)
      if ( $opt{label_side_layout} );

    $c->setData( $data, $opt{label} );
    my $color = set_color( \%opt );
    $c->setColors2( $perlchartdir::DataColor, $color );

    $c->addTitle( $opt{title}, $opt{title_font}, $opt{title_font_size} );
    $c->setStartAngle( $opt{start_angle} ) if ( exists $opt{start_angle} );

    $c->setRoundedFrame();
    $c->setDropShadow();
    $c->setSectorStyle( $perlchartdir::LocalGradientShading, 0xbb000000, 1 );

    $c->makeChart( $opt{file} );
    return $opt{file};
}

sub chart_spline {
    my ( $data, %opt ) = @_;
    $opt{xy_chart_layer_sub} = sub {
        my ($c) = @_;
        my $layer = $c->addSplineLayer();
        $layer->setMonotonicity($perlchartdir::MonotonicY);
        return $layer;
    };
    chart_xy( $data, %opt );
}

sub chart_line {
    my ( $data, %opt ) = @_;
    $opt{xy_chart_layer_sub} = sub {
        my ($c) = @_;
        my $layer = $c->addLineLayer();
        return $layer;
    };
    chart_xy( $data, %opt );
}


sub chart_percentage_bar {
    my ( $data, %opt ) = @_;
    chart_xy_layer($data, 'bar', $perlchartdir::Percentage, %opt);
}

sub chart_stacked_bar {
    my ( $data, %opt ) = @_;
    chart_xy_layer($data, 'bar', $perlchartdir::Stack, %opt);
}

sub chart_xy_layer {
    my ( $data, $type, $c_layer, %opt ) = @_;
    $opt{xy_chart_layer_sub} = sub {
        my ($c) = @_;
        my $layer;
        if($type eq 'bar'){
            $layer = $c->addBarLayer2( $c_layer, $opt{layer_3d_depth} );
        }elsif($type eq 'area'){
            $layer = $c->addAreaLayer2( $c_layer, $opt{layer_3d_depth} );
        }

        if($opt{with_data_label}){
            $layer->setAggregateLabelStyle();
            $layer->setDataLabelStyle();
        }

        return $layer;
    };
    chart_xy( $data, %opt );
}

sub chart_percentage_area {
    my ( $data, %opt ) = @_;
    #$opt{xy_chart_layer_sub} = sub {
        #my ($c) = @_;
        #my $layer = $c->addAreaLayer2($perlchartdir::Stack, $opt{layer_3d_depth});
        #return $layer;
    #};
    #chart_xy( $data, %opt );
    chart_xy_layer($data, 'area', $perlchartdir::Percentage, %opt);
}

sub chart_stacked_area {
    my ( $data, %opt ) = @_;
    #$opt{xy_chart_layer_sub} = sub {
        #my ($c) = @_;
        #my $layer = $c->addAreaLayer2($perlchartdir::Stack, $opt{layer_3d_depth});
        #return $layer;
    #};
    #chart_xy( $data, %opt );
    chart_xy_layer($data, 'area', $perlchartdir::Stack, %opt);
}

sub chart_multi_bar {
    my ( $data, %opt ) = @_;
    $opt{xy_chart_layer_sub} = sub {
        my ($c) = @_;
        my $layer = $c->addBarLayer2( $perlchartdir::Side, $opt{layer_3d_depth});
        return $layer;
    };
    chart_xy( $data, %opt );
}

sub chart_scatter {
    my ($data, %opt) = @_;
    $opt{xy_chart_layer_sub} = sub {
        my ($c) = @_;
        my $layer_sub = sub {
            my ($r) = @_;
            $c->addScatterLayer($r->{data}[0], $r->{data}[1], 
                $r->{legend}, 
                $r->{data_symbol}, $r->{data_symbol_size}, 
                $r->{color});
        };
        return $layer_sub;
    };
    chart_xy( $data, %opt );
}

sub set_axis_option {
    my ($c, %opt) = @_;

    #x
    set_axis_mark( $c->xAxis(), $opt{x_axis_mark} )
    if ( exists $opt{x_axis_mark} );
    $c->xAxis()->setLabels( $opt{label} );
    $c->xAxis()->setLabelStyle(
        $opt{x_axis_font},       $opt{x_axis_font_size},
        $opt{x_axis_font_color}, $opt{x_axis_font_angle}
    );

    #y
    set_axis_mark( $c->yAxis(), $opt{y_axis_mark} )
    if ( exists $opt{y_axis_mark} );
    $c->yAxis()->setLabelFormat( $opt{y_label_format} )
    if ( exists $opt{y_label_format} );
    $c->yAxis()->setLabelStyle( $opt{y_axis_font}, $opt{y_axis_font_size} );
    $c->yAxis()->setTickDensity( $opt{y_tick_density} )
    if ( exists $opt{y_tick_density} );
    $c->yAxis()
    ->setDateScale( $opt{y_axis_lower_limit}, $opt{y_axis_upper_limit} )
    if (  exists $opt{y_axis_lower_limit}
            and exists $opt{y_axis_upper_limit} );

}

sub chart_xy {    # XY型chart 基础函数
    my ( $data, %opt ) = @_;
    set_default_option( \%opt );

    my $c = new XYChart( $opt{width}, $opt{height} );
    $c->setPlotArea( @{ $opt{plot_area} } );
    $c->addTitle( $opt{title}, $opt{title_font}, $opt{title_font_size} );


    #x/y 轴
    set_axis_option($c, %opt);

    $c->swapXY() if ( $opt{is_horizontal} );

    #画什么样的图
    my $color = set_color( \%opt );


    my $layer = $opt{xy_chart_layer_sub}->($c);
    if(ref($layer) eq 'CODE'){
        for ( my $i = 0 ; $i <= $#$data ; $i++ ) {
            my $d = $data->[$i];
            $layer->({
                    data=> $d, 
                    color => $color->[$i], 
                    legend => $opt{legend}[$i], 
                    data_symbol => $opt{data_symbol}[$i], 
                    data_symbol_size => $opt{data_symbol_size}, 
                    with_data_symbol => $opt{with_data_symbol}, 
                });
        }
        #$c->addScatterLayer($dataX0, $dataY0, "Genetically Engineered", $perlchartdir::DiamondSymbol, 13, 0xff9933);
    }else{
        $layer->setLineWidth( $opt{line_width} );
        set_data_label( $layer, \%opt );
        for ( my $i = 0 ; $i <= $#$data ; $i++ ) {
            my $d = $data->[$i];
            $_ ||= 0 for @$d;
            my $temp = $layer->addDataSet( $d, $color->[$i], $opt{legend}[$i] );
            $temp->setDataSymbol( $opt{data_symbol}[$i], $opt{data_symbol_size} ) if($opt{with_data_symbol});
            $layer->setBarShape($opt{bar_shape}[$i], $i) if($opt{with_bar_shape});
        } ## end for ( my $i = 0; $i <= ...)
    }


    set_legend( $c, \%opt );
    $c->makeChart( $opt{file} );
    return $opt{file};
} ## end sub draw_xy_chart

1;
__DATA__
Black 000000
Gray0 150517
Gray18 250517
Gray21 2b1b17
Gray23 302217
Gray24 302226
Gray25 342826
Gray26 34282c
Gray27 382d2c
Gray28 3b3131
Gray29 3e3535
Gray30 413839
Gray31 41383c
Gray32 463e3f
Gray34 4a4344
Gray35 4c4646
Gray36 4e4848
Gray37 504a4b
Gray38 544e4f
Gray39 565051
Gray40 595454
Gray41 5c5858
Gray42 5f5a59
Gray43 625d5d
Gray44 646060
Gray45 666362
Gray46 696565
Gray47 6d6968
Gray48 6e6a6b
Gray49 726e6d
Gray50 747170
Gray 736f6e
SlateGray4 616d7e
SlateGray 657383
LightSteelBlue4 646d7e
LightSlateGray 6d7b8d
CadetBlue4 4c787e
DarkSlateGray4 4c7d7e
Thistle4 806d7e
MediumSlateBlue 5e5a80
MediumPurple4 4e387e
MidnightBlue 151b54
DarkSlateBlue 2b3856
DarkSlateGray 25383c
DimGray 463e41
CornflowerBlue 151b8d
RoyalBlue4 15317e
SlateBlue4 342d7e
RoyalBlue 2b60de
RoyalBlue1 306eff
RoyalBlue2 2b65ec
RoyalBlue3 2554c7
DeepSkyBlue 3bb9ff
DeepSkyBlue2 38acec
SlateBlue 357ec7
DeepSkyBlue3 3090c7
DeepSkyBlue4 25587e
DodgerBlue 1589ff
DodgerBlue2 157dec
DodgerBlue3 1569c7
DodgerBlue4 153e7e
SteelBlue4 2b547e
SteelBlue 4863a0
SlateBlue2 6960ec
Violet 8d38c9
MediumPurple3 7a5dc7
MediumPurple 8467d7
MediumPurple2 9172ec
MediumPurple1 9e7bff
LightSteelBlue 728fce
SteelBlue3 488ac7
SteelBlue2 56a5ec
SteelBlue1 5cb3ff
SkyBlue3 659ec7
SkyBlue4 41627e
SlateBlue 737ca1
SlateBlue 737ca1
SlateGray3 98afc7
VioletRed f6358a
VioletRed1 f6358a
VioletRed2 e4317f
DeepPink f52887
DeepPink2 e4287c
DeepPink3 c12267
DeepPink4 7d053f
MediumVioletRed ca226b
VioletRed3 c12869
Firebrick 800517
VioletRed4 7d0541
Maroon4 7d0552
Maroon 810541
Maroon3 c12283
Maroon2 e3319d
Maroon1 f535aa
Magenta ff00ff
Magenta1 f433ff
Magenta2 e238ec
Magenta3 c031c7
MediumOrchid b048b5
MediumOrchid1 d462ff
MediumOrchid2 c45aec
MediumOrchid3 a74ac7
MediumOrchid4 6a287e
Purple 8e35ef
Purple1 893bff
Purple2 7f38ec
Purple3 6c2dc7
Purple4 461b7e
DarkOrchid4 571b7E
DarkOrchid 7d1b7e
DarkViolet 842dce
DarkOrchid3 8b31c7
DarkOrchid2 a23bec
DarkOrchid1 b041ff
Plum4 7e587e
PaleVioletRed d16587
PaleVioletRed1 f778a1
PaleVioletRed2 e56e94
PaleVioletRed3 c25a7c
PaleVioletRed4 7e354d
Plum b93b8f
Plum1 f9b7ff
Plum2 e6a9ec
Plum3 c38ec7
Thistle d2b9d3
Thistle3 c6aec7
LavenderBlush2 ebdde2
LavenderBlush3 c8bbbe
Thistle2 e9cfec
Thistle1 fcdfff
Lavender e3e4fa
LavenderBlush fdeef4
LightSteelBlue1 c6deff
LightBlue addfff
LightBlue1 bdedff
LightCyan e0ffff
SlateGray1 c2dfff
SlateGray2 b4cfec
LightSteelBlue2 b7ceec
Turquoise1 52f3ff
Cyan 00ffff
Cyan1 57feff
Cyan2 50ebec
Turquoise2 4ee2ec
MediumTurquoise 48cccd
Turquoise 43c6db
DarkSlateGray1 9afeff
DarkSlateGray2 8eebec
DarkSlateGray3 78C7C7
Cyan3 46c7c7
Turquoise3 43bfc7
CadetBlue3 77bfc7
PaleTurquoise3 92c7c7
LightBlue2 afdcec
DarkTurquoise 3b9c9c
Cyan4 307d7e
LightSeaGreen 3ea99f
LightSkyBlue 82cafa
LightSkyBlue2 a0cfec
LightSkyBlue3 87afc7
SkyBlue 82caff
SkyBlue2 79baec
LightSkyBlue4 566d7e
SkyBlue 6698ff
LightSlateBlue 736aff
LightCyan2 cfecec
LightCyan3 afc7c7
LightCyan4 717d7d
LightBlue3 95b9c7
LightBlue4 5e767e
PaleTurquoise4 5e7d7e
DarkSeaGreen4 617c58
MediumAquamarine 348781
MediumSeaGreen 306754
SeaGreen 4e8975
DarkGreen 254117
SeaGreen4 387c44
ForestGreen 4e9258
MediumForestGreen 347235
SpringGreen4 347c2c
DarkOliveGreen4 667c26
Chartreuse4 437c17
Green4 347c17
MediumSpringGreen 348017
SpringGreen 4aa02c
LimeGreen 41a317
SpringGreen 4aa02c
DarkSeaGreen 8bb381
DarkSeaGreen3 99c68e
Green3 4cc417
Chartreuse3 6cc417
YellowGreen 52d017
SpringGreen3 4cc552
SeaGreen3 54c571
SpringGreen2 57e964
SpringGreen1 5efb6e
SeaGreen2 64e986
SeaGreen1 6afb92
DarkSeaGreen2 b5eaaa
DarkSeaGreen1 c3fdb8
Green 00ff00
LawnGreen 87f717
Green1 5ffb17
Green2 59e817
Chartreuse2 7fe817
Chartreuse 8afb17
GreenYellow b1fb17
DarkOliveGreen1 ccfb5d
DarkOliveGreen2 bce954
DarkOliveGreen3 a0c544
Yellow ffff00
Yellow1 fffc17
Khaki1 fff380
Khaki2 ede275
Goldenrod edda74
Gold2 eac117
Gold1 fdd017
Goldenrod1 fbb917
Goldenrod2 e9ab17
Gold d4a017
Gold3 c7a317
Goldenrod3 c68e17
DarkGoldenrod af7817
Khaki ada96e
Khaki3 c9be62
Khaki4 827839
DarkGoldenrod1 fbb117
DarkGoldenrod2 e8a317
DarkGoldenrod3 c58917
Sienna1 f87431
Sienna2 e66c2c
DarkOrange f88017
DarkOrange1 f87217
DarkOrange2 e56717
DarkOrange3 c35617
Sienna3 c35817
Sienna 8a4117
Sienna4 7e3517
IndianRed4 7e2217
DarkOrange3 7e3117
Salmon4 7e3817
DarkGoldenrod4 7f5217
Gold4 806517
Goldenrod4 805817
LightSalmon4 7f462c
Chocolate c85a17
Coral3 c34a2c
Coral2 e55b3c
Coral f76541
DarkSalmon e18b6b
Salmon1 f88158
Salmon2 e67451
Salmon3 c36241
LightSalmon3 c47451
LightSalmon2 e78a61
LightSalmon f9966b
SandyBrown ee9a4d
HotPink f660ab
HotPink1 f665ab
HotPink2 e45e9d
HotPink3 c25283
HotPink4 7d2252
LightCoral e77471
IndianRed1 f75d59
IndianRed2 e55451
IndianRed3 c24641
Red ff0000
Red1 f62217
Red2 e41b17
Firebrick1 f62817
Firebrick2 e42217
Firebrick3 c11b17
Pink faafbe
RosyBrown1 fbbbb9
RosyBrown2 e8adaa
Pink2 e7a1b0
LightPink faafba
LightPink1 f9a7b0
LightPink2 e799a3
Pink3 c48793
RosyBrown3 c5908e
RosyBrown b38481
LightPink3 c48189
RosyBrown4 7f5a58
LightPink4 7f4e52
Pink4 7f525d
LavenderBlush4 817679
LightGoldenrod4 817339
LemonChiffon4 827b60
LemonChiffon3 c9c299
LightGoldenrod3 c8b560
LightGolden2 ecd672
LightGoldenrod ecd872
LightGoldenrod1 ffe87c
LemonChiffon2 ece5b6
LemonChiffon fff8c6
LightGoldenrodYellow faf8cc
