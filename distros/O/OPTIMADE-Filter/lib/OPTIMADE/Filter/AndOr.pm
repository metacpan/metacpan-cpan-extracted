package OPTIMADE::Filter::AndOr;

use strict;
use warnings;

use parent 'OPTIMADE::Filter::Modifiable';

use Scalar::Util qw(blessed);

sub new {
    my $class = shift;
    my $operator;
    my @operands;

    if(      @_ == 2 ) {
        @operands = @_;
    } elsif( @_ == 3 ) {
        ( $operands[0], $operator, $operands[1] ) = @_;
    }
    return bless { operands => \@operands,
                   operator => $operator }, $class;
}

sub operator {
    my( $self, $operator ) = @_;
    my $previous_operator = $self->{operator};
    $self->{operator} = $operator if defined $operator;
    return $previous_operator;
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
    my( $delim, $flatten, $placeholder ) = (
        $options->{delim},
        $options->{flatten},
        $options->{placeholder},
    );
    $delim = "'" unless $delim;

    my $operator = $self->{operator};
    my @operands;
    my @values;
    for my $i (0..$#{$self->{operands}}) {
        my $arg = $self->{operands}[$i];
        if( blessed $arg && $arg->can( 'to_SQL' ) ) {
            my $values = [];
            eval { ( $arg, $values ) = $arg->to_SQL( $options ) };
            if( $@ ) {
                chomp $@;
                $arg = "<$@>";
            }
            if( $self->{operands}[$i]->isa( OPTIMADE::Filter::AndOr:: ) &&
                (!$flatten || $self->operator ne $self->{operands}[$i]->operator) ) {
                $arg = "($arg)";
            }
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
        push @operands, $arg;
    }

    if( wantarray ) {
        return ( "$operands[0] $operator $operands[1]", \@values );
    } else {
        return "$operands[0] $operator $operands[1]";
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
        die 'number of operands for OPTIMADE::Filter::AndOr must be 2, ' .
            'got ' . @{$self->{operands}};
    }
    die 'operator undefined for OPTIMADE::Filter::AndOr' if !$self->operator;
}

1;
