# -*- Perl -*-
# PostScript::Elements.pm
# An object for representing lines, circles, boxes, and images 
# such that they can be easily output as PostScript code.
#
# You may distribute this under the same terms as Perl
# itself.
#

PostScript::Elements::VERSION = '0.06';

package PostScript::Elements;
use strict;

# @paramnames is the list of valid parameters,
# %defaults is the hash of default values for those parameters.
#
my @paramnames = qw( type points linewidth linetint filltint );
my %defaults = (
                linewidth => 1,   # 1 pt  
	        filltint  => -1,  # -1 represents transparent
                linetint  => 0,   # 0 == black, 1 = white
               );

sub new {
    # The constructor method.
    # An Element object can be one or more lines, circles, 
    # boxes or images.
    #
    my $class = shift;
    my $self = [];       
    
    bless($self,$class);
    return $self;
}


sub addType {
    # A general routine for adding lines, circle, box, or
    # image objects to an Element.
    #
    my $self = shift;
    my %params = @_;
    
    # If a parameter is not specified, use the default...
    #
    foreach (@paramnames) {
        $params{$_} = $defaults{$_} unless (defined($params{$_}));
    };
 
    # Add the object to the current element
    #
    push @$self, { type      => $params{'type'},
                   points    => $params{'points'},
	           linewidth => $params{'linewidth'},
	           filltint  => $params{'filltint'},
                   linetint  => $params{'linetint'},
                 };
}

sub addArc {
    # Add an arc to the Element.
    # A points parameter is required, consisting of a reference to
    # list specifying the center coordinate, the radius 
    # of the arc, and two numbers specifying the starting angle 
    # and the ending angle describing the sweep of the arc. E.g.:
    # addArc(points=>[50,50,25,0,360]) 
    # would add a complete circle centered at 50,50 with a radius of 25.
    #
    my $self = shift;
    $self->addType(type => 'arc', 
                   @_);
}


sub addBox {
    # Add a Box to the Element.
    # The points parameter should consist of the upper left coordinate
    # of the box, its width, and its height.
    #
    my $self = shift;
    $self->addType(type => 'box', 
                   @_);
}


sub addLine {
    # Add a Line to the Element. 
    # The points parameter should contain the starting coordinate and
    # the end coordinate.
    #
    my $self = shift;
    $self->addType(type => 'line', 
                   @_);
}


sub Write() {
    # A method to create the PostScript code that will render the 
    # objects in the Element.
    #
    my $self = shift;
    my $returnval = "";
    my ($width, $height);    


    foreach my $element (@$self) {
        
	# Generate the appropriate PostScript based on the 
	# type attribute.
	# Arc:
        if ($element->{type} =~ /arc/i) {
	     # First save the current path (if any),
	     # then create the path of the arc
	     #
             $returnval .= "gsave\n".
                            $element->{'points'}->[0]." ".   # x value
                            $element->{'points'}->[1]." ".   # y value
	                    $element->{'points'}->[2]." ".   # radius
	                    $element->{'points'}->[3]." ".   # start angle 
	                    $element->{'points'}->[4]." ".   # end angle 
	                    "arc\n";
             # Don't fill the arc if filltint attribute is -1
	     # otherwise fill the current path with the tint specified by
	     # the filltint attribute. Save the path so it can be restored
	     # after the fill and it can be used by the stroke function.
	     #
             if ($element->{'filltint'} >= 0 ) {
	         $returnval .= $element->{'filltint'}." setgray\n". 
                               "gsave \nfill \ngrestore\n";
	     }
	     
	     # Stroke the arc with the width indicated by linewidth 
	     # and a greyscale percentage specified by linetint
	     #
	     $returnval .= $element->{'linetint'}." setgray\n".
	                   $element->{'linewidth'}." setlinewidth\n".
	                   "stroke\n".
                           "1 setgray\n".
	                   $defaults{'linewidth'}." setlinewidth\n".
                           "grestore\n";
       
        # Box:
	#
        } elsif ($element->{type} =~ /box/i) {
             # A box is described by the upper left corner, a width
             # and a height
             # 
             $width = $element->{'points'}->[2];
             $height = $element->{'points'}->[3];

             $returnval .= "gsave\n";
             $returnval .= $element->{'points'}->[0]." ".   # x value
                           $element->{'points'}->[1]." ".   # y value
                           "moveto\n".
                           # now draw it clockwise...
                           #
                           "$width 0 rlineto\n".
                           "0 ".(0-$height)." rlineto\n".
                           (0-$width)." 0 rlineto\n".
                           "0 $height rlineto\n".
                           "closepath\n";
             # Don't fill the box if filltint attribute is -1
	     #
             if ($element->{'filltint'} >= 0 ) {
	         $returnval .= $element->{'filltint'}." setgray\n". 
                               "gsave \nfill \ngrestore\n";
	     }
	     $returnval .= $element->{'linetint'}." setgray\n".
	                   $element->{'linewidth'}." setlinewidth\n".
	                   "stroke\n".
                           "1 setgray\n".
	                   $defaults{'linewidth'}." setlinewidth\n".
                           "grestore\n";

        # Line:
	#
        } elsif ($element->{type} =~ /line/i) {

             $returnval .= "gsave\n";
             $returnval .= $element->{'points'}->[0]." ".   # start x 
                           $element->{'points'}->[1]." ".   # start y
                           "moveto\n".
                           $element->{'points'}->[2]." ".   # end x
                           $element->{'points'}->[3]." ".   # end y
                           "lineto\n".
	                   $element->{'linetint'}." setgray\n".
	                   $element->{'linewidth'}." setlinewidth\n".
	                   "stroke\n".
                           "1 setgray\n".
	                   $defaults{'linewidth'}." setlinewidth\n".
                           "grestore\n";


        } else {
          # Do nothing
        }
    }
    return ($returnval);
}



1;

__END__


=head1 NAME

PostScript::Elements - Generate PostScript code for circles, boxes, lines

=head1 DESCRIPTION

An object for representing lines, circles, boxes, and images 
such that they can be easily output as PostScript code.

=head1 SYNOPSIS



=head1 AUTHOR



=cut

