#line 1
package Sub::Uplevel;

use 5.006;
use strict;
our $VERSION = '0.2002';
$VERSION = eval $VERSION;

sub import {
  no strict 'refs';
  my ($class, @args) = @_;
  for my $fcn ( @args ) {
    if ( $fcn ne 'uplevel' ) {
      die qq{"$fcn" is not exported by the $class module\n}
    }
  }
  my $caller = caller(0);
  *{"$caller\::uplevel"} = \&uplevel;
  return;
}

# We must override *CORE::GLOBAL::caller if it hasn't already been 
# overridden or else Perl won't see our local override later.

if ( not defined *CORE::GLOBAL::caller{CODE} ) {
    *CORE::GLOBAL::caller = \&_normal_caller;
}


#line 96

# @Up_Frames -- uplevel stack
# $Caller_Proxy -- whatever caller() override was in effect before uplevel
our (@Up_Frames, $Caller_Proxy);

sub _apparent_stack_height {
    my $height = 1; # start above this function 
    while ( 1 ) {
        last if ! defined scalar $Caller_Proxy->($height);
        $height++;
    }
    return $height - 1; # subtract 1 for this function
}

sub uplevel {
    my($num_frames, $func, @args) = @_;
    
    # backwards compatible version of "no warnings 'redefine'"
    my $old_W = $^W;
    $^W = 0;

    # Update the caller proxy if the uplevel override isn't in effect
    local $Caller_Proxy = *CORE::GLOBAL::caller{CODE}
        if *CORE::GLOBAL::caller{CODE} != \&_uplevel_caller;
    local *CORE::GLOBAL::caller = \&_uplevel_caller;
    
    # restore old warnings state
    $^W = $old_W;

    if ( $num_frames >= _apparent_stack_height() ) {
      require Carp;
      Carp::carp("uplevel $num_frames is more than the caller stack");
    }

    local @Up_Frames = ($num_frames, @Up_Frames );
    
    return $func->(@args);
}

sub _normal_caller (;$) { ## no critic Prototypes
    my $height = $_[0];
    $height++;
    if ( CORE::caller() eq 'DB' ) {
        # passthrough the @DB::args trick
        package DB;
        if( wantarray and !@_ ) {
            return (CORE::caller($height))[0..2];
        }
        else {
            return CORE::caller($height);
        }
    }
    else {
        if( wantarray and !@_ ) {
            return (CORE::caller($height))[0..2];
        }
        else {
            return CORE::caller($height);
        }
    }
}

sub _uplevel_caller (;$) { ## no critic Prototypes
    my $height = $_[0] || 0;

    # shortcut if no uplevels have been called
    # always add +1 to CORE::caller (proxy caller function)
    # to skip this function's caller
    return $Caller_Proxy->( $height + 1 ) if ! @Up_Frames;

#line 215

    my $saw_uplevel = 0;
    my $adjust = 0;

    # walk up the call stack to fight the right package level to return;
    # look one higher than requested for each call to uplevel found
    # and adjust by the amount found in the Up_Frames stack for that call.
    # We *must* use CORE::caller here since we need the real stack not what 
    # some other override says the stack looks like, just in case that other
    # override breaks things in some horrible way

    for ( my $up = 0; $up <= $height + $adjust; $up++ ) {
        my @caller = CORE::caller($up + 1); 
        if( defined $caller[0] && $caller[0] eq __PACKAGE__ ) {
            # add one for each uplevel call seen
            # and look into the uplevel stack for the offset
            $adjust += 1 + $Up_Frames[$saw_uplevel];
            $saw_uplevel++;
        }
    }

    # For returning values, we pass through the call to the proxy caller
    # function, just at a higher stack level
    my @caller;
    if ( CORE::caller() eq 'DB' ) {
        # passthrough the @DB::args trick
        package DB;
        @caller = $Sub::Uplevel::Caller_Proxy->($height + $adjust + 1);
    }
    else {
        @caller = $Caller_Proxy->($height + $adjust + 1);
    }

    if( wantarray ) {
        if( !@_ ) {
            @caller = @caller[0..2];
        }
        return @caller;
    }
    else {
        return $caller[0];
    }
}

#line 327

1;
