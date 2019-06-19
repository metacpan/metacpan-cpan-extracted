package Tcl::pTk::Canvas;

our ($VERSION) = ('1.00');

# Simple Canvas package.
#  This is here just so widgets can subclass from a canvas before actually creating a canvas
# Also to provide some compatibility functions with perl/tk
@Tcl::pTk::Canvas::ISA = ('Tcl::pTk::Widget');


## Wrapper for the canvas index command.
##  This translates indexes that are array ref form (e.g. [10,20]) into tcl index form 
##     (e.g. '@10,20'), for compatibility with perl/tk
sub index{
        my $self  = shift;
        my $id    = shift;
        my $index = shift;
        
        if( ref($index) and ref($index) eq 'ARRAY'){ 
                $index = '@'.join(",",@$index);
        }
        
        $self->interp->icall($self->path, 'index', $id, $index);
}

#### Wrappers for the canvas item create methods ###############
# These directly call invoke for speed. If these methods weren't present,
#  the normal tcl/tk mapping process would be used, which is more general case, but slow
## Note: This means that -updatecommand won't work properly if supplied at creation
#        If this is really needed, it can be set later with an itemConfigure call.
##
{ 
        no warnings 'uninitialized'; # This is to keep from getting "use of initialized variable in subroutine entry"
                                     #  warnings when a create item method has an option that is undef.
                                     #  For example $canvas->createOval(0,12,30,10, -fill => undef) would cause a warning
                                     #   before this was added.

        sub createArc{
                my $self = shift;
                $self->interp->invoke($self, 'create', 'arc', @_);
        }
        
        sub createBitmap{
                my $self = shift;
                $self->interp->invoke($self, 'create', 'bitmap', @_);
        }
        
        sub createGrid{
                my $self = shift;
                        $self->interp->invoke($self, 'create', 'grid', @_);
        }
        
        sub createImage{
                my $self = shift;
                $self->interp->invoke($self, 'create', 'image', @_);
        }
        
        sub createLine{
                my $self = shift;
                $self->interp->invoke($self, 'create', 'line', @_);
        }
        
        sub createOval{
                my $self = shift;
                $self->interp->invoke($self, 'create', 'oval', @_);
        }
        
        sub createPolygon{
                my $self = shift;
                $self->interp->invoke($self, 'create', 'polygon', @_);
        }
        
        sub createRectangle{
                my $self = shift;
                $self->interp->invoke($self, 'create', 'rectangle', @_);
        }
        
        sub createText{
                my $self = shift;
                
                # for compatibility, accept/translate the justify option to -justify
                my ($x,$y) = (shift, shift);
                my %options = @_;
                if( defined($options{justify})){
                        $options{-justify} = delete $options{justify};
                        @_ = %options;
                }
                $self->interp->invoke($self, 'create', 'text', $x,$y, @_);
        }
        
        sub createWindow{
                my $self = shift;
                $self->interp->invoke($self, 'create', 'window', @_);
        }

}

# Item cget used here (rather than autoloaded) so we can return Font objects
#   if -font requested
sub itemcget {
    my $self = shift;
    my $id   = shift;
    my $option = shift;
    
    if( $option eq '-font'){
            my $name = $self->call($self->path, 'itemcget', $id, $option);
            if( $name){
                    # Turn font name into an object
                    #  (We don't create a font object here, because the font already exists)
                    my $obj = bless {name => $name, interp => $self->interp}, 'Tcl::pTk::Font';
                    return $obj;
            }
            return $name;
    }
    
    $self->call($self->path, 'itemcget', $id, $option);
}
# Returns the bounding box in Canvas coordinates of the visible portion of the Canvas.
#  (Written by Slaven Rezic.) Copied from perl/tk
sub get_corners
{
    my $c = shift;
    my(@xview) = $c->xview;
    my(@yview) = $c->yview;
    my(@scrollregion) = @{$c->cget(-scrollregion)};
    return (
     $xview[0] * ($scrollregion[2]-$scrollregion[0]) + $scrollregion[0],
     $yview[0] * ($scrollregion[3]-$scrollregion[1]) + $scrollregion[1],
     $xview[1] * ($scrollregion[2]-$scrollregion[0]) + $scrollregion[0],
     $yview[1] * ($scrollregion[3]-$scrollregion[1]) + $scrollregion[1],
    );
}
1;

