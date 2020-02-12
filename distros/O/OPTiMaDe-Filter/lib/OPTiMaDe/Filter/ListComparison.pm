package OPTiMaDe::Filter::ListComparison;

use strict;
use warnings;
use Scalar::Util qw(blessed);

sub new {
    my( $class, $operator ) = @_;
    return bless { property => undef,
                   operator => $operator,
                   values => undef }, $class;
}

sub property {
    my( $self, $property ) = @_;
    my $previous_property = $self->{property};
    $self->{property} = $property if defined $property;
    return $previous_property;
}

sub operator {
    my( $self, $operator ) = @_;
    my $previous_operator = $self->{operator};
    $self->{operator} = $operator if defined $operator;
    return $previous_operator;
}

sub values {
    my( $self, $values ) = @_;
    my $previous_values = $self->{values};
    $self->{values} = $values if defined $values;
    return $previous_values;
}

sub to_filter {
    my( $self ) = @_;
    $self->validate;

    my @values;
    for my $i (0..$#{$self->{values}}) {
        my( $operator, $arg ) = @{$self->{values}[$i]};
        if( blessed $arg && $arg->can( 'to_filter' ) ) {
            $arg = $arg->to_filter;
        } else {
            $arg =~ s/\\/\\\\/g;
            $arg =~ s/"/\\"/g;
            $arg = "\"$arg\"";
        }
        push @values, "$operator $arg";
    }

    return '(' . join( ' ', $self->{property}->to_filter,
                            $self->{operator},
                            join( ', ', @values ) ) . ')';
}

sub to_SQL
{
    die "no SQL representation\n";
}

sub modify {
    my $self = shift;
    my $code = shift;

    $self->{property} = $code->( $self->{property}, @_ );
    $self->{values} = [ map { [ OPTiMaDe::Filter::modify( $_->[0], $code, @_ ),
                                OPTiMaDe::Filter::modify( $_->[1], $code, @_ ) ] }
                            @{$self->{values}} ];
    return $code->( $self, @_ );
}

sub validate
{
    my $self = shift;

    if( !$self->property ) {
        die 'property undefined for OPTiMaDe::Filter::ListComparison';
    }
    if( !$self->operator ) {
        die 'operator undefined for OPTiMaDe::Filter::ListComparison';
    }
    if( !$self->values ) {
        die 'values undefined for OPTiMaDe::Filter::ListComparison';
    }
}

1;
