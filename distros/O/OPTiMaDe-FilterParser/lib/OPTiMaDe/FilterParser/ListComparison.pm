package OPTiMaDe::FilterParser::ListComparison;

use strict;
use warnings;
use Scalar::Util qw(blessed);

sub new {
    my( $class, $operator ) = @_;
    return bless { property => undef,
                   operator => $operator,
                   values => undef }, $class;
}

sub set_property {
    my( $self, $property ) = @_;
    $self->{property} = $property;
}

sub set_operator {
    my( $self, $operator ) = @_;
    $self->{operator} = $operator;
}

sub set_values {
    my( $self, $values ) = @_;
    $self->{values} = $values;
}

sub to_filter {
    my( $self ) = @_;

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

    if( $self->{operator} eq 'LENGTH' ) {
        return '(' . join( ' ', $self->{operator},
                                $self->{property}->to_filter,
                                join( ', ', @values ) ) . ')';
    } else {
        return '(' . join( ' ', $self->{property}->to_filter,
                                $self->{operator},
                                join( ', ', @values ) ) . ')';
    }
}

sub to_SQL
{
    die "no SQL representation\n";
}

sub modify {
    my $self = shift;
    my $code = shift;

    $self->{property} = $code->( $self->{property}, @_ );
    $self->{values} = [ map { [ OPTiMaDe::FilterParser::modify( $_->[0], $code, @_ ),
                                OPTiMaDe::FilterParser::modify( $_->[1], $code, @_ ) ] }
                            @{$self->{values}} ];
    return $code->( $self, @_ );
}

1;
