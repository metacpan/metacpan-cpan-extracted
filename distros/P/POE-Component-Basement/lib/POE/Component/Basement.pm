=head1 NAME 

POE::Component::Basement

=cut
package POE::Component::Basement;
use strict;

use Scalar::Util qw/ refaddr /;
use UNIVERSAL::require;
use Sub::Installer;
use Carp;
use NEXT;
use POE;

use vars qw/ %STATES @CARP_NOT @EXPORT_SUBS $VERSION /;
use base qw/ POE::Component::Basement::Std Class::Data::Inheritable /;
BEGIN { @CARP_NOT = qw/ attributes / }

__PACKAGE__->mk_classdata( $_ ) for qw/ session_class /;
__PACKAGE__->session_class( 'POE::Session' );
$VERSION = .01;

=head1 SYNOPSIS

  package POE::MyComponent;

  #  use as base
  use base qw/ POE::Component::Basement /;
  
  #  where the initializations happen (see Class::Std)
  sub BUILD { ... }
  
  #  see also Class::Std and Class::Data::Inheritable also 
  #  for accessor creation etc.
  
  #  define states
  sub state_one   : State( :inline<_start> ) { ... }
  sub state_two   : State( :object<foo> ) { ... }
  sub state_three : State( :package<bar> ) { ... }
  
  #  combined
  sub state_multi : State( :inline<foobar> :package<snafoo> ) { ... }
  ...

  #  chained events
  sub first : State( :object<foo> :chained<bar> ) { ... }
  sub second : State( :object<bar> ) { ... }
  ...

  #  calling in a row
  sub first : State( :object<foo> :next<bar> ) { ... }
  sub second : State( :object<bar> ) { ... }
  ...
  
  #  usage
  my $comp = POE::MyComponent->new ({
  
      #  single alias or array reference for multiple
      aliases => [qw/ mycomp shub_niggurath /],

      ...  #  your specific init_arg's.
  });

=head1 DESCRIPTION

Provides L<Class::Std> and base L<POE> component functionality. This module is
still kinda experimental.

=head1 CLASS AND INSTANCE DATA

=head2 Setting C<session_class>

Determines on which class the session should be built on.  To use, for instance, 
L<POE::Session::MessageBased>, set the option like this:

  MyComponent->session_class( 'POE::Session::MessageBased' );

The default is L<POE::Session>.

=cut

my %aliases_of : ATTR( :init_arg<aliases> :default<[]> );

=head2 Option C<aliases>

Can be a single value to be set as alias, or an array reference. If the latter,
L<POE::Kernel>'s C<alias_set> is called for each of it's elements. This must
be supplied as argument to the C<new> method. See L<SYNOPSIS> for examples.

=head1 ATTRIBUTES

This module just uses the attribute C<State> and delegates all other attribute 
handling to L<Class::Std>. Parameters can multiple, separated by spaces. They
look like those of L<Class::Std> to be coherent. As an example:

  sub start_event : State( :inline<_start> ) {
      ...
  }

This would create an C<inline_state> for our session, named C<_start>.

=head2 inline, package and object

Create C<inline_states>, C<package_states> or C<object_states> in your session.
Multiple specifications of these parameters cause multiple events to be defined.
Have a look at L<POE> for more information.

=head2 chained

  sub first : State( :inline<_start> :chained<end> ) { 
      print "Called first.\n";
      return 23;
  }
  
  sub end : State( :inline<end> ) {
      my $last_return = $_[ARG0];
      print "Called second. First returned $last_return\n";
  }

Specifies with which event the current state should be chained. If you use
C<chained>, the given event will be triggered after the sub has completed. It's
return values will be passed to the chained event.

=head2 next

  #  the event gets triggered
  POE::Kernel->yield( foo => 333 );

  sub first : State( :inline<foo> :next<bar> ) {
      my ( $nr ) = $_[ARG0];
      ...
  }
  
  sub second : State( :inline<bar> ) {
      my ( $nr ) = $_[ARG0];
      ...
  }
  
An event that was specified with C<next> is triggered right after completion 
of the current subroutine. The C<next> event gets the same parameters as the 
current.

=head2 error

  sub first : State( :inline<foo> :error<error_occured> ) {
      die "in the name of Cthulhu";
  }

  sub second : State( :inline<error_occured> ) {
      my $error = $_[ARG0];
      print 'An Error has occured: ' . $error;
  }

If an C<error> handling state is defined, C<PCB> will build an C<eval> block
around the subroutine call and emit the event specified with C<error>. First
argument is the error message.

=head1 INHERITANCE

Currently, you can overload the called methods in package and object states.
Though you have to do this without specifying a new C<State()> attribute. The
new method has the same attributes as the overriden. The latter can also be
called with L<NEXT>. This basic way works like:

  #  the original
  package Original;
  sub whatever : State( :package<_start> ) { ... }
  ...
  
  #  the new one
  package NewOne;
  use base qw/ Original /;
  sub whatever { ... }

But for information, I'm planning the possibility to override specific events.

=head1 METHODS

Methods starting with an underline (C<_>) is thought as internal to 
POE::Component::Basement and should therefore not be called directly.

=cut

sub _parse_attribute {
    my ( $attr ) = @_;
    if ( $attr =~ /^(\w+)(?:\((.*)\))?$/ ) { return ( $1, $2 ) }
    return;
}

=head2 _parse_attributes

  ( $name, $param ) = _parse_attribute( $attribute )
  
Takes an attribute and tries to split it into name and parameters. Returns
undef if nothing usable found.

=cut

sub new {
    my $class = shift;
    
    #  delegate original call
    my $self = $class->NEXT::new( @_ );
    
    #  collect all states of this class
    my $states = $self->get_states;
    
    #  session class
    my $sc = $class->session_class;
    
    #  load and create session
    UNIVERSAL::require( $sc );
    $sc->create ( %$states );
    
    #  register aliases
    my $aliases = $aliases_of{ ident $self };
    POE::Kernel->alias_set( $_ )
      for ( ref $aliases eq 'ARRAY' ? @$aliases : ($aliases) );
    
    #  they shall receive us
    return $self;
}

=head2 new

Constructor. See L<SYNOPSIS> for usage. This overrides the C<new> method 
provided by L<Class::Std>.

=cut

#  no warnings about redefinement
{ no warnings 'redefine';
    
    #  called per sub
    sub MODIFY_CODE_ATTRIBUTES {
        my ( $class, $code, @attrs ) = @_;
        my @unknown;

        #  walk attributes of sub
        for my $attr (@attrs) {
    
            #  parse the attribute into pieces
            if ( my ( $name, $param ) = _parse_attribute( $attr ) ) {
    
                #  recognized as 'State' attribute
                if ( lc $name eq 'state' ) {
    
                    #  split up states
                    my ( $states, $params ) = _parse_parameters( $param );
                    
                    #  die without states
                    croak 'No states detected' unless %{ $states || {} };
                    
                    #  register states of component
                    register_states( $class, $code, $states, $params );
                    
                    #  finished attribute, next
                    next;
                }
            }
            
            #  unable to parse or unknown, ignore
            push @unknown, $attr;
        }
        
        #  return what we haven't processed
        return $class->NEXT::MODIFY_CODE_ATTRIBUTES( $code, @unknown );
    }
}

=head2 MODIFY_CODE_ATTRIBUTES

This is an internal sub that's responsible for building your state-map, as it
is called on specification of an attribute. See perldoc's L<attributes> for
more information about this subject. This is an I<internal function>, do not
call directly.

=cut

my %code_replacement;

sub _create_modified_state : RESTRICTED {
    my ( $class, $code, $params ) = @_;
    my $orig_code = $code;
    my $tag;

    #  we have a chained event. next hop gets return values as ARG0
    if ( my $next = $params->{chained} ) {
        my $last_code = $code;
        $code = sub {
            my @rets = $last_code->( @_ );
            POE::Kernel->yield( $next, @rets );
        };
    }
    elsif ( my $next = $params->{next} ) {
        my $last_code = $code;
        $code = sub {
            $last_code->( @_ );
            POE::Kernel->yield( $next, @_[POE::Session::ARG0 .. $#_] );
        };
    }
    
    #  check for error handling
    if ( my $err_handler = $params->{error} ) {
        my $last_code = $code;
        $code = sub {
            eval { $last_code->( @_ ) };
            POE::Kernel->yield( $err_handler, $@ ) if $@;
        }
    }

    #  install new sub if modified
    if ( refaddr $code ne refaddr $orig_code ) {
        $code_replacement{ refaddr $orig_code } = $code;
    }
    
    return $orig_code;
}

=head2 _create_modified_state

  $code = _create_modified_state( \&coderef, \%params );

Does the wrapping for the more enhanced attributes. Internal, do not call.

=cut

sub register_states : RESTRICTED {
    my ( $class, $code, $states, $params ) = @_;

    #  have a look at every state
    while ( my ( $state, $type ) = each %$states ) {

        # see if we need to do something on the code
        $code = _create_modified_state( $class, $code, $params );
        
        #  remember
        $STATES{ $class }{ $type }{ $state } = $code;
    }
    
    return;
}

=head2 register_states

  void register_states( $class, $coderef, { state_name => 'type' } );

Registers states corresponding to a specific code reference. Accepted state
names are C<inline>, C<package> and C<object>. Internal, do not call.

=cut

sub _flatten_inheritance : RESTRICTED {
    my ( $class ) = @_;

    #  bad refs
    no strict 'refs';

    #  include father class
    my ( %classmap, @isa_queue );
    $classmap{ $class } = 1;

    #  we start with the specified class and walk the queue
    push @isa_queue, @{ $class . '::ISA' };
    while ( my $c = shift @isa_queue ) {

        #  only act on unseen classes
        unless ( exists $classmap{ $c } ) {

            #  remember class and add it's @ISA to the queue
            $classmap{ $c } = 1;
            push @isa_queue, @{ $c . '::ISA' };
        }
    }

    #  tell our caller what we've found
    return keys %classmap;
}

=head2 _flatten_inheritance

  @classes_in_family = _flatten_inheritance( $rootclass )

Returns an array with names of classes used in the specified C<$rootclass>'
inheritance tree. This is internal, do not call.

=cut

sub get_states : RESTRICTED {
    my ( $self ) = @_;
    my ( %struct, %seen_states );
    my $own_class = ref( $self ) || $self;

    #  we iterate through our inheritance and collect our states
    for my $class ( _flatten_inheritance( ref( $self ) || $self ) ) {
        next unless exists $STATES{ $class };

        #  walk through our types and set up their states
        while ( my ( $type, $states ) = each %{ $STATES{ $class } } ) {
            
            #  get each state name and code reference
            while ( my ( $state, $code ) = each %{ $states || {} } ) {
                
                #  we only allow unique states
                if ( exists $seen_states{ $state } ) {
                    die "State $state defined twice "
                      . "($seen_states{$state} and $class)\n";
                }
                else { $seen_states{ $state } = $class }

                #  get the name of the sub
                my $name = _get_symbol_name( $class, $code )
                  or die "No name in symbol table for $state in $class\n";

                #  code might have to be replaced
                if ( my $newcode = $code_replacement{ refaddr $code } ) {
                    Sub::Installer::reinstall_sub
                      ( $class => { $name => $newcode } );
                    $code = $newcode;
                }
    
                #  package states just need a name
                if ( lc $type eq 'package' ) {
                    
                    #  the session wants an array reference
                    $struct{ $type . '_states' } ||= [ $own_class, {} ];
                    
                    #  add new state to package
                    $struct{ $type . '_states' }[1]{ $state } = $name;
                }
                
                #  inline states get the code reference
                elsif ( lc $type eq 'inline' ) {
                    $struct{ $type . '_states' }{ $state } = $code;
                }
                
                #  object is like package, just with ourself
                elsif ( lc $type eq 'object' ) {
                    
                    #  object states are surrounded by array ref
                    $struct{ $type . '_states' } ||= [ $self, {} ];
                    
                    #  object states obviously need an object
                    die 'Didn\'t get an object as first argument'
                      unless ref $self and UNIVERSAL::isa( $self, 'UNIVERSAL' );
                    
                    #  save states under object
                    $struct{ $type . '_states' }[1]{ $state } = $name;
                }   
            }
        }
    }
    
    #  return ready structure
    return \%struct;
}

=head2 get_states

  \%struct = $comp->get_states()

Returns a structure containing the defined inline, package and object states
ready to use for L<POE::Session>s constructor. Internal and restricted, do not
call.

=cut

#  we cache the sub names
my %symcache;

sub _get_symbol_name : RESTRICTED {
    my ( $class, $code ) = @_;

    #  we need symrefs, and reset symbol table hash
    no strict 'refs';
    keys %{ $class . '::' };
    
    #  return cached version, if existing
    return $symcache{ refaddr( $code ) } 
      if $symcache{ refaddr( $code ) };
    
    #  walk symbol table
    while ( my ( $name, $smth ) = each %{ $class . '::' } ) {
    
        #  cache name and return
        return $symcache{ refaddr( $code ) } = $name 
          if refaddr( *{ $smth }{CODE} ) eq refaddr( $code );
    }
    
    #  no name was found
    return undef;
}

=head2 _get_symbol_name

  $subname = _get_symbol_name( $class, $coderef );

Searches for a code reference in the symbol table of a class and returns the
sub's name if found. Otherwise undef. Do not call.

=cut

sub _parse_parameters {
    my ( $string ) = @_;
    my %struct;
    
    #  extract everything that looks like a parameter
    while ( $string =~ s/: ([a-z0-9_.;]+?) <(.*?)> //xi ) {
        my ( $name, $value ) = ( $1, $2 );
    
        #  empty ones have to be ignored
        next unless $name;
        
        #  states
        if ( grep { $name eq $_ } qw/ inline package object / ) {
            $struct{states}{ $value } = $name;
        }
        
        #  enhanced
        elsif ( grep { $name eq $_ } qw/ error chained next / ) {
            $struct{params}{ $name } = $value;
        }
        
        #  huh?!
        else { 
            croak "Unknown parameter: '$name'"; 
        }
    }
    
    #  there was some part in that attr line we didn't understand
    if ( $string =~ /\S/ ) {
        
        #  we're dying anyways, so let's make it pretty
        $string =~ s/^\s+//; $string =~ s/\s+$//;
        croak "Unable to understand: '$string'";
    }
    
    return @struct{qw/ states params /};
}

=head2 _parse_parameters

  %parameters = _parse_parameters( $parameter_string )

This function looks for parameters formed like :name<value> and returns them in
( name => value, .. ) like pairs. Dies on malformed or unknown parameters.
Internal method, do not call.

=cut

=head1 SEE ALSO

L<POE>, L<Class::Std>, L<Class::Data::Inheritable>

=head1 REQUIRES

L<POE>, L<Class::Std>, L<Carp>, L<Scalar::Util>, L<NEXT>, L<Sub::Installer>, 
L<Class::Data::Inheritable>

=head1 AUTHOR

Robert Sedlacek <phaylon@dunkelheit.at>

=head1 LICENSE

You can copy and/or modify this module under the same terms as perl itself.

=cut

1;
