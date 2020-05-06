package OPTIMADE::Filter::Comparison;

use strict;
use warnings;

use parent 'OPTIMADE::Filter::Modifiable';

use Scalar::Util qw(blessed);

sub new {
    my( $class, $operator ) = @_;
    return bless { operands => [], operator => $operator }, $class;
}

sub push_operand
{
    my( $self, $operand ) = @_;
    die 'attempt to insert more than two operands' if @{$self->{operands}} >= 2;
    push @{$self->{operands}}, $operand;
}

sub unshift_operand
{
    my( $self, $operand ) = @_;
    die 'attempt to insert more than two operands' if @{$self->{operands}} >= 2;
    unshift @{$self->{operands}}, $operand;
}

sub operator
{
    my( $self, $operator ) = @_;
    my $previous_operator = $self->{operator};
    $self->{operator} = $operator if defined $operator;
    return $previous_operator;
}

sub left
{
    my( $self, $operand ) = @_;
    my $previous_operand = $self->{operands}[0];
    $self->{operands}[0] = $operand if defined $operand;
    return $previous_operand;
}

sub right
{
    my( $self, $operand ) = @_;
    my $previous_operand = $self->{operands}[1];
    $self->{operands}[1] = $operand if defined $operand;
    return $previous_operand;
}

sub to_filter
{
    my( $self ) = @_;
    $self->validate;

    my $operator = $self->{operator};
    my @operands;
    for my $i (0..$#{$self->{operands}}) {
        my $arg = $self->{operands}[$i];
        if( blessed $arg && $arg->can( 'to_filter' ) ) {
            $arg = $arg->to_filter;
        } else {
            $arg =~ s/\\/\\\\/g;
            $arg =~ s/"/\\"/g;
            $arg = "\"$arg\"";
        }
        push @operands, $arg;
    }

    return "($operands[0] $operator $operands[1])";
}

sub to_SQL
{
    my( $self, $options ) = @_;
    $self->validate;

    $options = {} unless $options;
    my( $delim, $placeholder ) = (
        $options->{delim},
        $options->{placeholder},
    );
    $delim = "'" unless $delim;

    my $operator = $self->{operator};
    my @operands = @{$self->{operands}};

    # Handle STARTS/ENDS WITH
    if(      $operator eq 'CONTAINS' ) {
        $operator = 'LIKE';
        $operands[1] = '%' . $operands[1] . '%' if !blessed $operands[1];
    } elsif( $operator =~ /^STARTS( WITH)?$/ ) {
        $operator = 'LIKE';
        $operands[1] = $operands[1] . '%' if !blessed $operands[1];
    } elsif( $operator =~ /^ENDS( WITH)?$/ ) {
        $operator = 'LIKE';
        $operands[1] = '%' . $operands[1] if !blessed $operands[1];
    }

    my @values;
    my @operands_now;
    for my $arg (@operands) {
        if( blessed $arg && $arg->can( 'to_SQL' ) ) {
            ( $arg, my $values ) = $arg->to_SQL( $options );
            push @values, @$values;
        } else {
            push @values, $arg;
            if( $placeholder ) {
                $arg = $placeholder;
            } else {
                $arg =~ s/"/""/g;
                $arg = "\"$arg\"";
            }
        }
        push @operands_now, $arg;
    }
    @operands = @operands_now;

    if( wantarray ) {
        return ( "($operands[0] $operator $operands[1])", \@values );
    } else {
        return "($operands[0] $operator $operands[1])";
    }
}

sub modify
{
    my $self = shift;
    my $code = shift;

    $self->{operands} = [ map { OPTIMADE::Filter::Modifiable::modify( $_, $code, @_ ) }
                              @{$self->{operands}} ];
    return $code->( $self, @_ );
}

sub validate
{
    my $self = shift;

    if( @{$self->{operands}} != 2 ) {
        die 'number of operands for OPTIMADE::Filter::Comparison must be 2, ' .
            'got ' . @{$self->{operands}};
    }
    die 'operator undefined for OPTIMADE::Filter::Comparison'
        if !$self->operator;
}

1;
