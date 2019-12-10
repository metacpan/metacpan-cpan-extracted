package OPTiMaDe::FilterParser::Comparison;

use strict;
use warnings;
use Scalar::Util qw(blessed);

sub new {
    my( $class, $operator ) = @_;
    return bless { operands => [], operator => $operator }, $class;
}

sub set_operator {
    my( $self, $operator ) = @_;
    $self->{operator} = $operator;
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
    $options = {} unless $options;
    my( $delim, $placeholder ) = (
        $options->{delim},
        $options->{placeholder},
    );
    $delim = "'" unless $delim;

    my $operator = $self->{operator};
    my @operands = @{$self->{operands}};

    # Handle STARTS/ENDS WITH. Currently, the 2nd operand is quaranteed
    # to be string.
    if(      $operator eq 'CONTAINS' ) {
        $operator = 'LIKE';
        $operands[1] = '%' . $operands[1] . '%';
    } elsif( $operator =~ /^STARTS( WITH)?$/ ) {
        $operator = 'LIKE';
        $operands[1] = $operands[1] . '%';
    } elsif( $operator =~ /^ENDS( WITH)?$/ ) {
        $operator = 'LIKE';
        $operands[1] = '%' . $operands[1];
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

    $self->{operands} = [ map { OPTiMaDe::FilterParser::modify( $_, $code, @_ ) }
                              @{$self->{operands}} ];
    return $code->( $self, @_ );
}

1;
