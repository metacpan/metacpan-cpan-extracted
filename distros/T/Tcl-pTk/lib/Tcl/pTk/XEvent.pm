package Tcl::pTk::XEvent;

our ($VERSION) = ('1.02');

use strict;
use warnings;
use Carp;

=head1 NAME

Tcl::pTk::XEvent - Limited Support for perl/tk's XEvent in Tcl::pTk


=head1 SYNOPSIS

        # Create binding on a widget, using XEvent to get
        #   the mouse x/y position
        $widget->bind(
                '<Motion>',
                sub {
                           
                         my $e = $widget->XEvent;
                         
                         # Get mouse x/y position in the widget
                         my $mouseX = $e->x;
                         my $mouseY = $e->y;

                         print "mouse X/Y = $mouseX/$mouseY\n";
                }
                );
 

=head1 DESCRIPTION

I<Tcl::pTk::XEvent> provides (very) limited support for perl/tk's XEvent mechanism in Tcl::pTk. Currently it only provides
support for the I<x> and I<y> calls. Other calls will generate an error message. 
        
For XEvent calls other than I<x> and I<y>, bindings should be converted to use the equivalent I<Ev()> calling as shown below. 
        
=head2 Perl/Tk's XEvent Mechanism

Perl/Tk (L<Tk>) provides an additional method (The XEvent mechanism) to get event information during event processing.
This was added to perl/tk by adding c-code functions (Tk_EventInfo in tkbind.c and others) to the original Tcl/Tk c-code.

Although the XEvent mechanism is not described in the documents included in the perl/tk package, it is used in many places in the
perl/tk code, and in other external perl/tk widgets. The alternative to I<XEvent> is the I<Ev> mechanism, which is documented in the
L<Tk::bind> docs (Binding Callbacks and Substitution section).
        
=head2 Example of XEvent and an Ev Equivalent
        
B<Example of XEvent>

        # Create binding on a widget, using XEvent to get
        #   the mouse x/y position
        $widget->bind(
                '<Motion>',
                sub {
                         my $w = shift;  # Get the event widget
                         my $e = $w->XEvent;
                         
                         # Get mouse x/y position in the widget
                         my $mouseX = $e->x;
                         my $mouseY = $e->y;

                         print "mouse X/Y = $mouseX/$mouseY\n";
                }
                );
 
B<Equivalent Example using Ev() calls>

This is how a XEvent call should be converted to using the Ev() calls, which are fully supported in Tcl/Tk.

        # Create binding on a widget, using Ev calls to get
        #   the mouse x/y position
        $widget->bind(
                '<Motion>',
                [ sub {
                         my $w = shift;  # Get the event widget
                         my ($x, $y) = @_; # Get x/y passed in from the Ev() calls
                         
                         # Get mouse x/y position in the widget
                         my $mouseX = $x;
                         my $mouseY = $y;

                         print "mouse X/Y = $mouseX/$mouseY\n";
                }, 
                   Ev('x'), Ev('y) ]
                
        );


=cut

##################################################
# Constructor method for the XEvent object
#
#  Usage: 
#   $xevent = $widget->XEvent();
#
sub Tcl::pTk::Widget::XEvent{
        
        my $widget = shift;
        
        my $self = bless {'widget' => $widget }, 'Tcl::pTk::XEvent';
        
        return $self;
        
}

##################################################
# Support for the XEvent x call
#
#  Usage: 
#   $x = $xevent->x();
#
sub Tcl::pTk::XEvent::x{
        my $self = shift;
        
        my $widget = $self->{widget};
        
        my $x = $widget->pointerx;
        
        $x -= $widget->rootx;
        return $x;
}
        
##################################################
# Support for the XEvent y call
#
#  Usage: 
#   $y = $xevent->y();
#
sub Tcl::pTk::XEvent::y{
        my $self = shift;
        
        my $widget = $self->{widget};
        
        my $y = $widget->pointery;
        
        $y -= $widget->rooty;
        return $y;
}
     


1;
