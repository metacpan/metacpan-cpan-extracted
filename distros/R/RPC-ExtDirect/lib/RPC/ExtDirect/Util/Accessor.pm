package RPC::ExtDirect::Util::Accessor;

use strict;
use warnings;
no  warnings 'uninitialized';       ## no critic

use Carp;

### NON-EXPORTED PUBLIC PACKAGE SUBROUTINE ###
#
# Generate either simple accessors, or complex ones, or both
#

sub mk_accessors {
    # Support class method calling convention for convenience
    shift if $_[0] eq __PACKAGE__;
    
    my (%arg) = @_;
    
    $arg{class} ||= caller();
    
    my $simplexes = $arg{simple};
    
    $simplexes = [ $simplexes ] unless 'ARRAY' eq ref $simplexes;
    
    for my $accessor ( @$simplexes ) {
        next unless defined $accessor;

        _create_accessor(
            type     => 'simple',
            accessor => $accessor,
            %arg,
        );
    }
    
    my $complexes = $arg{complex};
    
    for my $prop ( @$complexes ) {
        my $setters  = $prop->{setter} || $prop->{accessor};
        
        $setters = [ $setters ] unless 'ARRAY' eq ref $setters;
        
        for my $specific ( @$setters ) {
            _create_accessor(
                type     => 'complex',
                accessor => $specific,
                fallback => $prop->{fallback},
                %arg,
            );
        }
    }
}

# This is a convenience shortcut, too, as I always forget if
# the sub name is singular or plural...
*mk_accessor = *mk_accessors;

############## PRIVATE METHODS BELOW ##############

### PRIVATE PACKAGE SUBROUTINE ###
#
# Create an accessor
#

sub _create_accessor {
    my (%arg) = @_;
    
    my $class     = $arg{class};
    my $overwrite = $arg{overwrite};
    my $ignore    = $arg{ignore};
    my $type      = $arg{type};
    my $accessor  = $arg{accessor};
    my $fallback  = $arg{fallback};

    return unless defined $accessor;

    if ( $class->can($accessor) ) {
        croak "Accessor $accessor already exists in class $class"
            if !$overwrite && !$ignore;
    
        return if $ignore && !$overwrite;
    }
    
    my $accessor_fn  = $type eq 'complex' ? _complex($accessor, $fallback)
                     :                      _simplex($accessor)
                     ;
    my $predicate_fn = _predicate($accessor);
    
    eval "package $class; no warnings 'redefine'; " .
         "$accessor_fn; $predicate_fn; 1";
}

### PRIVATE PACKAGE SUBROUTINE ###
#
# Return the text for a predicate method
#

sub _predicate {
    my ($prop) = @_;
    
    return "
        sub has_$prop {
            my \$self = shift;
            
            return exists \$self->{$prop};
        }
    ";
}

### PRIVATE PACKAGE SUBROUTINE ###
#
# Return the text for a simple accessor method that acts as both getter
# when there are no arguments passed to it, and as a setter when there is
# at least one argument.
# When used as a setter, only the first argument will be assigned
# to the object property, the rest will be ignored.
#

sub _simplex {
    my ($prop) = @_;
    
    return "
        sub $prop { 
            my \$self = shift;
            
            if ( \@_ ) {
                \$self->{$prop} = shift;
                return \$self;
            }
            else {
                return \$self->{$prop};
            }
        }
    ";
}

### PRIVATE PACKAGE SUBROUTINE ###
#
# Return an accessor that will query the 'specific' object property
# first and return it if it's defined, falling back to the 'fallback'
# property getter otherwise when called with no arguments.
# Setter will set the 'specific' property for the object when called
# with one argument.
#

sub _complex {
    my ($specific, $fallback) = @_;
    
    return "
        sub $specific {
            my \$self = shift;
            
            if ( \@_ ) {
                \$self->{$specific} = shift;
                return \$self;
            }
            else {
                return exists \$self->{$specific}
                            ? \$self->{$specific}
                            : \$self->$fallback()
                            ;
            }
        }
    ";
}

1;
