#===============================================================================
#
#  DESCRIPTION:  Abstract Class for Nodes Visiter
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================
package Plosurin::AbstractVisiter;
use strict;
use warnings;
use vars qw($AUTOLOAD);

sub new {
    my $class = shift;
    my $self = bless( $#_ == 0 ? shift : {@_}, ref($class) || $class );
    $self;
}

sub visit {
    my $self = shift;
    my $n    = shift;

    #get type of file
    my $ref = ref($n);
    unless ( ref($n) && UNIVERSAL::isa( $n, 'Soy::base' )
        || UNIVERSAL::isa( $n, 'Plo::File' )
        || UNIVERSAL::isa( $n, 'Plo::template' ) )
    {
        if ( ref($n) eq 'ARRAY' ) {
            $self->visit($_) for @$n;
        }
        else {
            die "Unknown node type $n (not isa Soy::base)";
        }
    }

    my $method = ref($n);
    $method =~ s/.*:://;

    #make method name
    $self->$method($n);
}

sub visit_childs {
    my $self = shift;
    foreach my $n (@_) {
        die "Unknow type $n (not isa Soy::base)"
          unless UNIVERSAL::isa( $n, 'Soy::base' );
        foreach my $ch ( @{ $n->childs } ) {
            $self->visit($ch);
        }
    }
}

sub __default_method {
    my $self =shift;
    my $n = shift;
    my $method = ref($n);
    $method =~ s/.*:://;
    die ref($self) . ": Method '$method' for class " . ref($n) . " not implemented at ";
}

sub AUTOLOAD {
    my $self   = shift;
    my $method = $AUTOLOAD;
    $method =~ s/.*:://;
    return if $method eq 'DESTROY';

    #check if can
    if ( $self->can($method) ) {
        my $superior = "SUPER::$method";
        $self->$superior(@_);
    }
    else {
        $self->__default_method(@_);
    }
}

1;

