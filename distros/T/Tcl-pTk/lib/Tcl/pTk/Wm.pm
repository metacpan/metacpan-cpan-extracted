# Copyright (c) 1995-2003 Nick Ing-Simmons. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

# Adapted for use with Tcl::pTk 9-21-08

package Tcl::pTk::Wm;

our ($VERSION) = ('1.02');

use strict;

use base qw( Tcl::pTk::Derived );

# There are issues with this stuff now we have Tix's wm release/capture
# as toplevel-ness is now dynamic.

Direct Tcl::pTk::Submethods ('wm' => [qw(aspect attributes capture client colormapwindows command
                       deiconify focusmodel frame geometry group
                       iconbitmap iconify  iconphoto iconmask iconname
                       iconwindow maxsize minsize overrideredirect positionfrom
                        release resizable sizefrom state title transient
                       withdraw wrapper )]);

sub SetBindtags
{
 my ($obj) = @_;
 
 # Setting bindtags for popup menus causes the menu items to be inactive on linux, so skip
 return if( $obj->isa('Tcl::pTk::Menu') );
         
 $obj->bindtags([ref($obj),$obj,'all']);
}

sub Populate
{
 my ($cw,$args) = @_;
 $cw->ConfigSpecs('-overanchor' => ['PASSIVE',undef,undef,undef],
                  '-popanchor'  => ['PASSIVE',undef,undef,undef],
                  '-popover'    => ['PASSIVE',undef,undef,undef]
                 );
}

# Sub to move a top-level window using the wmGeometry method
#   This is provided for compatibility with perl/tk
#  Usage:
#    $widget->MoveToplevelWindow($x,$y)
#      where: $x/$y are the coords to move the window to.
sub MoveToplevelWindow
{
 my ($w,$x,$y) = @_;
 $w->interp->icall('wm', 'geometry', $w->path, "+$x+$y");
}

# Implementation of the perl/tk 'iconimage' method. 
# This is translated to an 'iconphoto' call, which is only available
#  in more recent (> 8.5) tk's
sub iconimage{
 my ($w, $photo) = @_;
 $w->interp->icall('wm', 'iconphoto', $w->path, $photo);
}

sub MoveResizeWindow
{
 my ($w,$x,$y,$width,$height) = @_;
 $w->withdraw;
 $w->geometry($width.'x'.$height);
 $w->MoveToplevelWindow($x,$y);
 $w->deiconify;
}

sub WmDeleteWindow
{
 my ($w) = @_;
 my $cb  = $w->protocol('WM_DELETE_WINDOW');
 if (defined $cb)
  {
   $cb->Call;
  }
 else
  {
   $w->destroy;
  }
}

sub Post
{
 my ($w,$X,$Y) = @_;
 $X = int($X);
 $Y = int($Y);
 $w->positionfrom('user');
 $w->geometry("+$X+$Y");
 # $w->MoveToplevelWindow($X,$Y);
 $w->deiconify;
 $w->raise;
 $w->waitVisibility;
}


sub AnchorAdjust
{
 my ($anchor,$X,$Y,$w,$h) = @_;
 $anchor = 'c' unless (defined $anchor);
 $Y += ($anchor =~ /s/) ? $h : ($anchor =~ /n/) ? 0 : $h/2;
 $X += ($anchor =~ /e/) ? $w : ($anchor =~ /w/) ? 0 : $w/2;
 return ($X,$Y);
}

sub Popup
{
 my $w = shift;
 $w->configure(@_) if @_;
 $w->idletasks;
 my ($mw,$mh) = ($w->reqwidth,$w->reqheight);
 my ($rx,$ry,$rw,$rh) = (0,0,0,0);
 my $base    = $w->cget('-popover');
 my $outside = 0;
 if (defined $base)
  {
   if ($base eq 'cursor')
    {
     ($rx,$ry) = $w->pointerxy;
    }
   else
    {
     $rx = $base->rootx;
     $ry = $base->rooty;
     $rw = $base->Width;
     $rh = $base->Height;
    }
  }
 else
  {
   my $sc = ($w->parent) ? $w->parent->toplevel : $w;
   $rx = 0;
   $ry = 0;
   $rw = $w->screenwidth;
   $rh = $w->screenheight;
  }
 my ($X,$Y) = AnchorAdjust($w->cget('-overanchor'),$rx,$ry,$rw,$rh);
 ($X,$Y)    = AnchorAdjust($w->cget('-popanchor'),$X,$Y,-$mw,-$mh);
 # adjust to not cross screen borders
 if ($X < 0) { $X = 0 }
 if ($Y < 0) { $Y = 0 }
 if ($mw > $w->screenwidth)  { $X = 0 }
 if ($mh > $w->screenheight) { $Y = 0 }
 $w->Post($X,$Y);
}

sub FullScreen
{
 my $w = shift;
 my $over = (@_) ? shift : 0;
 my $width  = $w->screenwidth;
 my $height = $w->screenheight;
 $w->GeometryRequest($width,$height);
 $w->overrideredirect($over & 1);
 $w->Post(0,0);
 $w->update;
 if ($over & 2)
  {
   my $x = $w->rootx;
   my $y = $w->rooty;
   $width -= 2*$x;
   $height -= $x + $y;
   $w->GeometryRequest($width,$height);
   $w->update;
  }
}

sub iconposition
{
 my $w = shift;
 if (@_ == 1)
  {
   return $w->wm('iconposition',$1,$2) if $_[0] =~ /^(\d+),(\d+)$/;
   if ($_[0] =~ /^([+-])(\d+)([+-])(\d+)$/)
    {
     my $x = ($1 eq '-') ? $w->screenwidth-$2 : $2;
     my $y = ($3 eq '-') ? $w->screenheight-$4 : $4;
     return $w->wm('iconposition',$x,$y);
    }
  }
 $w->wm('iconposition',@_);
}

#####################################################################################################
# Widget protocol method
# Usage:
#   Getting protocol info
#     @protoNames= $toplevel->protocol();          # returns protocol names that have callbacks associated with them
#     $callback  = $toplevel->protocol($protoName) # return callback (if defined) for the given protocol name
#   Setting protocols:
#     $toplevel->protocol(protoName, sub { ... }); # Make subref into a callback, and associated with the protoName (e.g. WM_DELETE_WINDOW)
sub protocol {
    my $self = shift;
    
    # Make sure this is a toplevel widet
    if ( $self ne $self->toplevel){
            croak("Error in ".__PACKAGE__."::protocol: Supplied widget is not a toplevel");
    }
    
    ### Getting protocol info ###
    if ( scalar(@_) == 0 ){ # No Args supplied: @protoNames= $toplevel->protocol() usage
        return $self->interp->call('wm', 'protocol',$self->path );
    }
    elsif( @_ == 1){  # One arg supplied, must be a protoName: $callback  = $toplevel->protocol($protoName)
        my $protoName = $_[0];
	return $self->{_protocol_}{$protoName};
    }
    
    ### Setting Protocol callbacks ###
    my ($protoName, $callback) = @_;
    
    my $cb;
    my $cbRef;
    $cb = $self->_protocol_helper($callback, $protoName);
    if( defined($callback) && $callback ne ''){ # don't make a subrefif unsetting a protocol (i.e. sub ref is undef or '')
            # Make a subref that will execute the callback
            $cbRef = sub{ 
                        $cb->Call();
            };
                            
    }
    else{
            $cbRef = ''; # When unsetting a binding, set to empty string
    }

    $self->interp->call('wm', 'protocol', $self->path, $protoName, $cbRef);        
     
             
}

############################################################################################

=head2 _protocol_helper

Internal method to process protocol-method callbacks.
        
This creates a L<Tcl::pTk::Callback> object from the callback and stores the object
in the widget's internal data-store, so it can be returned if the protocol callback is queried (for perltk 
compatibility).

B<Usage:>

   my $subref = $self->_protocol_helper($callback, $protoName);


=cut

sub _protocol_helper{
        my $self      = shift;
        my $callback  = shift;
        my $protoName = shift;

        # Make Tcl::pTk::Callback out of callback supplied
        my $cb;
        if( $callback ){ # Create callback object if callback defined and nonempty
                $cb = Tcl::pTk::Callback->new($callback);
        }
        else{
                $cb = undef; # We might be unsetting a callback (with an undef or empty string), so make it undef in either case

        }

        $self->{_protocol_}{$protoName} = $cb; # store in widget data, so it can be recalled
        
        return $cb;

}

############################################################################################

=head2 manage

This implements the Wm manage method, which is new for Tcl/Tk 8.5

This simply calls the Tcl/Tk 'wm manage' command, and then re-blesses the widget
to be a toplevel widget, so other toplevel and Wm methods will work on it.
        
B<Usage:>

   my $toplevel = $widget->Tcl::pTk::Wm::manage();


=cut

sub manage
{
        my $widget = shift;
        $widget->call('wm', 'manage', $widget);
        
        bless($widget, 'Tcl::pTk::Toplevel');
        
        return $widget;
}

#######################################################################

=head2 forget

This implements the Wm manage forget, which is new for Tcl/Tk 8.5

This simply calls the Tcl/Tk 'wm forget' command, and then re-blesses the widget
to be a frame widget.

B<Usage:>

   my $toplevel = $toplevel->forget();


=cut

sub forget
{
        my $widget = shift;
        $widget->call('wm', 'forget', $widget);
        
        bless($widget, 'Tcl::pTk::Frame');
        
        return $widget;
}


1;
