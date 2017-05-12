package Postscript::HTML::Map;

# Assumes bounding box

use strict;
use warnings;

use base qw/Class::Accessor::Fast/;

use Data::Dumper;
use HTML::Element;
use Math::Bezier;

__PACKAGE__->mk_accessors(qw/postscript map width height current_x current_y args_stack polygon
                             comments html_handler scale_x scale_y/);

our $VERSION = '1.0001';

my %handlers = (
    BeginEPSF   => undef,
    stroke      => undef, 
    arc         => 'add_arc',
    newpath     => 'create_newpath',
    moveto      => 'perform_move',
    lineto      => 'add_line',
    curveto     => 'add_curve',
    closepath   => 'perform_closepath', # Will need to do more later
    scale       => 'adjust_scaling', # Will need to do more later
    );
my $handler_regex = join '|', keys %handlers;

sub render {
    my ($self) = @_;

    unless ($self->postscript){
        print STDERR "No postscript provided\n";
        return 0;
        }

    unless (-r $self->postscript){
        printf STDERR "Postscript file %s not readable\n", $self->postscript;
        return 0;
        }

    # Ensure we have fresh html output
    $self->map(HTML::Element->new(
        'map'
        ));

    my @postscript;
    do {
        open(my $ps_file, "<".$self->postscript);
        chomp(@postscript = <$ps_file>);
        close $ps_file;

        # Find the Comment that states the bounding box.
        # Working this out from the postscript would be extremely difficult,
        # Due to needing to process all the curves first.
        my ($bounding_definition) = map {
            /^%.*BoundingBox:\s*((?:\d+\s*){4})/ ? $1 : ()
            } @postscript;
        my (undef, undef, $width, $height) = split /\s+/, $bounding_definition;
        $self->width($width);
        $self->height($height);
        };

    $self->current_coords(0, 0);
    $self->args_stack([]);
    $self->polygon([]);
    $self->comments([]);
    $self->scale(1,1);

    while (@postscript){
        if ($postscript[0] =~ /^\s*%/){
            # A comment
            my ($comment) = (shift @postscript) =~ /^\s*%+(.*)/;
            
            $self->comment($comment);

            next;
            }
        unless ($postscript[0] =~ s#^\s*(.*?)\s*($handler_regex)##){
            # Nothing left on this line that interests us
            shift @postscript;
            next;
            }
        my ($args, $cmd) = ($1,$2);

        my $method_name = $handlers{$cmd};
        next unless $method_name;

        my $method = $self->can($method_name);
        next unless $method;
        $self->$method($cmd, $args);
        }

    return $self->map;
    }

sub add_arc {
    my ($self, $cmd, $args) = @_;

    my ($x, $y, $radius, $start_angle, $end_angle) = split / +/, $args;
    if (($start_angle == 0   && $end_angle == 360) ||
        ($start_angle == 360 && $end_angle == 0)){
        # Complete circle, use the circle operator

        $x *= $self->scale_x;
        $y *= $self->scale_y;

        # Radius handling goes crazy if scaling isn't equal, so we assume x
        $radius *= $self->scale_x;

        my $element = HTML::Element->new('area',
            shape   => 'circle', 
            coords  => join(', ', map $_.'px', $x, $self->height - $y, $radius),
            );

        if (ref $self->html_handler){
            $self->html_handler->($self, $element);
            }

        $self->map->push_content($element);
        }
    
    return $self;
    }

sub create_newpath {
    my ($self, $cmd, $args) = @_;

    if ($args){
        # Sometimes we get arguments to this, but they're really intended for the next command
        $self->args_stack_push($args);
        }

    $self->polygon([]);

    return;
    }

sub perform_move {
    my ($self, $cmd, $args) = @_;

    if (!$args){
        # Perhaps there's something in the stack for us?
        $args = $self->args_stack_pop;
        }

    die "moveto without args" unless $args;

    my ($x, $y) = split /\s+/, $args;

    $x *= $self->scale_x;
    $y *= $self->scale_y;

    $self->current_coords($x, $y);

    return;
    }

sub perform_closepath {
    my ($self) = @_;

    if (@{$self->polygon}){

        $self->map->push_content(['area', {
            shape   => 'poly', 
            coords  => join(", ", map $_.'px', @{$self->polygon}),
            href    => 'javascript:alert("'.$self->comment.'");',
            }]);

        $self->polygon([]);
        }

    return;
    }

sub add_curve {
    my ($self, $cmd, $args) = @_;

    die "No args to curveto" unless $args;

    # Bezier Curve
    my ($control1_x, $control1_y,
        $control2_x, $control2_y,
        $end_x, $end_y) = split /\s+/, $args;

    $control1_x *= $self->scale_x;
    $control1_y *= $self->scale_y;
    $control2_x *= $self->scale_x;
    $control2_y *= $self->scale_y;
    $end_x *= $self->scale_x;
    $end_y *= $self->scale_y;

    my $bezier = Math::Bezier->new( 
        $self->current_coords,
        $control1_x, $control1_y,
        $control2_x, $control2_y,
        $end_x, $end_y
        );

    $self->add_to_polygon(
        $bezier->curve(20)
        );

    $self->current_coords($end_x, $end_y);

    return;
    }

sub add_line {
    my ($self, $cmd, $args) = @_;

    die "No co-ordinates for line" unless $args;

    # Firstly, generate the line in the polygon
    $self->add_to_polygon($self->current_coords);

    my ($x, $y) = split /\s+/, $args;

    $x *= $self->scale_x;
    $y *= $self->scale_y;

    $self->add_to_polygon($x, $y);
    
    $self->current_coords($x, $y);

    return;
    }

sub adjust_scaling {
    my ($self, $cmd, $args) = @_;

    die "No scaling provided" unless $args;

    my ($x, $y) = split /\s+/, $args;

    $self->scale($x, $y);

    $self->height( $self->height * $self->scale_y );
    $self->width( $self->width * $self->scale_x );

    return;
    }

sub current_coords {
    my ($self, $x, $y) = @_;

    if ($x && $y){
        $self->current_x($x);
        $self->current_y($y);
        }

    return ($self->current_x, $self->current_y);
    }

sub args_stack_push {
    my ($self, $args) = @_;

    push @{$self->args_stack}, $args;

    return;
    }

sub args_stack_pop {
    my ($self) = @_;

    return pop @{$self->args_stack};
    }

sub add_to_polygon {
    my ($self, @coords) = @_;

    die "Uneven number of co-ordinates adding to polygon" if scalar(@coords) % 2;

    push @{$self->polygon}, @coords;

    return;
    }

sub comment {
    my ($self, $comment) = @_;

    if ($comment){
        push @{$self->comments}, $comment;
        }
    
    return $self->comments->[-1];
    }

sub scale {
    my ($self, $x, $y) = @_;

    if ($x && $y){
        $self->scale_x($x);
        $self->scale_y($y);
        }

    return ($self->scale_x, $self->scale_y);
    }

1;

__END__

=head1 NAME

Postscript::HTML::Map

=head1 SYNOPSIS

 use Postscript::HTML::Map;

 my $ps2map = Postscript::HTML::Map->new({
     postscript     => "car.ps",
     html_handler   => sub {
         my ($self, $element) = @_;

         $element->attr(href => 'javascript:alert("'.$self->comment.'");');

         return;
         },
     });

 my $map = $ps2map->render();
 $map->attr(name => 'car');

 print $map->as_HTML(undef, '    ');

=head1 DESCRIPTION

Postscript::HTML::Map takes a Postscript definition of an image and turns it into an HTML map,
with areas for each closed path.
This module was created for a very specific task: Taking a simply defined postscript image and turning it into a set of areas. The b<LIMITATIONS> are well defined. Patches welcome for any of the large number of things it doesn't handle. Nethertheless, perhaps it will be useful to someone else.

For each closed shape found in the postscript, a new area map is created as an b<HTML::Element>.
$ps2map->html_handler, if specified, is called to transform the area as required, presumably using past comments (see b<comment>).

This is expected to be used in conjunction with a gif generated from the postscript, without margins or cropping. 

=head1 METHODS

=head2 new(html_handler => \&handler, postscript => 'some_file.ps')

Constructs a new Postscript::HTML::Map object. See below for arguments.

=head2 postscript('some_file.ps')

Sets the file from which to read the postscript to be interpretted.
The file should contain a line to state the boundries of the image map required.
% BoundingBox: 0 0 450 300

=head2 html_handler(\&sub_reference)

Called after each area is added, and passed the ps2map object and the HTML::Element for the new area.

Should modify the HTML::Element as required, probably using b<comment>.

The return is igorned.

=head2 render()

Performs the actual rendering of the map, and returns an HTML::Element for further coersion or simple printing.

=head2 comment($comment)

Returns the last comment from a stack of comments seen.
This is for when a section has a comment at the top outlining the geometry below,
which is intended to be used for the href for that area. 

=back

=head1 LIMITATIONS

The postscript operators understood are limited (stroke, arc, newpath, moveto, lineto, curveto, closepath).
It will not understand predefined abbreviations.
It only handles closed shapes.
Anything it 

=head1 COPYRIGHT

Copyright 2008 Thermeon Europe.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful, but without any warranty; without even the implied warranty of merchantability or fitness for a particular purpose.

=head1 AUTHOR

Gareth Kirwan <gbjk@thermeon.com>

=cut
