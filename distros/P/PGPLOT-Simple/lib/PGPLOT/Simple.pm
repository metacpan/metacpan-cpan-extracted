package PGPLOT::Simple;

use 5.008000;
use strict;
use warnings;

use Exporter qw/import/;

use PGPLOT;
use Carp qw/croak/;
use List::Util qw/min max/;
use List::MoreUtils qw/any none/;
use Scalar::Util qw/looks_like_number/;

our %EXPORT_TAGS = (
    'essential' => [qw(
        set_begin           set_end         set_environment        
        set_viewport        set_window      set_box
        set_active_panel    set_range   
        
        write_label         write_text      write_text_viewport
        
        draw_points         draw_line       draw_polyline
        draw_polygon        draw_rectangle  draw_circle
        draw_arrow          draw_error_bars draw_function
        draw_histogram
        
        move_pen      
    )],
    'optional'  =>  [qw(
        set_color               set_color_representation    set_line_width
        set_line_style          set_character_height        set_font
        set_text_background     set_fill_area_style         set_hatching_style
        set_arrow_style

    )],
    'pgplot'    =>  [ @PGPLOT::EXPORT ],
);

our @EXPORT_OK = ();
our @EXPORT = ();

Exporter::export_ok_tags('essential');
Exporter::export_ok_tags('optional');
Exporter::export_ok_tags('pgplot');

our $VERSION = '0.05';


my $ATTR2SUB = {
    font            => \&set_font,
    color           => \&set_color,
    width           => \&set_line_width,
    style           => \&set_line_style,
    fill            => \&set_fill_area_style,
    height          => \&set_character_height,
    background      => \&set_text_background,
    arrow_style     => \&set_arrow_style,
    hatching_style  => \&set_hatching_style,
};

my $PALLETE = {
    Background      =>  0,   
    Foreground      =>  1,
    Red             =>  2,
    Green           =>  3,
    Blue            =>  4,
    Cyan            =>  5,
    Magenta         =>  6,
    Yellow          =>  7,
    Orange          =>  8,
    GreenYellow     =>  9,
    GreenCyan       => 10,
    BlueCyan        => 11,
    BlueMagenta     => 12,
    RedMagenta      => 13,
    DarkGray        => 14,
    LightGray       => 15,
};

my $FONT = {
    Normal          => 1,
    Roman           => 2,
    Italic          => 3,
    Script          => 4,
};

my $LINE_STYLE = {
    FullLine        => 1,
    Dashed          => 2,
    DotDashDotDash  => 3,
    Dotted          => 4,
    DashDotDotDot   => 5,
};

my $TEXT_ALIGN = {
    Left            => 0.0,
    Center          => 0.5,
    Right           => 1.0,
};

my $FILL_AREA_STYLE = {
    Solid           => 1,
    Outline         => 2,
    Hatched         => 3,
    CrossHatched    => 4,
};

my $BOX_STYLE = {
    Clean            => -2,
    Box              => -1,
    BoxCoord         =>  0,
    BoxCoordAxes     =>  1,
    BoxCoordAxesGrid =>  2,
    BoxXLog          => 10,
    BoxYLog          => 20,
    BoxXYLog         => 30,
};

my $ARROW_STYLE = {
    Filled           => 1,
    Outline          => 2,
};


###############################################################
# OPEN, CLOSING, AND SELECTING DEVICES
###############################################################


# Open a graphics device
sub set_begin {
    my $args = shift;

    my $file  = exists $args->{'file'} ? $args->{'file'} : "-/CPS";
    # The device specification for the plot device
    my $nxsub = exists $args->{'num_x_sub'} ? $args->{'num_x_sub'} : 1;
    my $nysub = exists $args->{'num_y_sub'} ? $args->{'num_y_sub'} : 1;
    # Number of X and Y subdivisions of the view surface
    my $unit  = 0;   # This is ignored by the library
    
    my $status = pgbeg( $unit, $file, $nxsub, $nysub );

    return $status;
}

# Closes all graphics devices
sub set_end {
    pgend;
    return;
}

sub set_environment {
    my $args = shift;

    croak "x_min, x_max, y_min, y_max parameters are required."
        if any {! exists $args->{$_} } qw/x_min x_max y_min y_max/;

    my $x_min = $args->{'x_min'};
    my $x_max = $args->{'x_max'};

    my $y_min = $args->{'y_min'};
    my $y_max = $args->{'y_max'};

    my $justify = 0;
    # Default don't justify the axes together
    if ( exists $args->{'justify'}  &&  $args->{'justify'} ne 0 ) {
        $justify = 1;
    }

    my $axes = $BOX_STYLE->{'BoxCoordAxes'};
    # Default draw box and label it with coordinates and draw the coordinate axes
    if ( exists $args->{'axes'} ) {
        my $id = $args->{'axes'};
        
        if ( exists $BOX_STYLE->{ $id } ) {
            $axes = $BOX_STYLE->{ $id };
            # If the user provided a valid axes key
        }
        elsif ( looks_like_number $id  &&  any { $id == $_ } (-2,-1,0,1,2,10,20,30) ) {
            $axes = $id;
            # If the user provided directly the axes code
        }
        else {
            croak "Wrong axes parameter supplied.";
        }
    }

    pgsave; # Save current attributes

    set_attributes( $args );    # Design settings

    pgenv( $x_min, $x_max, $y_min, $y_max, $justify, $axes );

    pgunsa; # Restore previous attributes

    return;
}


###############################################################
# WINDOWS AND VIEWPORTS
###############################################################


# Set viewport
sub set_viewport {
    my $args = shift;

    croak "x_left, x_right, y_bot, y_top parameters are required."
        if any {! exists $args->{$_} } qw/x_left x_right y_bot y_top/;

    croak "Must provide a value between 0 and 1."
        if any { !( 
                    looks_like_number $args->{$_}
                    && $args->{$_} >= 0
                    && $args->{$_} <= 1
                  )
               } qw/x_left x_right y_bot y_top/;

    my $x_left = $args->{'x_left'};
    my $x_right = $args->{'x_right'};

    my $y_bot = $args->{'y_bot'};
    my $y_top = $args->{'y_top'};

    pgsvp( $x_left, $x_right, $y_bot, $y_top );

    return;
}

# Set window
sub set_window {
    my $args = shift;

    croak "x_min, x_max, y_min, y_max parameters are required."
        if any {! exists $args->{$_} } qw/x_min x_max y_min y_max/;

    my $x_min = $args->{'x_min'};
    my $x_max = $args->{'x_max'};

    my $y_min = $args->{'y_min'};
    my $y_max = $args->{'y_max'};

    pgswin( $x_min, $x_max, $y_min, $y_max );

    return;
}

# Switch to a different panel on the view surface
sub set_active_panel {
    my $args = shift;
    
    croak "x_index and y_index parameters are required."
        if any {! exists $args->{$_} } qw/x_index y_index/;

    my $ix = $args->{'x_index'};
    my $iy = $args->{'y_index'};

    pgpanl( $ix, $iy );

    return;
}

# Choose axis limits
sub set_range {
    my $args = shift;
    
    croak "x1, x2, x_low and x_high parameters are required."
        if any{! exists $args->{$_} } qw/x1 x2 x_low x_high/;

    my $x1   = $args->{'x1'};
    my $x2   = $args->{'x2'};
    
    my $x_lo = $args->{'x_low' };
    my $x_hi = $args->{'x_high'};

    pgrnge($x1, $x2, $x_lo, $x_hi );
        
    return;
}


###############################################################
# AXES, BOXES AND LABELS
###############################################################


# Draw frame and write (DD) HH MM SS.S labelling
sub set_box {
    my $args = shift;

    my $x_opt   = exists $args->{'x_style'} ? $args->{'x_style'} : 'ABCGZHON';
    my $y_opt   = exists $args->{'y_style'} ? $args->{'y_style'} : 'ABCGN';

    my $x_tick  = exists $args->{'x_tick'}  ? $args->{'x_tick'}  : 0.0;
    my $y_tick  = exists $args->{'y_tick'}  ? $args->{'y_tick'}  : 0.0;

    my $n_x_sub = exists $args->{'n_x_sub'} ? $args->{'n_x_sub'} : 0;
    my $n_y_sub = exists $args->{'n_y_sub'} ? $args->{'n_y_sub'} : 0;

    pgsave; # Save current attributes

    set_attributes( $args );    # Design settings

    pgtbox( $x_opt, $x_tick, $n_x_sub, $y_opt, $y_tick, $n_y_sub );

    pgunsa; # Restore previous attributes

    return;
}

# Write labels for x-axis, y-axis, and top of plot
sub write_label {
    my $args = shift;

    my $x     = exists $args->{'x'}     ? $args->{'x'}     : 'X';
    my $y     = exists $args->{'y'}     ? $args->{'y'}     : 'Y';
    my $title = exists $args->{'title'} ? $args->{'title'} : 'Untitled';

    pgsave; # Save current attributes

    set_attributes( $args );    # Design settings

    pglab( $x, $y, $title );

    pgunsa; # Restore previous attributes

    return;
}

sub write_text_viewport {
    my $args = shift;

    croak "Must provide a string to write."
        unless exists $args->{'string'};
        
    my $text = $args->{'string'};
    my $side  = exists $args->{'side'}     ? $args->{'side'}     : 'BR';
    # Default to bottom right positioned
    my $disp  = exists $args->{'displace'} ? $args->{'displace'} :    1;
    # Default displacement relative to the viewport
    my $coord = exists $args->{'coord'}    ? $args->{'coord'}    :    1;
    # Default location of the character string along the specified edge of the viewport
    my $fjust = get_align( $args->{'justify'} );

    pgsave; # Save current attributes

    set_attributes( $args );    # Design settings

    pgmtxt( $side, $disp, $coord, $fjust, $text );
    
    pgunsa; # Restore previous attributes

    return;
}


###############################################################
# PRIMITIVES
###############################################################


# LINES
# 

# Draw a polyline (curve defined by line-segments)
sub draw_polyline {
    my $args = shift;

    croak "x and y parameters are required."
        if any {! exists $args->{$_} } qw/x y/;

    my $x = $args->{'x'};
    my $y = $args->{'y'};

    pgsave; # Save current attributes

    set_attributes( $args );    # Design settings

    # Line size
    my $size = scalar @$x;

    pgline( $size, $x, $y );

    pgunsa; # Restore previous attributes

    return;
}

# Move pen (change current pen position)
sub move_pen {
    my $args = shift;

    my ($x, $y) = ();

    if ( exists $args->{'x'}  &&  exists $args->{'y'} ) {
        $x = $args->{'x'};
        $y = $args->{'y'};

        pgmove( $x, $y );   # Move pen to position
    }

    pgqpos( $x, $y );   # Return current pen position

    return ($x, $y);
}

# Draw a line from the current pen position to a point
sub draw_line {
    my $args = shift;

    croak "x and y parameters are required."
        if any {! exists $args->{$_} } qw/x y/;
    
    my $x = $args->{'x'};
    my $y = $args->{'y'};

    pgsave; # Save current attributes

    set_attributes( $args );    # Design settings

    pgdraw( $x, $y );

    pgunsa; # Restore previous attributes

    return;
}

# POLYGONS AND FILLED AREAS
# 

# Draw a polygon, using fill-area attributes
sub draw_polygon {
    my $args = shift;

    croak "x and y parameters are required."
        if any {! exists $args->{$_} } qw/x y/;

    my $x = $args->{'x'};
    my $y = $args->{'y'};

    pgsave; # Save current attributes

    set_attributes( $args );    # Design settings

    # Number of points
    my $num = scalar @$x;

    pgpoly( $num, $x, $y );

    pgunsa; # Restore previous attributes

    return;
}

# Draw a circle, using fill-area attributes
sub draw_circle {
    my $args = shift;

    croak "x, y and radius parameters are required."
        if any {! exists $args->{$_} } qw/x y radius/;

    my $x = $args->{'x'};
    my $y = $args->{'y'};
    my $radius = $args->{'radius'};

    pgsave; # Save current attributes

    set_attributes( $args );    # Design settings

    pgcirc( $x, $y, $radius );

    pgunsa; # Restore previous attributes

    return;
}

# Draw a rectangle, using fill-area attibutes
sub draw_rectangle {
    my $args = shift;

    croak "x1,y1,x2 and y2 parameters are required."
        if any {! exists $args->{$_} } qw/x1 x2 y1 y2/;

    my $x1 = $args->{'x1'};
    my $x2 = $args->{'x2'};
    my $y1 = $args->{'y1'};
    my $y2 = $args->{'y2'};

    pgsave; # Save current attributes

    set_attributes( $args );    # Design settings

    pgrect( $x1, $x2, $y1, $y2 );

    pgunsa; # Restore previous attributes

    return;
}


# GRAPH MARKERS
#

# Draw several graph markers.
sub draw_points {
    my $args = shift;

    croak "x, and y parameters are required."
        if any {! exists $args->{$_} } qw/x y/;

    my $x = $args->{'x'};
    my $y = $args->{'y'};
    my $symbol = exists $args->{'symbol'} ? $args->{'symbol'} : -1;

    pgsave; # Save current attributes

    set_attributes( $args );    # Design settings

    # How many
    my $num = scalar @$x;

    pgpt( $num, $x, $y, $symbol );

    pgunsa; # Restore previous attributes

    return;
}


# TEXT
# 

# Write text at arbitrary position and angle
sub write_text {
    my $args = shift;

    croak "x,y and string parameters are required."
        if any {! exists $args->{$_} } qw/x y string/;

    my $x = $args->{'x'};
    my $y = $args->{'y'};
    my $string = $args->{'string'};

    my $align = get_align( $args->{'align'} );
    my $angle = get_angle( $args->{'angle'} );

    pgsave; # Save current attributes

    set_attributes( $args );    # Design settings

    pgptxt( $x, $y, $angle, $align, $string );

    pgunsa; # Restore previous attributes
    
    return;
}


# ARROWS
#

sub draw_arrow {
    my $args = shift;

    croak "x1,y1,x2 and y2 parameters are required."
        if any {! exists $args->{$_} } qw/x1 x2 y1 y2/;

    my $x1 = $args->{'x1'};
    my $x2 = $args->{'x2'};
    my $y1 = $args->{'y1'};
    my $y2 = $args->{'y2'};

    pgsave; # Save current attributes

    set_attributes( $args );    # Design settings

    pgarro( $x1, $y1, $x2, $y2 );

    pgunsa; # Restore previous attributes

    return;
}


###############################################################
# ATTRIBUTES
###############################################################


sub set_attributes {
    my $args = shift;

    for my $attr ( keys %$ATTR2SUB ) {
        if ( exists $args->{ $attr } ) {
             &{ $ATTR2SUB->{ $attr } }( $args->{ $attr } ); 
        }
    }

    return;
}


# COLOR
#

sub set_color {
    my $id = shift;
    
    my $color = $PALLETE->{'Foreground'}; # Default color

    if (defined $id) {
        if ( exists $PALLETE->{ $id } ) {
            $color = $PALLETE->{ $id };
            # If the user provided a valid color key
        }
        elsif ( looks_like_number $id  &&  $id >= 0  &&  $id <= 255 ) {
            $color = $id;
            # If the user provided directly the color code
        }
        else {
            croak "Must provide a valid color.";
        }
    }

    pgsci( $color ); # PGPLOT call setting color 
        
    return;
}

sub set_color_representation {
    my $args = shift;

    croak "code, red, green and blue parameters are required."
        if any { !( 
                    looks_like_number $args->{$_}
                    &&  exists $args->{$_}
                  ) 
               } qw/code red green blue/;

    my $code = $args->{'code'};
    my $red = $args->{'red'};
    my $green = $args->{'green'};
    my $blue = $args->{'blue'};

    # Data range validation
    croak "Code index value out of range"
        unless ( $code >= 0  &&  $code <= 255 );

    croak "Any of the rgb values supplied is out of range."
        if any { !( $_ >= 0  &&  $_ <= 1 ) }
            ($red, $green, $blue);

    pgscr( $code, $red, $green, $blue );

    return;
}


# LINE ATTRIBUTES
#

sub set_line_width {
    my $num = shift;

    my $width = 2;  # Default width

    if ( defined $num ) {
        if ( looks_like_number $num  &&  $num >= 1  &&  $num <= 201 ) {
            $width = $num;
        }
        else {
            croak "Must provide a valid integer number for line width.";
        }
    }

    pgslw( $width );   # PGPLOT call setting line width

    return;
}

sub set_line_style {
    my $id = shift;

    my $style = $LINE_STYLE->{'Solid'}; # Default style
    
    if (defined $id) {
        if ( exists $LINE_STYLE->{ $id } ) {
            $style = $LINE_STYLE->{ $id };        
            # If the user provided a valid line style
        }
        elsif ( looks_like_number $id  &&  $id >= 1  &&  $id <= 5 ) {
            $style = $id;
            # If the user provided directly the style code
        }
        else {
            croak "Must provide a valid style.";
        }
    }

    pgsls( $style ); # PGPLOT call setting line style 
        
    return;
}


# TEXT AND MARKER ATTRIBUTES
#

sub set_character_height {
    my $value = shift;

    my $height = 1.0;    # Default height

    if (defined $value) {
        if ( looks_like_number $value ) {
            $height = $value;
        }
        else {
            croak "Must provide a real number for character height.";
        }
    }

    pgsch( $height );   # PGPLOT call setting line height

    return;
}

sub set_font {
    my $id = shift;

    my $font = $FONT->{'Normal'};   # Default font

    if (defined $id) {
        if ( exists $FONT->{ $id } ) {
            $font = $FONT->{ $id };
            # If the user provided a valid font type
        }
        elsif ( looks_like_number $id  &&  $id >= 1  &&  $id <= 4 ) {
            $font = $id;
            # If the user provided directly the font type
        }
        else {
            croak "Must provide a valid font.";
        }
    }

    pgscf( $font );     # PGPLOT call setting font type

    return;
}

sub set_text_background {
    my $id = shift;
    
    my $color = -1; # Default transparent color

    if (defined $id) {
        if ( exists $PALLETE->{ $id } ) {
            $color = $PALLETE->{ $id };
            # If the user provided a valid color key
        }
        elsif ( looks_like_number $id  &&  $id >= -1  &&  $id <= 255 ) {
            $color = $id;
            # If the user provided directly the color code
        }
        else {
            croak "Must provide a valid color.";
        }
    }

    pgstbg( $color ); # PGPLOT call setting text background color 
        
    return;
}


# FILL-AREA ATTRIBUTES
# 

sub set_fill_area_style {
    my $id = shift;

    my $style = $FILL_AREA_STYLE->{'Solid'};  # Default text alignment

    if (defined $id) {
        if ( exists $FILL_AREA_STYLE->{ $id } ) {
            $style = $FILL_AREA_STYLE->{ $id };
            # If the user provided a valid fill style
        }
        elsif ( looks_like_number $id  &&  $id >= 1  &&  $id <= 4 ) {
            $style = $id;
            # If the user provided directly the fill style
        }
        else {
            croak "Must provide a valid fill style.";
        }
    }

    pgsfs( $style );

    return;
}

sub set_hatching_style {
    my $args = shift;

    my $angle = 45.0;
    my $sepn  =  1.0;
    my $phase  =  0.0;
    # Default values

    if ( exists $args->{'angle'} ) {
        my $value = $args->{'angle'};
        if ( looks_like_number $value  &&  $value >= 0  &&  $value <= 360 ) {
            $angle = $value;
        }
        else {
            croak "Must provide a valid angle value.";
        }
    }
    if ( exists $args->{'spacing'} ) {
        my $value = $args->{'spacing'};
        if ( looks_like_number $value  &&  $value >= 0  &&  $value <= 100 ) {
            $sepn = $value;
        }
        else {
            croak "Must provide a valid spacing value.";
        }
    }
    if ( exists $args->{'phase'} ) {
        my $value = $args->{'phase'};
        if ( looks_like_number $value  &&  $value >= 0  &&  $value <= 1 ) {
            $phase = $value;
        }
        else {
            croak "Must provide a valid phase value.";
        }
    }

    pgshs( $angle, $sepn, $phase );

    return;
}


# ARROW ATTRIBUTES
#

sub set_arrow_style {
    my $args = shift;

    my $fs    = $ARROW_STYLE->{'Filled'};
    my $angle =  45;
    my $barb  = 0.3;

    if( exists $args->{'fill'} ) {
        my $id = $args->{'fill'};
        if( exists $ARROW_STYLE->{ $id } ) {
            $fs = $ARROW_STYLE->{ $id };
            # If the user provided a valid fill style
        }
        elsif ( looks_like_number $id  &&  $id >= 1  &&  $id <= 2 ) {
            $fs = $id;
            # If the user provided directly the fill style
        }
        else {
            croak "Must provide a valid fill style.";
        }
    }
    if( exists $args->{'arrow_angle'} ) {
        my $value = $args->{'arrow_angle'};
        if ( looks_like_number $value  &&  $value >= 0  &&  $value <= 360 ) {
            my $angle = $value;
        }
        else {
            croak "Must provide a valid arrow angle";
        }
    }
    if( exists $args->{'arrow_barb'} ) {
        my $value = $args->{'arrow_barb'};
        if ( looks_like_number $value  &&  $value >= 0  &&  $value <= 1 ) {
            my $angle = $value;
        }
        else {
            croak "Must provide a valid arrow barb";
        }
    }

    pgsah( $fs, $angle, $barb );

    return;
}


###############################################################
# XY PLOTS
###############################################################


# ERROR BARS
#

# Horizontal / Vertical error bars
sub draw_error_bars {
    my $args = shift;

    croak "Must provide either (x1,x2,y) or (y1,y2,x) parameters."
        if none { exists $args->{$_} } qw/x y/;

    # Error bars terminal, undef mean proportional of the length of the bar

    pgsave; # Save current attributes

    set_attributes( $args );    # Design settings

    if( exists $args->{'y'} ) {
        croak "x1, x2 and y parameters are required."
            if any {! exists $args->{$_} } qw/x1 x2 y terminal/;

        my $x1 = $args->{'x1'};
        my $x2 = $args->{'x2'};
        my $y  = $args->{'y'};
        my $terminals = $args->{'terminal'};
        my $num = scalar @$y;
        
        pgerrx( $num, $x1, $x2, $y, $terminals );
    }
    elsif ( exists $args->{'x'} ) {
        croak "y1, y2, and x parameters are required."
            if any {! exists $args->{$_} } qw/y1 y2 x terminal/;

        my $y1 = $args->{'y1'};
        my $y2 = $args->{'y2'};
        my $x  = $args->{'x'};
        my $terminals = $args->{'terminal'};
        my $num = scalar @$x;

        pgerry( $num, $x, $y1, $y2, $terminals );
    }

    pgunsa; # Restore previous attributes

    return;
}


# CURVES DEFINED BY FUNCTIONS
#

sub draw_function {
    my ($by, $args) = @_;

    croak "Must define by x, y or xy."
        if none { $by eq $_ } qw/x y xy/;

    my $flag = exists $args->{'flag'} ? $args->{'flag'} : 1;
    # Default plotted in the current window and viewport

    pgsave; # Save current attributes

    set_attributes( $args );    # Design settings

    if ($by eq 'x') {       # Function defined by X = F(Y)
        croak "fy, num, min and max parameters are required."
            if any {! exists $args->{$_} } qw/fy num min max/;

        my $fy   = $args->{'fy'};
        my $num  = $args->{'num'};
        my $min  = $args->{'min'};
        my $max  = $args->{'max'};

        pgfunx( $fy, $num, $min, $max, $flag );
    }
    elsif ($by eq 'y') {    # Function defined by Y = F(X)
        croak "fx, num, min and max parameters are required."
            if any {! exists $args->{$_} } qw/fx num min max/;
        
        my $fx   = $args->{'fx'};
        my $num  = $args->{'num'};
        my $min  = $args->{'min'};
        my $max  = $args->{'max'};

        pgfuny( $fx, $num, $min, $max, $flag );
    }
    else {   # Function defined by X = F(T), Y = G(T)
        croak "fx, fy, num, min and max parameters are required."
            if any {! exists $args->{$_} } qw/fx fy num min max/;

        my $fx   = $args->{'fx'};
        my $fy   = $args->{'fy'};
        my $num  = $args->{'num'};
        my $min  = $args->{'min'};
        my $max  = $args->{'max'};

        pgfunt( $fx, $fy, $num, $min, $max, $flag );
    }

    pgunsa; # Restore previous attributes

    return;
}


# HISTOGRAMS
#

sub draw_histogram {
    my $args = shift;

    croak "data parameter is required."
        unless exists $args->{'data'};

    pgsave; # Save current attributes

    set_attributes( $args );    # Design settings

    my $data = $args->{'data'};
    my $flag = exists $args->{'flag'} ? $args->{'flag'} : 1;
    # Default plotted in the current window and viewport
    my @temp = grep { defined } @$data;
    # This if done because List::Util's die with arrays that may contain undef
    my $min  = exists $args->{'min'}  ? $args->{'min'}  : min @temp;
    my $max  = exists $args->{'max'}  ? $args->{'max'}  : max @temp;
    my $num  = scalar @$data;
    my $nbin = exists $args->{'nbin'} ? $args->{'nbin'} : $num % 400;

    pghist( $num, $data, $min, $max, $nbin, $flag );

    pgunsa; # Restore previous attributes

    return;
}


###############################################################
# MISC
###############################################################


sub get_align {
    my $id = shift;

    my $align = $TEXT_ALIGN->{'Left'};  # Default text alignment

    if (defined $id) {
        if ( exists $TEXT_ALIGN->{ $id } ) {
            $align = $TEXT_ALIGN->{ $id };
            # If the user provided a valid text alignment
        }
        elsif ( looks_like_number $id  &&  any { $id == $_ } (0, 0.5, 1) ) {
            $align = $id;
            # If the user provided directly the text alignment
        }
        else {
            croak "Must provide a valid align or justification value.";
        }
    }

    return $align;
}

sub get_angle {
    my $degree = shift;

    my $angle = 0;  # Default angle

    if (defined $degree) {
        if ( looks_like_number $degree  &&  $degree >= 0  &&  $degree <= 360 ) {
            $angle = $degree;
            # If the user provided a valid degree
        }
        else {
            croak "Must provide a valid angle degree value.";
        }
    }

    return $angle;
}


1;

__END__

=head1 NAME


PGPLOT::Simple - Simple Interface to PGPLOT


=head1 SYNOPSIS


 use strict;
 use PGPLOT::Simple qw(:essential);

 die "Must provide a filename.\n" unless @ARGV;

 my $filename = shift;
 chomp $filename;

 unless ( $filename =~ /\.ps$/ ) {
    $filename .= ".ps";
 }
 
 set_begin({
    file => "$filename/CPS",
 });
 
 set_environment({
     x_min   =>  0,
     x_max   =>  50,
     y_min   =>  0,
     y_max   =>  10,
 });
 
 write_label({
     title  => 'A Simple Graph Using PGPLOT::Simple',
     color  => 'Blue',
     font   => 'Italic',
 });
 
 draw_points({
     x     => [1, 3, 12, 32, 40],
     y     => [1, 5,  5,  3,  9],
     color => 'Blue',
     width => 20,
 });
 
 draw_error_bars({
     x        => [20],
     y1       => [4],
     y2       => [6],
     terminal => 10,
     width    => 10,
     color    => 'Orange',
 });
 
 set_end;


=head1 DESCRIPTION


PGPLOT::Simple is a simple interface to the PGPLOT library ala Perl, making
simple things easy and difficult things possible.

Why simple? Because it has a simple and intiutive interface to the most common things you
will need from PGPLOT, but also allowing you low-level access to the PGPLOT library.


=head1 FUNCTIONS : ESSENTIAL


=head2 set_begin

Opens a graphical device or file and prepares it for subsequent plotting.

 set_begin({ file      => "$filename/$type",
             num_x_sub => 2,
             num_y_sub => 1,
 });

All the fields are optional. As default file would be used the Standard Output
and a type of Color PostScript (CPS).

The number of X and Y subdivision of the view surface is set to 1 for each.

References:

=over

=item http://www.astro.caltech.edu/~tjp/pgplot/subroutines.html#PGBEG

=back

=head2 set_end

Close and release any open graphics devices. This is the same as calling
B<pgend> directly.

References:

=over

=item http://www.astro.caltech.edu/~tjp/pgplot/subroutines.html#PGEND

=back

=head2 set_environment

This function starts a new picture and defines the range of variables and the scale of the plot.
It also draws and labels the enclosing box and the axes if requested.

L</"set_environment"> establishes the scaling for subsequent calls to L</"draw_points">,
L</"draw_polyline">, etc.  The plotter is advanced to a new page or panel,
clearing the screen if necessary.

 set_environment({
    x_min   =>              $x1,    # Required. Bottom left coordinate
    y_min   =>              $y1,    # Required 
    x_max   =>              $x2,    # Required. Top right coordinate
    y_max   =>              $y2,    # Required
    justify =>                0,    # Default
    axis    =>   'BoxCoordAxes',    # Default
 });

Supported axis codes:

    Clean
    Box
    BoxCoord
    BoxCoordAxes
    BoxCoordAxesGrid
    BoxXLog
    BoxYLog
    BoxXYLog

Also accept the axis number code from the PGPLOT library.

Set justify to something other than 0, to set the scales of the x and y axes (in
world coordinates per inch) equal.

References:

=over

=item http://www.astro.caltech.edu/~tjp/pgplot/subroutines.html#PGENV

=back

=head2 set_viewport

Change the size and position of the viewport, specifying
the viewport in normalized device coordinates.  Normalized
device coordinates run from 0 to 1 in each dimension. The
viewport is the rectangle on the view surface "through"
which one views the graph.

 set_viewport({ x_left  => $x1,    # Required. Left coordinate
                x_right => $x2,    # Required. Right coordinate
                y_bot   => $y1,    # Required. Bottom coordinate
                y_top   => $y2,    # Required. Top coordinate
 });

References:

=over

=item http://www.astro.caltech.edu/~tjp/pgplot/subroutines.html#PGSVP

=back

=head2 set_window

Change the window in the world coordinate space that is to be mapped on the
viewport.

 set_window({ x_min => $x1,    # Required. Bottom left coordinate
              y_min => $y1,    # Required 
              x_max => $x2,    # Required. Top right coordinate
              y_max => $y2,    # Required
 });

References:

=over

=item http://www.astro.caltech.edu/~tjp/pgplot/subroutines.html#PGSWIN

=back

=head2 set_box

Draw a box and optionally label one of both axes with (DD) HH MM SS style
nummeric labels (useful for time or RA - DEC plots).

You define a style or options for each label. See documentation for a larger
discussion about what's available.

 set_box({ x_style => 'ABCGZHON',    # Default
           y_style =>    'ABCGN',    # Default
           x_tick  =>        0.0,    # Default
           y_tick  =>        0.0,    # Default
           n_x_sub =>          0,    # Default
           n_y_sub =>          0,    # Default
 });

All parameters are optional, in which case the default values will be used.

References:

=over

=item http://www.astro.caltech.edu/~tjp/pgplot/subroutines.html#PGTBOX

=back

=head2 set_active_panel

Start plotting in a different panel. If the view surface has been
divided into panels by L</"set_begin"> or using the L<PGPLOT> functions 
B<pgbeg> or B<pgsubp>, this routine can be used to move to a different panel.

 set_active_panel({ x_index => 2,    # Required
                    y_index => 1,    # Required
 });

References:

=over

=item http://www.astro.caltech.edu/~tjp/pgplot/subroutines.html#PGPANL

=back

=head2 set_range

Choose plotting limits x_low and x_high which encompass the data
range x1 to x2.

 set_range({ x_low  => $min - 1,    # Required
             x_high => $max + 1,    # Required
             x1     => $min,        # Required
             x2     => $max,        # Required
 });

References:

=over

=item http://www.astro.caltech.edu/~tjp/pgplot/subroutines.html#PGRNGE

=back

=head2 write_label

Set the graphs title and labels.

 write_label({ x          =>        'X',   # Default
               y          =>        'Y',   # Default
               title      => 'Untitled',   # Default
               font       =>   'Normal',   # Default
               color      =>     'Blue',
 });

References:

=over

=item http://www.astro.caltech.edu/~tjp/pgplot/subroutines.html#PGLAB

=back

=head2 write_text

Primitive routine for drawing text. The text may be drawn at any
angle with the horizontal, and may be centered or left- or right-
justified at a specified position.

 write_text({ x          =>                800,     # Required
              y          =>                1.5,     # Required
              string     => "PGPLOT Is Great!",     # Required
              angle      =>                  0,     # Default
              align      =>             'Left',     # Default
              background =>      'BlueMagenta',
              color      =>           'Yellow',
              height     =>                2.5,
              font       =>           'Script',
 });

References:

=over

=item http://www.astro.caltech.edu/~tjp/pgplot/subroutines.html#PGPTXT

=back

=head2 write_text_viewport

Write text at a position specified relative to the viewport (outside
or inside).  This routine is useful for annotating graphs.
It is used by routine L</"write_label">.

 write_text_viewport({ string   => "Potatoes",    # Required
                       displace =>       "BR",    # Default
                       coord    =>          1,    # Default
                       justify  =>     'Left',    # Default
                       color    =>     'Cyan',
 });

Displace must include one of the characters 'B', 'L', 'T', or 'R' signifying
the Bottom, Left, Top, or Right margin of the viewport. If it includes 'LV' or
'RV', the string is written perpendicular to the frame rather than parallel to
it.

Justify can be one of 'Left', 'Right' and 'Center'. It also accept the
nummeric values defined for the B<pgmtxt> function.

References:

=over

=item http://www.astro.caltech.edu/~tjp/pgplot/subroutines.html#PGMTXT

=back

=head2 draw_points

Add graph markers points to an existing graph. Must provide
X and Y data and Symbol.

 draw_points({ x      => \@x_data,      # Required
               y      => \@y_data,      # Required
               symbol =>  $symbol,
               color  =>    'Red',
 });

It really draw graph markers, but by default the symbol used to graph is a
point. If you want something other, you need to provide a valid symbol code.
See L<PGPLOT> documentation to get the list of symbols.

Note: It's called draw_points because mainly you will use it for drawing points,
and because it's easier to remember than draw_graph_markers.

References:

=over

=item http://www.astro.caltech.edu/~tjp/pgplot/subroutines.html#PGPT

=item http://www.astro.caltech.edu/~tjp/pgplot/hershey.html

=back

=head2 move_pen

Move pen to the point with world coordinates X,Y. No line is drawn.

 move_pen({ x => 200,
            y => 400,
 });

Return the current pen position. Can also be called without X and Y
position, in this case only the pen position is returned.

Note: return a list with 2 values, first value correspond to the X value,
and second correpond to the Y value.

=over

=item http://www.astro.caltech.edu/~tjp/pgplot/subroutines.html#PGMOVE

=back

=head2 draw_line

Draw a line from the current pen position to the point with world
coordinates X,Y. The new pen position is X,Y in world coordinates.

 draw_line({ x => 743,  # Required
             y => 324,  # Required
 });

References:

=over

=item http://www.astro.caltech.edu/~tjp/pgplot/subroutines.html#PGDRAW

=back

=head2 draw_polyline

Add a line to an existing graph. Must provide X and Y data.

 draw_polyline({ x      => \@x_data,   # Required
                 y      => \@y_data,   # Required
                 color  =>  'Green',
                 width  =>        5,
                style =>  'Dotted',
 });

References:

=over

=item http://www.astro.caltech.edu/~tjp/pgplot/subroutines.html#PGLINE

=back

=head2 draw_polygon

Add a polygon to an existing graph. Must provide X and Y data.

 draw_polygon({ x      =>  \@x_data,   # Required
                y      =>  \@y_data,   # Required
                color  =>   'Green',
                width  =>         2,
                style  =>  'Dashed',
                fill   => 'Outline',
 });

References:

=over

=item http://www.astro.caltech.edu/~tjp/pgplot/subroutines.html#PGPOLY

=back

=head2 draw_rectangle

Add a rectangle to an existing graph. Must provide X and Y data.

 draw_rectangle({ x1      =>         $x1,  # Required
                  x2      =>         $x2,  # Required
                  y1      =>         $y1,  # Required
                  y2      =>         $y2,  # Required
                  color   =>    'Orange',
                  width   =>           7,
                  style   =>  'FullLine',
                  fill    =>   'Hatched',
 });

References:

=over

=item http://www.astro.caltech.edu/~tjp/pgplot/subroutines.html#PGRECT

=back

=head2 draw_circle

Add a circle to an existing graph. Must provide X, Y and Radius data.

 draw_circle({ x      =>                $x,    # Required
               y      =>                $y,    # Required
               radius =>              $rad,    # Required
               color  =>          'Orange',
               width  =>                 7,
               style  =>  'DotDashDotDash',
               fill   =>    'CrossHatched',
 });

References:

=over

=item http://www.astro.caltech.edu/~tjp/pgplot/subroutines.html#PGCIRC

=back

=head2 draw_arrow

Add a arrow to an existing graph. Must provide X and Y data.

 draw_arrow({ x1          =>          1320,   # Required 
              x2          =>          1650,   # Required
              y1          =>            20,   # Required
              y2          =>           140,   # Required
              color       => 'GreenYellow',
              width       =>            10,
              arrow_style =>  { 
                fill  => 'Outline',
                angle =>        50,
              },
 });

References:

=over

=item http://www.astro.caltech.edu/~tjp/pgplot/subroutines.html#PGARRO

=back

=head2 draw_error_bars

Plot horizontal or vertical error bars. Must provide X and Y data.

 draw_error_bars({ x1        =>  [400, 1000, 2600],     # Required Horizontal
                   x2        =>  [500, 1000, 3000],     # Required
                   y         =>  [1.2,  1.5,  1.4],     # Required
                   terminal  =>                  2,     # Required
                   width     =>                  2,
                   color     =>                 $f,
 });

 draw_error_bars({ y1        =>                \@c,     # Required Vertical
                   y2        =>                \@b,     # Required
                   x         =>                \@a,     # Required
                   terminal  =>                0.0,     # Required
 });

You also need to provide a 'terminal' key which corresponds to the
length of terminals to be drawn at the ends of the error bar, as a multiple
of the default length; if 'terminal' = 0.0, no terminals will be drawn.

References:

=over

=item http://www.astro.caltech.edu/~tjp/pgplot/subroutines.html#PGERRX

=item http://www.astro.caltech.edu/~tjp/pgplot/subroutines.html#PGERRY

=back

=head2 draw_function

Draw functions. Must provide function type:

    'x'  - Function defined by Y = F(X)
    'y'  - Function defined by X = F(Y)
    'xy' - Function defined by X = F(T), Y = G(T)


 draw_function('x', {
         fy    => sub{ sqrt($_[0]) },   # Required
         num   =>    500,               # Required. Num. of points required to
                                        #   define the curve.
         min   =>      0,               # Required
         max   =>     50,               # Required
         flag  =>      1,               # Default.
         color => 'Blue',
         width =>      7,
 });
 
 draw_function('xy', {
         fy    => sub{ 3 * cos $_[0] }, # Required
         fx    => sub{ 5 * sin $_[0] }, # Required
         num   =>         500,          # Required
         min   =>          10,          # Required
         max   =>         100,          # Required
         color => 'GreenCyan',
         width =>           7,
 });

Flag option define if the curve is plotted in the current window and viewport.
If the value is 0 B<pgenv> is called automatically by one of the L<PGPLOT>
functions subroutines to start a new plot with automatic scaling. Take a look
at the L</"Notes"> section to see what this would imply.

References:

=over

=item L<PGPLOT> to see accepted function pass methods.

=item http://www.astro.caltech.edu/~tjp/pgplot/subroutines.html#PGFUNX

=item http://www.astro.caltech.edu/~tjp/pgplot/subroutines.html#PGFUNY

=item http://www.astro.caltech.edu/~tjp/pgplot/subroutines.html#PGFUNT

=item http://www.astro.caltech.edu/~tjp/pgplot/subroutines.html#PGENV

=back

=head2 draw_histogram

Draw a histogram of unbinned data.

 draw_histogram({ data  =>   \@a,   # Required
                  min   =>     0,
                  max   =>   300,
                  nbin  =>    25,
                  color => 'Red',
                  width =>     2,
                  flag  =>     1,   # Default
 });

Min and max values are the minimum and maximum data value for the histogram.
Min and max values defaults to the min and max value of the given array.

Nbin is the number of bins to use. Defaults to the number of elements that has
the array modulo 400, which corresponds to the maximum value of bins possible.

Flag option define if the curve is plotted in the current window and viewport.
If the value is 0 B<pgenv> is called automatically by one of the L<PGPLOT>
functions subroutines to start a new plot with automatic scaling. Take a look
at the L</"Notes"> section to see what this would imply.

References:

=over

=item http://www.astro.caltech.edu/~tjp/pgplot/subroutines.html#PGHIST

=item http://www.astro.caltech.edu/~tjp/pgplot/subroutines.html#PGENV

=back


=head1 FUNCTIONS : OPTIONAL


=head2 set_color

Set next primitive color, launch exception if a wrong color
supplied.

See L</"color"> to see the valid color code names. Defaults to 'Foreground' if
nothing supplied.

References:

=over

=item http://www.astro.caltech.edu/~tjp/pgplot/subroutines.html#PGSCI

=back

=head2 set_text_background

Set next primitive color, launch exception if a wrong color
supplied.

Support same color options as L</"set_color">. Defaults to transparent if
nothing supplied.

References:

=over

=item http://www.astro.caltech.edu/~tjp/pgplot/subroutines.html#PGSTBG

=back

=head2 set_color_representation

Set a color representation for a index value. This index value can be used
later to referring to this color.

To define a color we need to pass the RGB values to the function.

 set_color_representation({ code  =>  20,    # Required
                            red   => 0.1,    # Required
                            green => 0.4,    # Required
                            blue  => 0.8,    # Required
 });

References:

=over

=item http://www.astro.caltech.edu/~tjp/pgplot/subroutines.html#PGSCRN

=back

=head2 set_line_width

Set line height of the next primitive. Launch exception
if something other than a digit is supplied.

See L</"width"> to get the valid width range.Defaults to 2 pixel width if
nothing supplied.

References:

=over

=item http://www.astro.caltech.edu/~tjp/pgplot/subroutines.html#PGSLW

=back

=head2 set_line_style

Set line style of the next line primitive. Launch exception
if a wrong line style code is supplied.

See L</"style"> to see the supported line style codes.

References:

=over

=item http://www.astro.caltech.edu/~tjp/pgplot/subroutines.html#PGSLS

=back

=head2 set_font

Set the Character Font for the next text plotting.

See L</"font"> to see the supported font types. Defaults to 'Normal'
if nothing supplied.

References:

=over

=item http://www.astro.caltech.edu/~tjp/pgplot/subroutines.html#PGSCF

=back

=head2 set_fill_area_style

Set the Fill-Area Style attribute for subsequent area-fill by
L</"draw_polygon">, L</"draw_rectangle">, L</"draw_circle"> or the equivalent low
level functions call B<pgpoly>, B<pgrect>, B<pgcirc>.

See L</"fill"> to see the supported styles. Defaults to 'Solid' if 
nothing supplied.

References:

=over

=item http://www.astro.caltech.edu/~tjp/pgplot/subroutines.html#PGSFS

=back

=head2 set_arrow_style

Set the style to be used for arrowheads drawn by L</"draw_arrow">.

See L</"arrow_style"> to see the accepted options.

References:

=over

=item http://www.astro.caltech.edu/~tjp/pgplot/subroutines.html#PGSAH

=back

=head2 set_hatching_style

Set the style to be used for hatching. See L</"fill_style">.

See L</"hatching_style"> to see the accepted options.

References:

=over

=item http://www.astro.caltech.edu/~tjp/pgplot/subroutines.html#PGSHS

=back


=head1 OPTIONS


=head2 color

Supported color code names:

    Background
    Foreground
    Red 
    Green
    Blue
    Cyan
    Magenta
    Yellow
    Orange
    GreenYellow
    GreenCyan 
    BlueCyan 
    BlueMagenta
    RedMagenta
    DarkGray
    LightGray

Also accept the number color codes (0-255). For color numbers major than
15, you must define the color representation. See L</"set_color_representation">
and L<PGPLOT> docs.

=head2 background

See L</"color">.

=head2 width

Set the line-width attribute. This attribute affects lines, graph
markers, and text. The line width is specified in units of 1/200 
(0.005) inch (about 0.13 mm) and must be an integer in the range
1-201.

=head2 style

This attribute affects line primitives only; it does not affect graph
markers, text, or area fill.

Supported line style code names:

    FullLine
    Dashed
    DotDashDotDash
    Dotted
    DashDotDotDot

Also accept the number line style code (1-5). See L<PGPLOT> docs.

=head2 font

Font type for text.

Supported font type code names:

    Normal
    Roman
    Italic
    Symbol

Also accept the font number code (1-4). See L<PGPLOT> docs.

=head2 fill

Set the Fill-Area Style attribute for polygons, rectangles or circles.

    Solid
    Outline
    Hatched
    CrossHatched

Also accept the integer value identifiers (1-4). See L<PGPLOT> docs.

=head2 align

Supported text align code names:

    Left
    Center
    Right

Also accept the float value identifiers (0, 0.5, 1). See L<PGPLOT> docs.

=head2 height

Set the character size attribute. The size affects all text and graph
markers drawn later in the program. The default character size is
1.0, corresponding to a character height about 1/40 the height of
the view surface.  Changing the character size also scales the length
of tick marks drawn by L</"set_box"> and terminals drawn by
L</"draw_error_bars">.

=head2 arrow_style

Set the style to be used for arrowheads drawn by L</"draw_arrow">.

You have 3 keys to define the different parts of an arrow head:

    fill_style  - Can be 'Filled' or 'Outline'.
    angle       - The acute angle of the arrow point.
    barb        - The fraction of the triangular arrow-head that
                  is cut away from the back.

Example:
    
    arrow_style => { fill   =>  'Filled',   # Default   
                     angle  =>      45.0,   # Default
                     barb   =>       0.3,   # Default
    },

=head2 hathing_style

Set the style to be used for hatching. See L</"fill_style">.

    hatching_style => { angle   => 45.0,    # Default
                        spacing =>  1.0,    # Default
                        phase   =>  0.0,    # Default
    },

=head1 NOTES

=over

=item Low level PGPLOT Library function call

To make direct call to the PGPLOT Library you only need to call it with the
package name. Example: 

 print PGPLOT::Simple::pgldev();

Or, if you want to import all the functions into your namespace add the pgplot
into your import call. Example:

 use PGPLOT::Simple qw(:pgplot);

Or combine them as you need. Example:
 
 use PGPLOT::Simple qw( :essential set_color_representation :pgplot );

=item Attributes settings

Please note that on each function where you can define attributes, this
attributes are relative to the given function.

On PGPLOT you set a main style which all function inherit, so that changing
the color using a function like set_color implies that each function call
after the color setting will be plotted using that "active color".

To don't lose this global attributes settings mechanism, which can be useful,
each function call of this module will call a function available from the
PGPLOT Library that permits to save the current attributes, and another which
permits to restore them.

=over 1

=item http://www.astro.caltech.edu/~tjp/pgplot/subroutines.html#PGSAVE

=item http://www.astro.caltech.edu/~tjp/pgplot/subroutines.html#PGUNSA

=back

=item Functions that provide a flag option

If we set the flag option to 0, B<pgenv> is called automatically by that
function to start a new plot, but we should be aware, that each attribute we
associated with the function call, for example color settings, will be applied
not only to that function, but also be applied to what B<pgenv> generates.
E.g.:

 draw_function('x', {
    fy    => sub{ sqrt $_[0] },
    num   =>    500,
    min   =>      0,
    max   =>     50,
    color => 'Blue',
    width =>      7,
    flag  =>      0,    # Here we set it to 0, by default is 1.
 });

Doing this, we will have the boxes, and labels also with a width of 7 and in
blue.

References:

=over 1

=item http://www.astro.caltech.edu/~tjp/pgplot/subroutines.html#PGENV

=back

=back

=head1 SEE ALSO


L<PGPLOT> Perl Module by Karl Glazebrook.

PGPLOT Library by Tim Pearson, L<http://www.astro.caltech.edu/~tjp/pgplot>.


=head1 AUTHOR


Florian Merges, E<lt>fmerges@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE


Copyright (C) 2005 by Florian Merges

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut
