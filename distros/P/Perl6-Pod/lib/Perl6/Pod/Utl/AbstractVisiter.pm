#===============================================================================
#
#  DESCRIPTION:  Abstract Class for Nodes Visiter
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zag@cpan.org>
#===============================================================================
package Perl6::Pod::Utl::AbstractVisiter;
use strict;
use warnings;
use vars qw($AUTOLOAD);
use Carp;
our $VERSION = '0.01';

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
    unless ( ref($n) && UNIVERSAL::isa( $n, 'Perl6::Pod::Lex::Block' )
        )
    {
        if ( ref($n) eq 'ARRAY' ) {
            $self->visit($_) for @$n;
        }
        else {
            die "Unknown node type $n (not isa Perl6::Pod::Lex::Block)";
        }
    }

    my $method = $self->__get_method_name($n);
    #make method name
    $self->$method($n);
}

=head2 __get_method_name $ref

make mathod name from object ref

=cut
sub __get_method_name {
    my $self = shift;
    my $el = shift || croak "wait object !";
    my $method = ref($el);
    $method =~ s/.*:://;
    return $method;
}

sub visit_childs {
    my $self = shift;
    foreach my $n (@_) {
        die "Unknow type $n (not isa Perl6::Pod::Block)"
          unless UNIVERSAL::isa( $n, 'Perl6::Pod::Block' ) || 
          UNIVERSAL::isa( $n, 'Perl6::Pod::Lex::Block' );
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

