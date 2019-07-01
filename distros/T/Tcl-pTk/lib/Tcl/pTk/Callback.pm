package Tcl::pTk::Callback;

our ($VERSION) = ('1.02');


use strict;
use warnings;
use Carp;

=head1 NAME

Tcl::pTk::Callback -  Callback Helper class for Tcl::pTk


=head1 SYNOPSIS

        # Create Callback - No Arg Subref form
	$cb = Tcl::pTk::Callback->new(\&lots);
        
        # Create Callback - Subref form, with args
	$cb = Tcl::pTk::Callback->new([\&lots, $arg1, $arg2]);
        
        # Create Callback - Object->Method form, with args
	$cb = Tcl::pTk::Callback->new([ $obj, 'method', $arg1, $arg2]);
        
        # Execute/call the callback, with extra args
        $cb->Call($extraArg1, $extraArg2);

=head1 DESCRIPTION

I<Tcl::pTk::Callback> is a helper class, modeled after I<Tk::Callback> (documented in L<Tk::callbacks> ), that 
provides methods for constructing and executing callbacks for the L<Tcl::pTk> package. 

=head1 ATTRIBUTES

=over 1

=item callback

Array ref of components of the callback. This will be of the form:

 # Subref form
 [ $subref, @args ];  # @args are optional
 
 # Object-Method form
 [ $object, $methodname, @args]; # @args are optional
 
 # methodName form (used for bind callbacks, where the event source widget is used in the call,
 #   $widget->methodName(...)
 ['methodName', @args];  @args are optional
 
=item form

Text indicating what form the callback is in (as defined above). This will be I<subref> or I<object-method>.
 
=item EvMapping

Hash ref showing mapping of any I<Tcl::pTk::Ev> objects in the args to their position in the stored callback.

For example, if the callback is supplied as:

  [ $subref, 'arg1', Ev('x'), Ev('y'), 'arg4']; 
  
The EvMapping will be:

 {
    x => 2,
    y => 3
 }
 
=item noWidgetArg

Flag = 1 to NOT include the widget/event-source as the first arg passed to a binding

This is most always equal to 0, because bindings always include the source widget as the first arg.
However, some widgets that provide their own '%' substitution (like tktable a.k.a. TableMatrix) do not
pass the widget as the first arg.
 
=back

=head1 METHODS

=cut

##################################################

=head2 new

Constructor: Creates a new Tcl::pTk::Callback instance. 
        
Any args supplied with be fed to the callback when it is executed by the I<Call> method, before any args
that are supplied to I<Call>.

B<Usage:>


        # Create Callback - No Arg Subref form
	$cb = Tcl::pTk::Callback->new(\&lots);
        
        # Create Callback - Subref form, with args
	$cb = Tcl::pTk::Callback->new( [\&lots, $arg1, $arg2] );
        
        # Create Callback - Object->Method form, with args
	$cb = Tcl::pTk::Callback->new([ $obj, 'method', $arg1, $arg2]);
        
        Note: The noWidgetArg attribute may be supplied as the second arg in any of the 
          above forms.

=cut

sub new{
        my $class = shift;

        $class = ref($class) if( ref($class)); # handle $object->new syntax
        
        my $self = {};
        
        my $callback = shift;

	# Fall thru if the supplied callback is already a callback object
	if( Scalar::Util::blessed($callback) && $callback->isa('Tcl::pTk::Callback') ){
		return $callback;
	}
        
        # Get the optional noWidgetArg
        my $noWidgetArg = shift;
        $self->{noWidgetArg} = $noWidgetArg;
        
        
        if( ref($callback) eq 'CODE'){ # No Arg Sub Ref
                $self->{callback} = [$callback];
        }
        elsif( ref($callback) eq 'ARRAY'){ # Subref with args
                                
                $self->{callback} = $callback;
                
        }
        elsif( !ref($callback)){ # Must be just a method name
                $self->{callback} = [$callback];
        }
        else{
                confess("Error in ".__PACKAGE__."::new: callback received '$callback' expected code-ref or array ref\n");
        }
        
        #### Determine the form
        my @callback = @{$self->{callback}};
        
        my $first = $callback[0];
        
        my $argStart;  #Index where the args start
        if( ref($first) and ref($first) ne 'CODE'){ # must be an object,method call
                $self->{form} = 'object-method';
                $argStart = 2;
        }
        elsif( defined($first) && !ref($first) ){    # First are not a reference, must be a method name
                $self->{form} = 'methodName';
                $argStart = 1;
        }
        elsif( ref($first) eq 'CODE'){ # Subref call 
                $self->{form} = 'subref';
                $argStart = 1;
        }
        else{
                confess("Error in ".__PACKAGE__."::new: unrecognized callback\n");
        }
                
        
        # Examine args and determine if any are Tcl::pTk::Ev objects, which need event info substitution performed
        #   when they are executed as part of a bind operation.
        my %EvMapping;
        if ($#callback >= $argStart){ # args present
                foreach my $argIndex($argStart..$#callback){
                        my $arg = $callback[$argIndex];
                        if( ref($arg) and ref($arg) eq 'Tcl::pTk::Ev'){
                                my $subst = $arg->[0];
                                $EvMapping{$subst} = $argIndex;
                        }
                }
                $self->{EvMapping} = \%EvMapping;
        }
        bless $self, $class;
        
}

##################################################

=head2 Call

Calls/executes a callback, with optional extra args.
        
Any args supplied to I<Call> will be fed to the callback after any args that were supplied to I<new>.

B<Usage:>

        # Execute/call a callback, with optional extra args
        $cb->Call($extraArg1, $extraArg2);

=cut

sub Call{
        my $self = shift;
        
        my @args = @_;
        
        my @callback = @{$self->{callback}};
        
        my $form = $self->{form};
        
        my $first = shift @callback;
        
        if( $form eq 'object-method'){ # must be an object,method call
                my $method = shift @callback;
                $first->$method(@callback,@args);
        }
        elsif( $form eq 'methodName'){ # A method, object call
                my $obj = shift @callback;
                $obj->$first(@callback, @args);
        }
        else{ # Subref call 
                $first->(@callback,@args);
        }
}
    
####################################################################

=head2 BindCall

Special I<Call> method for a callback supplied to a I<bind> function. I<BindCall> expects to get
the event source (e.g. a button, window, frame, etc that the event occured in) as the first arg
of the method. The callback will then be executed with the event source as the first arg (if a subref
callback type), or as the object (if a object->method callback type). 

The following table shows some examples of how a callback is executed for several different forms
of callback supplied to a I<bind> method.

   Callback supplied to bind    Resultant Call
   -------------------------    --------------------------------
   [$subref, arg1, arg2]	$subref->($eventSource, arg1, arg2)
   ['methodname', arg1,arg2]	$eventSource->methodName($arg1, $arg2)
   'methodname'	                $eventSource->methodName()
    $subref                     $subref->($eventSource)
   [$widget, 'methodname',arg1]	$widget->methodName($arg1)


B<Usage:>

        # Execute/call a callback, with optional extra args
        $cb->BindCall($eventSource, $extraArg1, $extraArg2);
        


=cut

sub BindCall{
        my $self = shift;
        
        my $eventSource = shift;
        
        my $noWidgetArg = $self->{noWidgetArg};  # Flag = 1 if we aren't to add event source widget to the call
        
        my @args = @_;
        
        my @callback = @{$self->{callback}};
        
        my $first = shift @callback;
        my $form  = $self->{form};
        
        if( $form eq 'methodName' ){ # must be an method name, treat as a $eventSource->methodName call 
                $eventSource->$first(@callback,@args);
        }
        elsif( $form eq 'object-method'){ # must be an object,method call
                my $method = shift @callback;
                $first->$method(@callback,@args);
        }
        else{ # Subref call 
                my @totalArgs = (@callback, @args);
                unshift @totalArgs, $eventSource unless($noWidgetArg);
                $first->(@totalArgs);
        }
}
        
####################################################################

=head2 _updateEvArgs

Internal method to update the I<Ev> args of the callback (as defined in the I<EvMapping> attribute) with updated
values. This is typically used to populate the Ev args with the actual event information substitutions after a I<bind>
event occurs.
        

B<Usage:>

        $cb->_updateEvArgs(@evArgValues);

=cut

sub _updateEvArgs{
        my $self = shift;
        
        my @evArgValues = @_;
        
        my $callback  = $self->{callback};
        my $EvMapping = $self->{EvMapping};


        return unless defined($EvMapping); # No substitution needed if EvMapping not there

        my @argIndexes = sort {$a<=>$b} values %$EvMapping; # Indexes in the $callback to replace
        
        @$callback[@argIndexes] = @evArgValues;

}

####################################################################

=head2 createTclBindRef

Method to create a callback array-reference suitable for feeding to the Tcl::call method that will properly 
execute this L<Tcl::pTk::Callback> when the bind event occurs. Handles any Event pattern substitution thru
Tcl.pm's Tcl::Ev() mechanism.
        
B<Usage:>

        # Create bind ref from the callback object and the widget the 
        #  binding is created from.
        my $bindRef = $callback->createTclBindRef($creatingWidget);
        
        
        # Bind ref created now feed to Tcl::Call (thru the interp)
        $interp->all("bind",$tag, $sequence, $bindRef);
        
=cut 

sub createTclBindRef{
        my $self = shift;
        
        my $creatingWidget = shift;
        my $noWidgetArg    = $self->{noWidgetArg};
        
        my $EvMapping = $self->{EvMapping};
        
        my $TclEvArg;
        if( defined($EvMapping)){ # Ev Mapping/Substitution needed
                my %EvInverse = reverse(%$EvMapping); # Get Inverse mapping (indexes to values)
                my @indexes = sort {$a<=>$b} keys %EvInverse; # Sorted indexes
                
                # Create Substitution args for Tcl::Ev
                my @TclEv = map "%".$_, @EvInverse{@indexes};
                
                # Add the event source substitution (most allways there)
                unshift @TclEv, '%W' unless( $noWidgetArg);
                
                $TclEvArg = Tcl::Ev(@TclEv);
                
                my $bindRef = [
                        sub{
                                my $eventPath = shift unless($noWidgetArg);
                                
                                my $eventSource;
                                
                                unless( $noWidgetArg){
                                        # Map eventsource Path to an actual widget
                                        my $widgets = $creatingWidget->interp->widgets();
                                       $widgets = $widgets->{RPATH};
                                       $eventSource = $widgets->{$eventPath};
                                
                                       # If eventSource not found in the lookup, use the creating Widget
                                       $eventSource = defined($eventSource)? $eventSource : $creatingWidget;
                                }
                                
                                my @evArgs = @_;
                        
                                $self->_updateEvArgs(@evArgs);
                                $self->BindCall($eventSource);
                           },
                           $TclEvArg
                     ];
                return $bindRef;
        }
        else{  # No Ev Substitution needed
                my $bindRef = 
                        [sub{
                                my $eventPath = shift;
                                # Map eventsource Path to an actual widget
				if( !defined( $creatingWidget->interp ) ){
					Carp::confess "$creatingWidget has no interp!!";
				}
                                my $widgets = $creatingWidget->interp->widgets();
                                $widgets = $widgets->{RPATH};
                                my $eventSource = $widgets->{$eventPath};
                                
                                # If eventSource not found in the lookup, use the creating Widget
                                $eventSource = defined($eventSource)? $eventSource : $creatingWidget;

                                $self->BindCall($eventSource);
                           },
                           Tcl::Ev('%W')
                           ];
               return $bindRef;
        }
}

1;
