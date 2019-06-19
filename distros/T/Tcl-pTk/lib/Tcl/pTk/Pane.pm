# Tk::Pane.pm
#

# Dummy package declaration for Scrollable Frame, to avoid warning messages
#   when we set the Tcl::pTk::Pane::ISA below
#
package Tcl::pTk::ScrollableFrame;

package Tcl::pTk::Pane;

our ($VERSION) = ('1.00');

use Tcl::pTk;
use Tcl::pTk::Widget;
use Tcl::pTk::Derived;

use Carp (qw/ croak /);

use strict;

#use base qw(Tcl::pTk::Derived Tcl::pTk::ScrollableFrame);
@Tcl::pTk::Pane::ISA = (qw/ Tcl::pTk::Derived Tcl::pTk::ScrollableFrame /);

Tcl::pTk::Widget->Construct('Pane');

# Setup binding so the scrollwheel works
sub ClassInit
{
 my ($class,$mw) = @_;
 $class->SUPER::ClassInit($mw);


 $mw->MouseWheelBind($class);
}


sub Populate {
    my( $cw, $args ) = @_;

    $cw->SUPER::Populate( $args );

    #### Setup options ###
    
    # Get native options first and turn into data to feed configSpaces
    my @nativeOptions = $cw->Tcl::pTk::Widget::configure();
    my %configSpecs;
    foreach my $optElement(@nativeOptions){
            my $name = $optElement->[0];
            my @optData = ('SELF', @$optElement[1..3]);
            
            # Change any '{}' that shows up for scrollcommands to undefs
            #   Without this, configure is called with something like "-yscrollcommand => '{}'", which
            #    causes problems
            $optData[3] = undef if( defined($optData[3]) && $optData[3] eq '{}');
            
            # Remove any options surrounded by brackets (e.g. change '{#d9d9d9}' to '#d9d9d9'). The brackets
            #  cause problems when calling tcl configure (e.g. '.window configure -background {#d9d9d9} causes problems
            if( defined($optData[3]) ){
                    $optData[3] =~ s/^\s*\{//;
                    $optData[3] =~ s/\}$//;
            }
            
            $configSpecs{$name} = [@optData];
    }
                    
    #  gridded and sticky are here to emulate the original Tk::Pane version
    #  They don't do anything in this widget
    $cw->ConfigSpecs(
        -gridded         => [qw/PASSIVE gridded gridded/, undef],
        -sticky         =>  [qw/PASSIVE sticky sticky/, undef],
        %configSpecs
    );
    
    # The frame widget of the BWidget ScrollableFrame is our default delegate
    #   for any methods
    my $frame = $cw->getframe;
    $frame = $cw->interp->declare_widget($frame, 'Tcl::pTk::Frame'); # turn path name into widget

    $cw->Advertise('frame', $frame); 
    
    $cw->Delegates('Construct' => $frame,
                   );

    $cw->ConfigSpecs(DEFAULT => [$frame],
                     );
    
    $cw->focus(); # This ensure that mousewheel event will work on win32
                  #  i.e. mousewheel events are routed to the widget with focus


}


# Manager wrapper method supplied here so that $cw->manager calls in Default method of Tcl::pTk::Frame.pm
#  Doesnt't get delegated to the frame
sub manager{
        my $self = shift;
        $self->Tcl::pTk::Widget::manager(@_);
}

sub frame{
        my $self = shift;
        return $self->Subwidget('frame');
}

####### Wrapped see method ######
# For compatibility with the original Tk::Pane, any -anchor options are translated
#  to their equivalent horix and vert components of the wrapped ScrollableFrame widget
sub see{
      my $self = shift;
      my @origArgs = @_;
      my $widget = shift;
      my @args = @_;
      
      
      # Find any -anchor option
      my $anchor;
      my $lastAnchor; # flag = 1 if the previous arg was anchor
      my $lastArg;
      my @newArgs;  # Args to supply to the wrapped see method
      foreach my $val(@args){
              if( $val eq '-anchor'){
                      $lastAnchor = 1;
                      next;
              }
              if( $lastAnchor ){
                      $anchor = $val;
                      $lastAnchor = 0;
                      next;
              }
              $lastAnchor = 0;
              push @newArgs, $val;
      }
      
      # Error checking. Should have just two or less args at this point
      unless( @newArgs <= 2){
              croak("Invalid args supplied to Tcl::pTk::Pane::see args =  ",join(", ", @args));
      }
      
      # Translate anchor to horiz / vert
      if( $anchor ){
              # Mapping of anchor to horiz/vert args
              my %anchorLookup = (
                      'n'  =>  [qw/ top /],
                      's'  =>  [qw/ bot /],
                      'e'  =>  [qw/ right /],
                      'w'  =>  [qw/ left /],
                      'nw' =>  [qw/ top left  /],
                      'ne' =>  [qw/ top right /],
                      'sw' =>  [qw/ bot left  /],
                      'se' =>  [qw/ bot right /],
                    );
              my $anchorTrans = $anchorLookup{$anchor};
              unless( defined( $anchorTrans ) ){
                      croak("Invalid -anchor arg $anchor supplied to Tcl::pTk::Pane::see");
              }
              
              # Call inherited see with translated anchor args
              $self->SUPER::see($widget, @$anchorTrans);
      }
      else{
              # Call inherited see with horiz/vert args
              $self->SUPER::see($widget, @newArgs);
      }
}
              
              
              

##### Overridded CreateArgs  #######
#  This ensures the ignored options -sticky and -gridded aren't supplied to the
#   wrapped ScrollableFrame widget at creation time.
sub CreateArgs{
        my $class = shift;
        my ($parent, $args) = @_;
        
        # Split up args to create and non-create categories
        #  (non-create are the -sticky and -gridded options)
        my %createArgs;
        my %nonCreateArgs;
        foreach my $opt( keys %$args){
                if( $opt eq '-gridded' || $opt eq '-sticky'){
                        $nonCreateArgs{$opt} = $args->{$opt};
                }
                else{
                        $createArgs{$opt} = $args->{$opt};
                }
        }
        
        %$args = %nonCreateArgs;
        return (%createArgs);
}


1;

__END__

=head1 NAME

Tcl::pTk::Pane - A window panner

=for category Derived Widgets

=head1 SYNOPSIS

    use Tcl::pTk::Pane;

    $pane = $mw->Scrolled(Pane, Name => 'fred',
	-scrollbars => 'soe',
    );

    # Add some widgets
    $pane->Label()->pack;
    $pane->Label()->pack;

    # Pack the pane
    $pane->pack;

=head1 DESCRIPTION

B<Tcl::pTk::Pane> provides a scrollable frame widget. Once created it can be
treated as a frame, except it is scrollable.
        
B<Note:> This L<Tcl::pTk> Implementation of the L<Tk::Pane> widget. It uses the Tcl/Tk I<BWidget> package
I<ScrollableFrame> to approximate the behavoir of the original L<Tk::Pane> widget.
        
B<Limitation>: This widget doesn't recognize the I<-gridded> and I<-sticky> options of the original
L<Tk::Pane> widget. Currently, if these options are ignored.

=head1 OPTIONS

This widget has the same options as the Tcl I<ScrollableFrame> widget, which are repeated below.
        
=over 4

=item B<-areaheight>

Specifies the height for the scrollable area. If zero, then the height of the scrollable area is made just large enough to hold all its children.

=item B<-areawidth>

Specifies the width for the scrollable area. If zero, then the width of the scrollable area window is made just large enough to hold all its children.

=item B<-constrainedheight>

Specifies whether or not the scrollable area should have the same height of the scrolled window. If true, vertical scrollbar is not needed.

=item B<-constrainedwidth>

Specifies whether or not the scrollable area should have the same width of the scrolled window. If true, horizontal scrollbar is not needed.

=item B<-height>
    Specifies the desired height for the window in pixels. 

=item B<-width>
    Specifies the desired width for the window in pixels. 

=item B<-xscrollincrement>
    See xscrollincrement option of canvas widget. 

=item B<-yscrollincrement>
    See yscrollincrement option of canvas widget. 
            

=back

=head1 METHODS

=over 4

=item I<$pane>-E<gt>B<frame>()

Returns the I<Frame> widget that are scrolled. Equivalent to the I<getframe> method
of the wrapped I<ScrollableFrame> widget.

=item I<$pane>-E<gt>B<see>(I<$widget> ?,I<options>?)

Adjusts the view so that I<$widget> is visible. Valid Options are described below.
I<options-value> pairs can be passed, each I<option-value> pair must be
one of the following

B<Note>: For compatibility with the original Tk::Pane widget, the I<-anchor> option translated
to the I<-horiz> and I<-vert> options of the wrapped I<ScrollableFrame> widget.

=over 8

=item B<-anchor> =E<gt> I<anchor>

Specifies how to make the widget visable. If not given then as much of
the widget as possible is made visable.

Possible values are B<n>, B<s>, B<w>, B<e>, B<nw>, B<ne>, B<sw> and B<se>.
This will cause an edge on the widget to be aligned with the corresponding
edge on the pane. for example B<nw> will cause the top left of the widget
to be placed at the top left of the pane. B<s> will cause the bottom of the
widget to be placed at the bottom of the pane, and as much of the widget
as possible made visable in the x direction.

=item B<?vert?> B<?horz?>

I<vert> and I<horz> specify which part of widget must be preferably visible,
in case where widget is too tall or too large to be entirely visible. 
vert must be top (the default) or bottom, and horz must be left (the default) or right.
If vert or horz is not a valid value, area is not scrolled in this direction.

=back

=item I<$pane>-E<gt>B<xview>

Returns a list containing two elements, both of which are real fractions
between 0 and 1. The first element gives the position of  the left of the
window, relative to the Pane as a whole (0.5 means it is halfway through the
Pane, for example). The second element gives the position of the right of the
window, relative to the Pane as a whole.

=item I<$pane>-E<gt>B<xview>(I<$widget>)

Adjusts the view in the window so that I<widget> is displayed at the left of
the window.

=item I<$pane>-E<gt>B<xview>(B<moveto> =E<gt> I<fraction>)

Adjusts the view in the window so that I<fraction> of the total width of the
Pane is off-screen to the left. fraction must be a fraction between 0 and 1.

=item I<$pane>-E<gt>B<xview>(B<scroll> =E<gt> I<number>, I<what>)

This command shifts the view in the window left or right according to I<number>
and I<what>. I<Number> must be an integer. I<What> must be either B<units> or
B<pages> or an abbreviation of one of these. If I<what> is B<units>, the view
adjusts left or right by I<number>*10 screen units on the display; if it is
B<pages> then the view adjusts by number screenfuls. If number is negative then
widgets farther to the left become visible; if it is positive then widgets
farther to the right become visible.

=item I<$pane>-E<gt>B<yview>

Returns a list containing two elements, both of which are real fractions
between 0 and 1. The first element gives the position of  the top of the
window, relative to the Pane as a whole (0.5 means it is halfway through the
Pane, for example). The second element gives the position of the bottom of the
window, relative to the Pane as a whole.

=item I<$pane>-E<gt>B<yview>(I<$widget>)

Adjusts the view in the window so that I<widget> is displayed at the top of the
window.

=item I<$pane>-E<gt>B<yview>(B<moveto> =E<gt> I<fraction>)

Adjusts the view in the window so that I<fraction> of the total width of the
Pane is off-screen to the top. fraction must be a fraction between 0 and 1.

=item I<$pane>-E<gt>B<yview>(B<scroll> =E<gt> I<number>, I<what>)

This command shifts the view in the window up or down according to I<number>
and I<what>. I<Number> must be an integer. I<What> must be either B<units> or
B<pages> or an abbreviation of one of these. If I<what> is B<units>, the view
adjusts up or down by I<number>*10 screen units on the display; if it is
B<pages> then the view adjusts by number screenfuls. If number is negative then
widgets farther up become visible; if it is positive then widgets farther down
become visible.

=back

=head1 AUTHOR

B<Original Code:>
Graham Barr E<lt>F<gbarr@pobox.com>E<gt>

=head1 COPYRIGHT

B<Original Code:>
Copyright (c) 1997-1998 Graham Barr. All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
