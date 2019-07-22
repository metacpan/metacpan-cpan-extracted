package OPTiMaDe::FilterParser::Comparison;

use strict;
use warnings;
use Scalar::Util qw(blessed);

sub new {
    my( $class, $operator ) = @_;
    return bless { operands  => [], operator  => $operator }, $class;
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

sub to_SQL
{
    my( $self, $delim ) = @_;
    $delim = "'" unless $delim;

    my $operator = $self->{operator};
    my @operands;
    for my $i (0..$#{$self->{operands}}) {
        my $arg = $self->{operands}[$i];
        if( blessed $arg && $arg->can( 'to_SQL' ) ) {
            $arg = $arg->to_SQL( $delim );
        } else {
            $arg =~ s/"/""/g;
            $arg = "\"$arg\"";
        }
        push @operands, $arg;
    }

    # Currently the 2nd operator is quaranteed to be string
    if(      $operator eq 'CONTAINS' ) {
        $operator = 'LIKE';
        $operands[1] =~ s/^"/"%/;
        $operands[1] =~ s/"$/%"/;
    } elsif( $operator =~ /^STARTS( WITH)?$/ ) {
        $operator = 'LIKE';
        $operands[1] =~ s/"$/%"/;
    } elsif( $operator =~ /^ENDS( WITH)?$/ ) {
        $operator = 'LIKE';
        $operands[1] =~ s/^"/"%/;
    }

    return "($operands[0] $operator $operands[1])";
}

1;
