package OPTiMaDe::Filter::Negation;

use strict;
use warnings;

sub new {
    my( $class, $inner ) = @_;
    return bless { inner => $inner }, $class;
}

sub inner
{
    my( $self, $inner ) = @_;
    my $previous_inner = $self->{inner};
    $self->{inner} = $inner if defined $inner;
    return $previous_inner;
}

sub to_filter
{
    my( $self ) = @_;
    $self->validate;
    return '(NOT ' . $self->inner->to_filter . ')';
}

sub to_SQL
{
    my( $self, $options ) = @_;
    $self->validate;

    my( $sql, $values ) = $self->inner->to_SQL( $options );
    if( wantarray ) {
        return ( "(NOT $sql)", $values );
    } else {
        return "(NOT $sql)";
    }
}

sub modify
{
    my $self = shift;
    my $code = shift;

    $self->inner( OPTiMaDe::Filter::modify( $self->inner, $code, @_ ) );
    return $code->( $self, @_ );
}

sub validate
{
    my $self = shift;
    die 'inner undefined for OPTiMaDe::Filter::Negation' if !$self->inner;
}

1;
