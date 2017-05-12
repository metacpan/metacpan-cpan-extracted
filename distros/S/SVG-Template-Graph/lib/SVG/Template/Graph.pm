package SVG::Template::Graph;

use 5.006;
use strict;
use warnings;
use Carp;
use SVG::Parser;
use Exporter;
use Transform::Canvas;
use POSIX qw(strftime);

our $VERSION = '1.0';

use vars qw($VERSION @ISA );    #$AUTOLOAD);

our @ISA = qw(SVG::Parser Exporter );

=head1 NAME

SVG::Template::Graph - Perl extension for generating template-driven graphs with SVG

=head1 SYNOPSIS

 use SVG::Template::Graph;
 $data = [
		{ 
		barGraph=>1,#<barGraph|[lineGraph]>
	  	barSpace=>20,
        	'title'=> '1: Trace 1',
        	'data' => #hash ref containing x-val and y-val array refs
                	{
                	'x_val' => 
				[50,100,150,200,250,
			        300,350,400,450,500,550],
			'y_val' =>
                        	[100,150,100,126,100,
				175,100,150,120,125,100],

                	},
		'format' =>
			{ #note that these values could change for *each* trace
			'lineGraph' => 1,
	        	'x_min' =>      0, 
			'x_max' =>      600, 
			'y_min' =>      50,
			'y_max' =>      200,
			'x_axis' => 1, #draw x-axis
			'y_axis' => 1, #draw y-axis
 
                	#define the labels that provide the data context.
	        	'labels' =>
				{
				#for year labels, we have to center the axis markers
				'x_ticks' =>
					{
					'label' =>[2002,2003,2004],
					'position'=>[100,300,500],
					},
	       			'y_ticks' =>
					{
					#tick mark labels
					'label' => [ -250, 0, 250, 500],
               				#tick mark location in the data space
               				'position' => [50, 100, 150, 200],
               				},
               			},
               		},
		},
 	];


 #construct a new SVG::Template::Graph object with a file handle
 my $tt = SVG::Template::Graph->new($file);

 #set up the titles for the graph
 $tt->setGraphTitle(['Hello svg graphing world','I am a subtitle']);
 
 #generate the traces. 
 $tt->drawTraces($data,$anchor_rectangle_id);
 #serialize and print
 print  $tt->burn();

=head1 DESCRIPTION

Template::Graph:SVG is a module for the generation of template-driven
graphs using Scalable Vector Graphics (SVG). Using this module, it is possible
to define a template SVG document with containers which are populated with
correctly scaled plot images.

=head2 EXPORT

None by default.

=head2 EXAMPLES

Refer to the examples directory inside this distribution for working examples.

=cut

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use SVG::Template::Graph ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

#our %EXPORT_TAGS = ( 'all' => [ qw() ] );

#our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

#our @EXPORT = qw(
#);

$VERSION = eval $VERSION;    # see L<perlmodstyle>

=head2 new()

 #construct a new SVG::Template::Graph object with a file handle
 my $tt = SVG::Template::Graph->new($file);

The constructor for the class. Takes a template file name as an argument

=cut

sub new ($;$;@) {
    my ( $proto, $file, %attrs ) = @_;
    my $class = ref $proto || $proto;
    my $self;

    my %default_attributes = %SUPER::default_attributes;

    $self->{_config_}    = {};
    $self->{_svgTree_}   = {};
    $self->{_IDCACHE_}   = {};
    $self->{graphTarget} = undef;

    # establish defaults for unspecified attributes
    $self              = $class->SUPER::new();
    $self->{_svgTree_} = $self->parse_uri($file);
    $self->{_IDMap_}   = {};
    return $self;
}

=head2 burn()

serialise the image. See SVG::xmlify for more details

=cut

sub burn ($;@) {

    my ( $self, %attrs ) = @_;
    return $self->D()->xmlify(%attrs);
}

=head2 setGraphTitle

 my $svg_element_ref = $tt->setGraphTitle ($string|\@strings, %attributes)

Generate the text for the Graph Title
Returns the reference to the text element

=cut

sub setGraphTitle ($$;@) {
    my $self = shift;
    my $text = shift;
    return $self->_setAxisText($self->mapTemplateId("group.graph.title"), $text, @_ );
}

=head2 setTraceTitle

set the title of a trace

 $tt->setTraceTitle( $string|\@strings, %attributes )


=cut

sub setTraceTitle ($$$;@) {
    my $self = shift;
    my $ti   = shift;
    my $text = shift;
    return $self->_setAxisText($self->mapTemplateId("group.trace.title.$ti"), $text, @_ );
}

=head2  setXAxisTitle

Generate the text for the Graph X-Axis Titles
Returns the reference to the text element

 $tt->setXAxisTitle($axis_number, $string, %attributes)
 $tt->setXAxisTitle($axis_number, \@strings, %attributes)

=cut

sub setXAxisTitle ($$$;@) {
    my $self = shift;

    #the trace index
    my $ti   = shift;
    my $text = shift;
    return $self->_setAxisText($self->mapTemplateId("group.trace.axes.title.x.$ti"), $text, @_ );
}

=head2 setYAxisTitle

Generate the text for the Graph Y-Axis Titles
Returns the reference to the text element


 $tt->setYAxisTitle($axis_number, $string,%attributes)
 $tt->setYAxisTitle($axis_number, \@strings,%attributes)

=cut

sub setYAxisTitle ($$$;@) {
    my $self = shift;

    #the trace index
    my $ti   = shift;
    my $text = shift;
    return $self->_setAxisText($self->mapTemplateId("group.trace.axes.title.y.$ti"), $text, @_ );
}

=head2 _gg

Check that a group exists (is a valid, defined group in the SVG DOM) and create a group in the document if id does not exist. Return the group element
This ensures that even if a designer failed to generate a group ID in the drawing, you will get a drawing with the right group names.
If type is defined, an element of $type with %attributes is defined.


 my $svg_element = $tt->_gg ($id)
 my $svg_element = $tt->_gg ($id,'rect',width=>10,height=>10,
		x=>10,y=>10,fill=>'none',stroke=>'red')

=cut

sub _gg ($$;@) {
    my $self  = shift;
    my $id    = shift || 'abc';
    my $type  = shift || 'group';
    my %attrs = @_;
    return $self->{_IDCACHE_}->{$id} if $self->{_IDCACHE_}->{$id};
    my $d = $self->D()
      || confess("E1000: Supplied SVG input  not properly parsed!!");
    my $tg = $d->getElementByID($id);
    unless ($tg) {

        carp("element $type with id '$id' not found in document when setting a text field.");
        $d->getRootElement()->comment("missing group $id added by pid $$ $0");
        $tg = $d->getRootElement()->element( $type, id => $id, %attrs );

       #        carp("element $type with id '$id' created under root element ");
    }
    $self->{_IDCACHE_}->{$id} = $tg;

    #print STDERR "Saving $tg to IDCACHE $id\n";
    return $tg;
}

=head2 _setAxisText

Internal method called by setGraphTitle and setAxisTitle to do the actual work. Not really intended to be accessed from the outside but available for advanced users.

 $tt->_setAxisText ($id,$text|\@text,%attributes)

=cut

sub _setAxisText ($$$;@) {
    my $self = shift;
    my $id   = shift;
    my $text = shift;
    my %attrs;
    %attrs = @_;

    #check if we have an array of strings
    $text = [$text] unless ( ref($text) eq 'ARRAY' );

    carp(
"No text was supplied. Either supply a string or an array reference containing strings"
      )
      unless scalar @$text;
    my $tg = $self->_gg($id);
    my $to = $tg->text(%attrs)
      || carp("Failed to generate an Axis text element within group '$id'.");
    my %args = ( x => 0 );

    foreach my $line (@$text) {
        $to->tspan(%args)->cdata($line)
          || carp(
            "Failed to generate an Axis tspan element within group '$id'.");

        #set the dy spacing for multi-line text
        $args{dy} = '1em';
    }
    return $to;
}

=head2 struct $struct 

the input structure required by sub drawTraces to generate the graph.
Refer to the examples included in this distribution in the examples
directory for working samples.

 $struct = [{
	'tracetype' => 'linegraph',
        'title'=> '1: Trace 1',
        'data' => #hash ref containing x-val and y-val array refs
                {
                'x_val' =>
                        [0, 2, 4, 
			6, 8, 10,
			12,14,16,
			18,20],
                'y_val' =>
                        [4, 2, 5, 
			3, 7, 4 , 
			9, 9, 2, 
			4, 3],
                },
        'format' =>
                {
                'x_max' => 600, #or for your case, the date value of the 1st point
                'x_min' => 0, #or for your case, the date value of the last point
                'y_max' => 0.35,
                'y_min' => -0.1,
                'x_title' => 'Calendar Year',
                'y_title' => '% Annual Performance',
		'x_axis' => 0, # do not automatically draw an x-axis
		'y_axis' => 1, #automatically draw a y-axis
                
		#define the labels that provide
                #the data context.
                'labels' =>
                        {
                        #for year labels, we have to center the axis markers
                        'x_ticks' =>
                                {
                                'label'         =>[2002,2003,2004],
                                'position'      =>[100,300,500],
                                },
                        y_ticks =>
                                {
                                #tick mark label
                                'label' => [ '-10.00%', '-5.00%', '0.00%',
					 '5.00%', '10.00%', '15.00%', 
					'20.00%', '25.00%', '30.00%', 
					'35.00%' ],
                                #tick mark location in the data space
                                'position' => [-0.10,-0.5,0,
						-.5,.10,.15,
						.20,.25,.30,
						.35],
                                },
                        },
                },
        legend_title => 'Some Interesting Data',
        },
 ];

=cut

=head2 getCanvasBoxBoundaries() 

if $id_anchor_data is an array reference, then it uses it to describe the extents of the viewbox into which the current drawing will happen.
If $id_anchor_data is a string then its associated xml element is assumed to be a rectangle and getCanvasBoxBoundaries uses the rectangle geometry.to define the plot bounding box.
hash references are not supported.

Action: set the boundary box data in the object and returns the array reference:
 
	[xmin, ymin, xmax, ymax]

=cut

sub getCanvasBoxBoundaries ($) {

    my $self = shift;
    my $id   = $self->getGraphTarget;

    unless ( defined $self->{_config_}->{xmin_p} ) {

        if ( ref($id) eq 'ARRAY' ) {
            (
                $self->{_config_}->{xmin_p}, $self->{_config_}->{ymin_p},
                $self->{_config_}->{xmax_p}, $self->{_config_}->{ymax_p}
              )
              = @$id;
        } elsif ( ref($id) eq 'HASH' ) {
            croak('getCanvasBoxBoundaries does not yet support hashes');

        } else {
            my $r = $self->D()->getElementByID($id)
              || croak("Could not find rectangle with id='$id'");

            #define the configuration data for the paperspace.
            $self->{_config_}->{xmin_p} = $r->getAttribute('x');
            $self->{_config_}->{xmax_p} =
              $self->{_config_}->{xmin_p} + $r->getAttribute('width');
            $self->{_config_}->{ymin_p} = $r->getAttribute('y');
            $self->{_config_}->{ymax_p} =
              $self->{_config_}->{ymin_p} + $r->getAttribute('height');
        }

    }

    #return the reference to the array as expected by Transform::Canvas
    return [
        $self->{_config_}->{xmin_p}, $self->{_config_}->{ymin_p},
        $self->{_config_}->{xmax_p}, $self->{_config_}->{ymax_p},
    ];
}

=head2 getDataBoxBoundaries (\%struct)

returns the value of the boundary box of the data set which places the graph in the image
as an array reference:

 [xmin, ymin, xmax, ymax]

=cut

sub getDataBoxBoundaries ($$) {

    my $self = shift;
    my $p    = shift;

    return [
        $p->{format}->{x_min}, $p->{format}->{y_min},
        $p->{format}->{x_max}, $p->{format}->{y_max},
    ];

}

=head2 drawAxis(<target_group_id>,[x|y|undef]))

draw one or both of axes (zero-value line) of the drawing data space. Draws both axes unless one of the axes is passed as a string.

 drawAxis('somegroupid','x') draws the x-axis line into group 'somegroupid'.
 drawAxis('somegroupid','y') draws the y-axis line indo group 'somegroupid'
 drawAxis('somegroupid') draws both x- and y- axis lines into group 'somegroupid'

construction detail: draws the content into a group.

=cut

sub drawAxis ($$$) {
    my $self = shift;
    my $id   = shift;          #anchor id
    my $o    = shift || '';    #orientation
    my $g;
    if ( !$o || ( $o eq 'x' || $o eq 'y' ) ) {
        $g = $self->_gg($id);

        #draw the x-axis if it appears in the canvas window
        $g->line(
            id => "x axis zero line",
            x1 => $self->T->mapX(0),
            y1 => $self->T->mapY( $self->T->dy0 ),
            x2 => $self->T->mapX(0),
            y2 => $self->T->mapY( $self->T->dy1 ),
          )
          if $o eq 'x';
        $g->line(
            id => "y axis zero line",
            x1 => $self->T->mapX( $self->T->dx0 ),
            y1 => $self->T->mapY(0),
            x2 => $self->T->mapX( $self->T->dx1 ),
            y2 => $self->T->mapY(0),
          )
          if $o eq 'y';
        return $g;
    }
    return undef;
}

=head2 drawTraces ($data_structure,$insertion_anchor_id)

given a structure describing the incoming drawing parameters, generates the SVG lines, axes, and ticks and returns the number of traces that were handled.
If $anchor_id is defined and is a rectangle ID, then the drawing will take place in id.if $anchor_point is defined and it is an array of 4 real numbers,
then this will be taken to be the location where the insertion box goes.

The format for the array is: [x0 y0 x1 y1]. in canvas dimension

=cut

sub drawTraces ($$) {
    my $self             = shift;
    my $struct           = shift;
    my $insert_anchor_id = shift;
    unless ($insert_anchor_id) {
        $self->setGraphTarget;
        $insert_anchor_id = $self->getGraphTarget;
    }

    #make sure we got an array ref for $struct
    croak(
"drawTrace error: expected an array at drawTraces but got something called '"
          . ref($struct)
          . "' with content $struct." )
      unless ref($struct) eq 'ARRAY';

    #take the hash struct for each trace and run it through the grinder.
    #past this point, the code goes to hell as of 2004.09.21.
    #but this is the way to go...

    my $ti = 0;
    foreach my $trace (@$struct) {
        $ti++;
        $self->getTracePointMap( $ti, 'path', $trace, $insert_anchor_id )
          || croak("Failed to build trace $ti");
    }

    return $ti;
}

=head2 getTracePointMap $index, polyline|[path]|polygon, $p, $anchor_data, %args

scales the points for lines appropriately and generates
the correct polyline or path or polygon element,
scaled and inverted to match paper space.

if $anchor_data is defined, then it is either the id of a rectangle whose geometry will contain the results, or it is an array reference which contains the viewbox defilition [x0,y0,x1,y1] where the graph is to be placed.

this is the method in which the generation of the graph is handled

returns the reference of the polyline/path/polygon tag that was generated.

=cut

sub getTracePointMap ($$$$;@) {
    my $self             = shift;
    my $ti               = shift;
    my $type             = shift;
    my $p                = shift;
    my $insert_anchor_id = shift;
    my %args             = @_;

    my $canvas = $self->getCanvasBoxBoundaries;

    #assign a default line drawing type
    $p->{lineGraph} = 1 unless $p->{barGraph};
    $self->{map}    = Transform::Canvas->new(

        #the canvas extents limits
        canvas => $canvas,

        #the data scape mapping to the above canvas geometry
        data => $self->getDataBoxBoundaries($p),
    );

    confess("Failed to create Canvas Transform object")
      unless ref( $self->{map} ) eq 'Transform::Canvas';
    my @pr = $self->{map}->map( $p->{data}->{x_val}, $p->{data}->{y_val} );

    #draw the gridlines
    $self->drawGridLines( $ti, $p->{format} )
      || warn("Error building the gridlines");

    $self->lineGraph( $ti, $type, \@pr, $canvas, %args ) if $p->{lineGraph};

    delete $args{closed} if $args{closed};

    if ( $p->{barGraph} ) {
        $p->{data}->{x_val} =
          ref $p->{data}->{x_val}
          ? $p->{data}->{x_val}
          : [ $p->{data}->{x_val} ];
        $p->{data}->{y_val} =
          ref $p->{data}->{y_val}
          ? $p->{data}->{y_val}
          : [ $p->{data}->{y_val} ];
        $self->barGraph( $ti, [ $p->{data}->{x_val}, $p->{data}->{y_val} ],
            $p->{barSpace}, %args );
    }

    $self->drawAxis($self->mapTemplateId("group.trace.axes.x.$ti"), 'x' )
      if $p->{format}->{x_axis};
    $self->drawAxis($self->mapTemplateId("group.trace.axes.y.$ti"), 'y' )
      if $p->{format}->{y_axis};

    #set the trace titles if they are specified
    $self->setXAxisTitle( $ti, $p->{format}->{x_title} )
      if defined $p->{format}->{x_title};
    $self->setYAxisTitle( $ti, $p->{format}->{y_title} )
      if defined $p->{format}->{y_title};
    $self->setTraceTitle( $ti, $p->{title} ) if defined $p->{title};
    return 1;
}

=head2 lineGraph index, type, [\@x,\@y], $canvas, %styling_attributes

draw a line graph trace

=cut

#draw the line graph
sub lineGraph ($$$$@) {
    my $self   = shift;
    my $ti     = shift;
    my $type   = shift;
    my $points = shift;
    my $canvas = shift;
    my %args   = @_;

    $type = 'path'
      unless ( $type eq 'polyline'
        || $type eq 'polygon'
        || $type eq 'scatter' );
    my %closed = ();
    %closed = ( '-closed' => 'true' ) if ( lc( $args{closed} ) eq 'true' );

    delete $args{closed} if $args{closed};

    #draw the trace in the container
    my $c_points = $self->D()->get_path(
        x     => $points->[0],
        y     => $points->[1],
        -type => $type,
        %closed,
    );

    #invoke the transformation from data space to canvas space
    my ( $min_x, $min_y, $max_x, $max_y ) = @$canvas;
    my $id_string =$self->mapTemplateId("group.trace.data.$ti");
    my $traceBase = $self->_gg($id_string)
      || confess(
        "Failed to find required element 
					id '$id_string'"
      );
    return $traceBase->$type( %$c_points, id => "trace.$ti", %args );
}

#draw the bar graph

=head2 barGraph()

 $g->barGraph( $index, [\@x,\@y], \@canvas, $barSpace, %styling_attributes)

draw a bar graph trace

=cut

sub barGraph ($$$$@) {
    my $self = shift;
    my $ti   = shift;

    #the raw points.
    my $points   = shift;
    my $barSpace = shift;
    my %args     = @_;

    my $out = $self->getCanvasBoxBoundaries;

    my ( $min_x, $min_y, $max_x, $max_y ) = @$out;

    my $Points = scalar @{ $points->[0] };

    my $traceBase = $self->_gg("group.trace.data.$ti")
      || confess("Failed to find required element id group.trace.data.$ti");

    #we do a simple width linerization which falls down
    #when the bars do not span the image.
    $barSpace = $barSpace ? $barSpace : $Points + 1;
    my $width = ( $max_x - $min_x ) / $barSpace;

    #draw a rectangle for each point, with the
    #rectangle centered on the point at the X midpoint
    #of the rectangle.
    #
    #watch out for paper space inversion tricks.
    #min_y is the bottom of the drawing (max_canvas_value)
    #we are working in paper space
    foreach my $index ( 0 .. $Points - 1 ) {

        my $x = $self->T->mapX( $points->[0]->[$index] ) - 0.5 * $width;

        #my $y = $self->T->mapY($points->[1]->[$index]);
        my $y = $self->T->mapY(0);

        my $height =
          $self->T->mapY( $points->[1]->[$index] ) - $self->T->mapY(0);

        #handle negative rectangle height
        if ( $height < 0 ) {
            $height = -$height;
            $y      = $y - $height;
        }
        $traceBase->rect(
            x      => $x,
            y      => $y,
            width  => $width,
            height => $height,
            %args
        );

        #this is the correct top position
        #zeros position. do not mess with this!!

    }
}

=head2 drawGridLines()

 $p->drawGridLines ($target_svg_element_ref,$transformation_ref,$format_structure_ref)

draw the gridlines for a graph as defined in the formatting data structure for each trace.

=cut

sub drawGridLines ($$$) {
    my $self = shift;
    my $ti   = shift;
    my $f    = shift;    #formatting data structure ($in->{format})

    my $gid = undef;
    $gid =$self->mapTemplateId("group.trace.axes.x.$ti");
    my $g_x = $self->_gg($gid)
      || confess("Failed to find required element ID '$gid'");
    $gid =$self->mapTemplateId("group.trace.axes.y.$ti");
    my $g_y = $self->_gg($gid)
      || confess("Failed to find required element ID '$gid'");

    $gid =$self->mapTemplateId("group.trace.axes.values.x.$ti");
    my $t_x = $self->_gg($gid)
      || confess("Failed to find required element ID '$gid'");
    $gid =$self->mapTemplateId("group.trace.axes.values.y.$ti");
    my $t_y = $self->_gg($gid)
      || confess("Failed to find required element ID '$gid'");

    $gid =$self->mapTemplateId("group.trace.tick.$ti");
    my $tk_y = $self->_gg($gid)
      || confess("Failed to find required element ID '$gid'");
    my $tk_x = $self->_gg($gid)
      || confess("Failed to find required element ID '$gid'");

    croak("Format not correctly passed to drawGrid: not a hash reference")
      unless ref($f) eq 'HASH';

    #
    #handle labels if we have a gridlines label
    if ( defined $f->{labels} ) {

        #Grid positions
        $self->{grid}->{y_p} = $f->{labels}->{y_ticks}->{position} || [];
        $self->{grid}->{x_p} = $f->{labels}->{x_ticks}->{position} || [];

        #grid label units
        $self->{grid}->{x_u} = $f->{labels}->{x_ticks}->{unit} || '';
        $self->{grid}->{y_u} = $f->{labels}->{y_ticks}->{unit} || '';

        #grid axes labels
        $self->{grid}->{y_l} = $f->{labels}->{y_ticks}->{label} || [];
        $self->{grid}->{x_l} = $f->{labels}->{x_ticks}->{label} || [];

        #grid count
        $self->{grid}->{y_c} = scalar @{ $self->{grid}->{y_p} } || 0;
        $self->{grid}->{x_c} = scalar @{ $self->{grid}->{x_p} } || 0;

        $self->handleFurnishings( 'x', $f,
            { line => $g_x, label => $t_x, tick => $tk_x } );

        #cut line here
        $self->handleFurnishings( 'y', $f,
            { line => $g_y, label => $t_y, tick => $tk_y } );

        #cut line here
    }
    return 1;
}

=head2 handleFurnishings()


 $p->handleFurnishings( $orientation, $format, \%anchor_refs);

single point for handling grid lines, gridline lables, and gridline tickmarks
this method is a factory method for generating vertical or horizontal furnishings for the trace
the anchor hash reference contains the following keys:
 
 line
 label
 tick

parameters

gridline orientation 

 $orientation = 'x' or 'y' 

Gridline context-format hash reference
 
 $format - hash reference

defines what is shown and what is not.

whose values are svg element object references where the respective entities are to be appended as children.

=cut


sub handleFurnishings ($$$$$) {

    my $self   = shift;
    my $o      = shift;
    my $f      = shift;
    my $anchor = shift;

    croak "Orientation should be 'x' or 'y'" unless ( $o eq 'x' or $o eq 'y' );
    croak "gridPosition entry '"
      . $self->{grid}->{"${o}_p"}
      . "' is not an array reference"
      unless ref $self->{grid}->{"${o}_p"} eq 'ARRAY';
    croak "anchor entry is not a hash reference" unless ref $anchor eq 'HASH';
    croak "formatting hash reference is not a hash reference"
      unless ref $f eq 'HASH';
    croak "gridCount '" . $self->{grid}->{"${o}_c"} . "' should be an integer"
      if $self->{grid}->{"${o}_c"} =~ /\D+/;

    #handle each grid position one at a time
    my $i    = 0;
    my $tick = $self->getTick( $f->{labels}, $o );

    foreach $i ( 0 .. $self->{grid}->{"${o}_c"} - 1 ) {

        #we only draw if the position data is defined
        last unless defined $self->{grid}->{"${o}_p"}->[$i];

        #y-value of the constant-y grid line
        $anchor->{line}->comment("Gridlines $i for $o");
        $self->drawGridLine( $o, $i, { anchor => $anchor->{line}, }, );
        $anchor->{label}->comment("Labels $i for $o");
        $self->drawGridLabel( $o, $i, { anchor => $anchor->{label}, }, );
        $anchor->{tick}->comment("Tick marks $i for $o");
        $self->drawTick( $o, $i, $tick, { anchor => $anchor->{tick}, }, );
    }
    return $i;
}

=head2 drawGridLine()

draw a single grid line

=cut

sub drawGridLine ($$$$) {
    my $self = shift;
    my $o    = shift || 'x';
    my $i    = shift;
    my $args = shift;

    #set the data values into the object for future use
    # $self->{grid}->{line}->{dx}
    # $self->{grid}->{line}->{dy}
    $self->{grid}->{line}->{"d$o"} =
      defined $self->{grid}->{"${o}_p"}
      ? $self->{grid}->{"${o}_p"}->[$i]
      : ( $self->T->dy1 - $self->T->dy0 ) * $i / $self->{grid}->{"${o}_c"};

    #convert to canvas values and define:
    # $self->{grid}->{line}->{cx}
    # $self->{grid}->{line}->{cy}
    $self->{grid}->{line}->{"c$o"} =
        $o eq 'y'
      ? $self->T->mapY( $self->{grid}->{line}->{"d$o"} )
      : $self->T->mapX( $self->{grid}->{line}->{"d$o"} );

    $args->{anchor}->line(
        y1 => $o eq 'y' ? $self->{grid}->{line}->{cy} : $self->T->cy0,
        x1 => $o eq 'y' ? $self->T->cx0 : $self->{grid}->{line}->{cx},
        y2 => $o eq 'y' ? $self->{grid}->{line}->{cy} : $self->T->cy1,
        x2 => $o eq 'y' ? $self->T->cx1 : $self->{grid}->{line}->{cx},
    );
}

=head2 drawTick()

 $p->drawTick( ['x'|'y'], $index, $tick, $args, %attrs);

tickmark-generation handler

=cut

sub drawTick ($$$$$;@) {
    my $self  = shift;
    my $o     = shift || 'x';
    my $i     = shift;
    my $tick  = shift;
    my $args  = shift;
    my %attrs = @_;

    #do nothing unless the tickmarks are required,
    return undef unless defined $tick;

    #$self->{grid}->{line}->{"d$o"} =  defined $args->{GridPosition} ?
    #		$self->{GridPosition}->[$i] :
    #		($t->dy1 - $t->dy0)*$i/$args->{GridCount};

    #convert to canvas values
    #$self->{grid}->{line}->{"c$o"} = $o eq 'y' ?
    #	$t->mapY($self->{grid}->{line}->{"d$o"} :
    #	$t->mapX($x_line);

    #handle the front and back ticks
    my %hash;
    if ( $tick->[0] ) {
        my ( $x, $y ) = ( $self->T->cx0, $self->T->cy0 );
        %hash = (

            y1 => $o eq 'y' ? $self->{grid}->{line}->{cy} : $y,
            y2 => $o eq 'y' ? $self->{grid}->{line}->{cy} : $y - $tick->[0],
            x1 => $o eq 'y' ? $x : $self->{grid}->{line}->{cx},
            x2 => $o eq 'y' ? $x - $tick->[0] : $self->{grid}->{line}->{cx},
        );
        $args->{anchor}->line( %hash, %attrs );
    }
    if ( $tick->[1] ) {
        my ( $x, $y ) = ( $self->T->cx1, $self->T->cy1 );
        %hash = (

            y1 => $o eq 'y' ? $self->{grid}->{line}->{cy} : $y,
            y2 => $o eq 'y' ? $self->{grid}->{line}->{cy} : $y + $tick->[1],
            x1 => $o eq 'y' ? $x : $self->{grid}->{line}->{cx},
            x2 => $o eq 'y' ? $x + $tick->[1] : $self->{grid}->{line}->{cx},
        );
        $args->{anchor}->line( %hash, %attrs );
    }
}

=head2 drawGridLabel()

grid lable generator 

=cut

sub drawGridLabel ($$$$) {
    my $self = shift;
    my $o    = shift;
    my $i    = shift;
    my $args = shift;

    my $c      = $self->{grid}->{line}->{"c$o"};
    my $d      = $self->{grid}->{line}->{"d$o"};
    my $string =
      defined $args->{grid}->{"${o}_u"}
      ? $self->{grid}->{"${o}_l"}->[$i] . " " . $args->{grid}->{"${o}_u"}
      : $self->{grid}->{"${o}_l"}->[$i];

    #decide what to print as a gridline label
    my $thistext = defined $self->{grid}->{"${o}_l"}
      ?    #if labels are defined
      $string
      : $self->{grid}->{line}->{"d$o"};    #use data positions instead
    $thistext =~ s/\s$//;

    return $o eq 'y'
      ? $args->{anchor}
      ->text( y => $self->{grid}->{line}->{cy}, x => $self->T->cx0, )
      ->cdata($thistext)
      : $args->{anchor}
      ->text( x => $self->{grid}->{line}->{cx}, y => $self->T->cy0, )
      ->cdata($thistext);

    #	$args->{anchor}->line(
    #		y1=> $o eq 'y' ? $self->{grid}->{line}->{cy} : $t->cy0,
    #		x1=> $o eq 'y' ? $t->cx0 : $self->{grid}->{line}->{cx},
    #		y2=> $o eq 'y' ? $self->{grid}->{line}->{cy} : $t->cy1,
    #		x2=> $o eq 'y' ? $t->cx1 : $self->{grid}->{line}->{y},
    #		);

}

=head2 getTick($label_ref $oation)

return the front and back extensions to lines based on the definition (or lack of) tickmarks in the label construct

Example of a label definition: 

    $label = {
        'y_ticks' => {
             'style' => {
                  'right' => '10'
              },
             'position' => [
                  '150',
                  '100',
                  '0',
                  '-75'
              ],
             'label' => [
                  'Much',
                  'Some',
                  'None',
                  'Lost'
              ]
         },
         'x_ticks' => {}
     };

=cut

sub getTick($$$) {
    my $self = shift;
    my $l    = shift;
    my $o    = shift;
    $o = lc($o);
    $o = 'x' unless $o eq 'y';

    my $extender = [ 0, 0 ];

    return undef unless defined $l->{"${o}_ticks"}->{style};

    my %map = (
        x => [ 'top',  'bottom' ],
        y => [ 'left', 'right' ]
    );

    my $one = $map{$o}->[0];
    my $two = $map{$o}->[1];

    #handle constant-x (vertical) gridlines
    $extender->[0] =
      defined $l->{"${o}_ticks"}->{style}->{$one}
      ? $l->{"${o}_ticks"}->{style}->{$one}
      : 0;
    $extender->[1] =
      defined $l->{"${o}_ticks"}->{style}->{$two}
      ? $l->{"${o}_ticks"}->{style}->{$two}
      : 0;
    return $extender;
}

=head2 D

$self->D()

returns the SVG Document object

=cut

sub D ($) {
    my $self = shift;
    return $self->{_svgTree_};
}

=head2 T($name)

$self->T($name)

returns the currently invoked transformation object. Returns transformation object $name if requested by name

=cut

sub T ($;$) {
    my $self = shift;
    my $name = shift;
    return $self->{maps}->{$name} if defined $name;
    return $self->{map};
}

=head2 setGraphTarget $targetid, $elementType <rect>, %element_attributes

define the graph target (currently only rectangles are accepted) on top of which the data will be drawn

=cut

sub setGraphTarget ($$;@) {
    my $self = shift;
    $self->{graphTarget} = shift || $self->mapTemplateId('rectangle.graph.data.space');
    my $type = shift || 'rect';
    return $self->_gg( $self->{graphTarget}, $type, @_ );
}

=head2 getGraphTarget

returns the current graph target

=cut

sub getGraphTarget ($) {
    my $self = shift;
    return $self->{graphTarget};
}

=head2 autoGrid (int $min, int $max, int $count)

generates a reference to an array of $count+1 evenly distributed values ranging between $min and $max  

	$tt->autoGrid(0,100,10);

=cut

sub autoGrid ($$$) {
    my $self = shift;
    my ( $min, $max, $count ) = @_;
    my @array = ( 0 .. $count );
    map { $_ = ( $max - $min ) / ($count) * $_ } @array;

    #print STDERR Dumper \@array;
    return \@array;
}

=head2 Format

format an array of values according to formatting rules

 $tt->Format \@array,$format,$format_attribute[,@more_format_attributes]

 $format can be 'time' or 'printf'

for 'time', uses the Time::localtime 

example 1: formatting to print the verbose date

 $a = [
   '0',
   '2.75',
   '5.5',
   '8.25',
   '11'
 ];

 my $b = $tt->Format($a,'time',"%a %b %e %H:%M:%S %Y");
 
returns 

 $b = [
   'Thu Jan  1 01:00:00 1970',
   'Thu Jan  1 01:00:02 1970',
   'Thu Jan  1 01:00:05 1970',
   'Thu Jan  1 01:00:08 1970',
   'Thu Jan  1 01:00:11 1970'
 ];

Format uses POSIX function b<strftime> 
Refer to L<POSIX> for more information on time formating.
 
example 2: formatting to print to three decimal places using sprintf
 
 $tt->Format([1.123,2.1234,3.12345,4.123456],'sprintf','%.3f'); 

example 3: formatting to print a percent sign
 
 $tt->Format([1.123,2.1234,3.12345,4.123456],'sprintf','%%'); 


=cut

sub Format ($$$;@) {
    my $self   = shift;
    my $array  = shift;
    my $format = shift || 'sprintf';
    my $fmt    = shift || '%.3f';
    my @attrs  = @_;
    if ( $format eq 'time' ) {
        map { $_ = strftime( $fmt, _getLocalTime($_) ) } @$array;
    } elsif ( $format eq 'printf' ) {
        map { $_ = printf( $fmt, $_ ) } @$array;
    } elsif ( $format eq 'sprintf' ) {
        map { $_ = sprintf( $fmt, $_ ) } @$array;
    } else {
        print STDERR "processing default\n";
    }
    return $array;
}

sub _getLocalTime ($) {
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) =
      localtime(shift @_);
    return ( $sec, $min, $hour, $mday, $mon, $year , $wday, $yday,
        $isdst );
}

=head2 mapTemplateId string $id

=cut 

sub mapTemplateId ($$) {
	my $self = shift;
	my $myid = shift;
	unless (defined $myid) {
		carp "undefined xml ID! Setting to 'unknown'" . join (":",caller()) ;
		$myid = 'unknown';
		$self->{_IDMap_}->{$myid} = $myid;
	}
	unless ($self->{_IDMap_}->{$myid}) {
		carp "Undeclared xml ID $myid! Adding to ID list";
		$self->{_IDMap_}->{$myid} = $myid;
	}
#	getIdMap unless $self->{_IDMap_};
	print STDERR "$myid = $self->{_IDMap_}->{$myid}\n";
	return $self->{_IDMap_}->{$myid} || $myid;
}

=head2 setTemplateIdMap hash template_pairs

assign the definitions between the internal keys and the ids in the template at hand.
This method need not be called as all IDs automatically get run through if the default IDs specified below are used.

=cut


sub setTemplateIdMap ($@) {
	my $self = shift;
	my %TemplateMap = @_;
	$self->{_IDMap_} = \%TemplateMap; 
}

=head2 simpleGraph string $id, string $type, hash %attrs

=cut

sub simpleGraph ($$$@) {
    my $self  = shift;
    my $id    = shift;
    my $type  = shift;
    my %attrs = @_;
    my $d     = $self->D;

    my $g = $d->group( id => $id, 'text-anchor' => 'middle' );
    $g->comment(
        "drawing element which defines the graph boundaries for graph $id");
    my $graph = $g->rect(%attrs);
    my $cy    = $graph->getAttribute('x') + $graph->getAttribute('width') / 2;
    my $cx    = $graph->getAttribute('y') / 2;
    $g->group(
        id        =>$self->mapTemplateId("group.graph.title"),
        class     =>$self->mapTemplateId("group.graph.title"),
        transform => "translate($cx,$cy)",
    )->comment("the graph title");
    my $t = $g->group( id =>$self->mapTemplateId("group.trace"), );
    $t->comment("the trace group");
    $t->group(
        id        =>$self->mapTemplateId("group.trace.1"),
        class     =>$self->mapTemplateId("group.trace"),
        transform => "translate($cx,$cy)",
    )->comment("trace 1");

    $t->group(
        id    =>$self->mapTemplateId("group.trace.title.1"),
        class =>$self->mapTemplateId("group.trace.title"),
    )->comment("the trace title");
    $t->group(
        id    =>$self->mapTemplateId("group.trace.tick.1"),
        class =>$self->mapTemplateId("group.trace.tick"),
    )->comment("the trace ticks");
    my $a = $t->group(
        id    =>$self->mapTemplateId("group.trace.axes.1"),
        class =>$self->mapTemplateId("group.trace.axes"),
    );
    $a->group(
        id    =>$self->mapTemplateId("group.trace.axes.x.1"),
        class =>$self->mapTemplateId("group.trace.axes.x"),
    )->comment("the trace x axes");
    $a->group(
        id    =>$self->mapTemplateId("group.trace.axes.y.1"),
        class =>$self->mapTemplateId("group.trace.axes.y"),
    )->comment("the trace y axes");
    $a->group(
        id    =>$self->mapTemplateId("group.trace.axes.values.x.1"),
        class =>$self->mapTemplateId("group.trace.axes.values.x"),
    )->comment("the trace axes values in y axis");
    $a->group(
        id    =>$self->mapTemplateId("group.trace.axes.values.y.1"),
        class =>$self->mapTemplateId("group.trace.axes.values.y"),
    )->comment("the trace axes values in y axis");

    $a->group(
        id    =>$self->mapTemplateId("group.trace.axes.titles.x.1"),
        class =>$self->mapTemplateId("group.trace.axes.titles.x"),
    )->comment("the trace axes titles in x axis");
    $a->group(
        id    =>$self->mapTemplateId("group.trace.axes.titles.y.1"),
        class =>$self->mapTemplateId("group.trace.axes.titles.y"),
    )->comment("the trace axes titles in y axis");
}

my $dump = qq {<rect "/>
<group id="group.graph.title"/>
<!-- trace insertion takes place here -->
<g id="group.trace.1" fill="none"
                stroke="black" stroke-width="2">
<group id="group.trace.title.1"/>
                     <!-- draw the data below the gridlines -->
                     <g id="group.trace.data.1"
                        stroke="#333333" stroke-width="0.5"
                        fill="#411DA4"/>
                     <g id="group.trace.grid.1"
                        stroke="gray" stroke-width="1"/>
                     <g id="group.trace.tick.1"
                        stroke="black" stroke-width="1.5"/>
                     <g id="group.trace.axes.1"
                        stroke="none" fill="black">
                             <g id="group.trace.axes.x.1" stroke="gray"
                                fill="none" stroke-width="1"/>
                             <g id="group.trace.axes.y.1" stroke="gray"
                                fill="none" stroke-width="1"/>
                             <g id="group.trace.axes.values.x.1" text-anchor="middle"
                                stroke="none" fill="black" transform="translate(0,265)"/>
                             <g id="group.trace.axes.values.y.1" stroke="none"
                                fill="black" text-anchor="start" transform="translate(-40,0)"/>
                             <g id="group.trace.axes.title.x.1" text-anchor="middle"
                                transform="translate(365,370)" font-size="12"
                                fill="#411DA4" font-weight="Bold"/>
                             <g id="group.trace.axes.title.y.1.c" text-anchor="end"
                                transform="translate(40,200)">
                                     <g id="group.trace.axes.title.y.1"
                                        transform="rotate(-90)" font-weight="Bold"
                                        font-size="12" fill="#411DA4"/>
                             </g>
                     </g>
             </g>
         <!-- end of trace insertion 1 -->

};

#module placeholder
1;

=head2 TEMPLATE

To draw a graph, a template is required which contains two key datasets: a rectangle which will contain the inserted graph data and a group containing child group elements with the IDs expected by SVG::Template::Graph


=head3 REQUIRED RECT ELEMENT



=head3 REQUIRED GRAPH TRACE HANDLER

The svg snippet below provides the required groups for the generation of the first trace (trace intex 0)

Because SVG uses the Painter's model, the image rendering order 
follows the XML document order. For the snippet below, 
the rendering order is the following:

 data,grid,ticks,
 axes:x,y,
 axes values:
 x,y,
 axes text:
 x,y,
 axes titles:
 x,y

Trace generation snippet

  <!-- trace insertion takes place here -->
      <g id="group.trace.1" fill="none"
         stroke="black" stroke-width="2">
              <!-- draw the data below the gridlines -->
              <g id="group.trace.data.1"  
                 stroke="#333333" stroke-width="0.5" 
                 fill="#411DA4"/>
              <g id="group.trace.grid.1" 
                 stroke="gray" stroke-width="1"/>
              <g id="group.trace.tick.1" 
                 stroke="black" stroke-width="1.5"/>
              <g id="group.trace.axes.1" 
                 stroke="none" fill="black">
                      <g id="group.trace.axes.x.1" stroke="gray" 
                         fill="none" stroke-width="1"/>
                      <g id="group.trace.axes.y.1" stroke="gray" 
                         fill="none" stroke-width="1"/>
                      <g id="group.trace.axes.values.x.1" text-anchor="middle" 
                         stroke="none" fill="black" transform="translate(0,265)"/>
                      <g id="group.trace.axes.values.y.1" stroke="none" 
                         fill="black" text-anchor="start" transform="translate(-40,0)"/>
                      <g id="group.trace.axes.title.x.1" text-anchor="middle" 
                         transform="translate(365,370)" font-size="12" 
                         fill="#411DA4" font-weight="Bold"/>
                      <g id="group.trace.axes.title.y.1.c" text-anchor="end" 
                         transform="translate(40,200)">
                              <g id="group.trace.axes.title.y.1" 
                                 transform="rotate(-90)" font-weight="Bold" 
                                 font-size="12" fill="#411DA4"/>
                      </g>
              </g>
      </g>
  <!-- end of trace insertion 1 -->

In order to show the trace in front of the gridlines, the above snippet changes to:

  <!-- trace insertion takes place here -->
      <g id="group.trace.1" fill="none"
         stroke="black" stroke-width="2">
              <g id="group.trace.grid.1"
                 stroke="gray" stroke-width="1"/>
              <g id="group.trace.tick.1"
                 stroke="black" stroke-width="1.5"/>
              <g id="group.trace.axes.1"
                 stroke="none" fill="black">
                      <g id="group.trace.axes.x.1" stroke="gray"
                         fill="none" stroke-width="1"/>
                      <g id="group.trace.axes.y.1" stroke="gray"
                         fill="none" stroke-width="1"/>
                      <g id="group.trace.axes.values.x.1" text-anchor="middle"
                         stroke="none" fill="black" transform="translate(0,265)"/>
                      <g id="group.trace.axes.values.y.1" stroke="none"
                         fill="black" text-anchor="start" transform="translate(-40,0)"/>
                      <g id="group.trace.axes.title.x.1" text-anchor="middle"
                         transform="translate(365,370)" font-size="12"
                         fill="#411DA4" font-weight="Bold"/>
                      <g id="group.trace.axes.title.y.1.c" text-anchor="end"
                         transform="translate(40,200)">
                              <g id="group.trace.axes.title.y.1"
                                 transform="rotate(-90)" font-weight="Bold"
                                 font-size="12" fill="#411DA4"/>
                      </g>
              </g>
              <!-- draw the data on top of the gridlines -->
              <g id="group.trace.data.1" stroke="#333333" stroke-width="0.5" fill="#411DA4"/>
      </g>
  <!-- end of trace insertion 1 -->


=head2 EXAMPLES

Refer to the examples directory inside this distribution for working examples.

=head1 SEE ALSO

L<SVG::Parser> L<SVG::Manual> L<Expat> L<SAX> L<SVG::TT:Graph> L<Tramsform::Canvas>
L<http://www.roitsystems.com> L<http://www.roitsystems.com>

=head1 AUTHOR

Ronan Oger, E<lt>ronan.oger@roitsystems.com<gt> L<http://www.roitsystems.com> L<http://www.roitsystems.com>

=head1 CREDITS

This library was developed and written by Ronan Oger, ROIT Systems Gmbh,  under contract to Digital Craftsmen.

=head1 COPYRIGHT

Copyright (C) 2004 by Ronan Oger, ROIT Systems GmbH, Zurich, Switzerland

Copyright (C) 2004 by Digital Craftsmen Ltd, London, UK

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;

__END__
