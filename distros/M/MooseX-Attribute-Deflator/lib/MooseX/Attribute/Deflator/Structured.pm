#
# This file is part of MooseX-Attribute-Deflator
#
# This software is Copyright (c) 2012 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package MooseX::Attribute::Deflator::Structured;
{
  $MooseX::Attribute::Deflator::Structured::VERSION = '2.2.2';
}

# ABSTRACT: Deflators for MooseX::Types::Structured

use MooseX::Attribute::Deflator;

deflate 'MooseX::Types::Structured::Optional[]', via {
    my ( $attr, $constraint, $deflate ) = @_;
    return $deflate->( $_, $constraint->type_parameter );
}, inline_as {
    my ( $attr, $constraint, $deflators ) = @_;
    return $deflators->( $constraint->type_parameter );
};

inflate 'MooseX::Types::Structured::Optional[]', via {
    my ( $attr, $constraint, $inflate ) = @_;
    return $inflate->( $_, $constraint->type_parameter );
}, inline_as {
    my ( $attr, $constraint, $deflators ) = @_;
    return $deflators->( $constraint->type_parameter );
};

deflate 'MooseX::Types::Structured::Map[]', via {
    my ( $attr, $constraint, $deflate ) = @_;
    my $value       = {%$_};
    my $constraints = $constraint->type_constraints;
    while ( my ( $k, $v ) = each %$value ) {
        $value->{$k} = $deflate->( $value->{$k}, $constraints->[1] );
    }
    return $deflate->( $value, $constraint->parent );
}, inline_as {
    my ( $attr, $constraint, $deflators ) = @_;
    return (
        '$value = {%$value};',
        'while ( my ( $k, $v ) = each %$value ) {',
        '$value->{$k} = do {',
        '    my $value = $value->{$k};',
        '    $value = do {',
        $deflators->( $constraint->type_constraints->[1] ),
        '    };',
        '  };',
        '}',
        $deflators->( $constraint->parent ),
    );
};

inflate 'MooseX::Types::Structured::Map[]', via {
    my ( $attr, $constraint, $inflate ) = @_;
    my $value = $inflate->( $_, $constraint->parent );
    my $constraints = $constraint->type_constraints;
    while ( my ( $k, $v ) = each %$value ) {
        $value->{$k} = $inflate->( $value->{$k}, $constraints->[1] );
    }
    return $value;
}, inline_as {
    my ( $attr, $constraint, $deflators ) = @_;
    return (
        '$value = do {',
        $deflators->( $constraint->parent ),
        ' };',
        'while ( my ( $k, $v ) = each %$value ) {',
        '  $value->{$k} = do {',
        '    my $value = $value->{$k};',
        '    $value = do {',
        $deflators->( $constraint->type_constraints->[1] ),
        '    };',
        '  };',
        '}',
        '$value',
    );
};

deflate 'MooseX::Types::Structured::Dict[]', via {
    my ( $attr, $constraint, $deflate ) = @_;
    my %constraints = @{ $constraint->type_constraints };
    my $value       = {%$_};
    while ( my ( $k, $v ) = each %$value ) {
        $value->{$k} = $deflate->( $value->{$k}, $constraints{$k} );
    }
    return $deflate->( $value, $constraint->parent );
}, inline_as {
    my ( $attr, $constraint, $deflators ) = @_;
    my %constraints = @{ $constraint->type_constraints };
    my @map         = 'my $dict;';
    while ( my ( $k, $v ) = each %constraints ) {
        push( @map,
            '$dict->{"' . quotemeta($k) . '"} = sub { ',
            'my $value = shift;',
            $deflators->($v), ' };' );
    }
    return (
        @map,
        '$value = {%$value};',
        'while ( my ( $k, $v ) = each %$value ) {',
        '$value->{$k} = do {',
        '    my $value = $value->{$k};',
        '    $value = $dict->{$k}->($value);',
        '  };',
        '}',
        $deflators->( $constraint->parent ),
    );
};

inflate 'MooseX::Types::Structured::Dict[]', via {
    my ( $attr, $constraint, $inflate ) = @_;
    my %constraints = @{ $constraint->type_constraints };
    my $value = $inflate->( $_, $constraint->parent );
    while ( my ( $k, $v ) = each %$value ) {
        $value->{$k} = $inflate->( $value->{$k}, $constraints{$k} );
    }
    return $value;
}, inline_as {
    my ( $attr, $constraint, $deflators ) = @_;
    my %constraints = @{ $constraint->type_constraints };
    my @map         = 'my $dict;';
    while ( my ( $k, $v ) = each %constraints ) {
        push( @map,
            '$dict->{"' . quotemeta($k) . '"} = sub { ',
            'my $value = shift;',
            $deflators->($v), ' };' );
    }
    return (
        @map,
        '$value = do {',
        $deflators->( $constraint->parent ),
        ' };',
        'while ( my ( $k, $v ) = each %$value ) {',
        '$value->{$k} = do {',
        '    my $value = $value->{$k};',
        '    $value = $dict->{$k}->($value);',
        '  };',
        '}',
        '$value',
    );
};

deflate 'MooseX::Types::Structured::Tuple[]', via {
    my ( $attr, $constraint, $deflate ) = @_;
    my @constraints = @{ $constraint->type_constraints };
    my $value       = [@$_];
    for ( my $i = 0; $i < @$value; $i++ ) {
        $value->[$i] = $deflate->( $value->[$i],
            $constraints[$i] || $constraints[-1] );
    }
    return $deflate->( $value, $constraint->parent );
}, inline_as {
    my ( $attr, $constraint, $deflators ) = @_;
    my @constraints = @{ $constraint->type_constraints };
    my @map         = 'my $tuple = [];';
    foreach my $tc (@constraints) {
        push( @map,
            'push(@$tuple, sub {',
            'my $value = shift;',
            $deflators->($tc), ' });' );
    }
    return (
        @map,
        '$value = [@$value];',
        'for ( my $i = 0; $i < @$value; $i++ ) {',
        '$value->[$i] = do {',
        '    my $value = $value->[$i];',
        '    $value = ($tuple->[$i] || $tuple->[-1])->($value);',
        '  };',
        '}',
        $deflators->( $constraint->parent ),
    );
};

inflate 'MooseX::Types::Structured::Tuple[]', via {
    my ( $attr, $constraint, $inflate ) = @_;
    my @constraints = @{ $constraint->type_constraints };
    my $value = $inflate->( $_, $constraint->parent );
    for ( my $i = 0; $i < @$value; $i++ ) {
        $value->[$i] = $inflate->( $value->[$i],
            $constraints[$i] || $constraints[-1] );
    }
    return $value;
}, inline_as {
    my ( $attr, $constraint, $deflators ) = @_;
    my @constraints = @{ $constraint->type_constraints };
    my @map         = 'my $tuple = [];';
    foreach my $tc (@constraints) {
        push( @map,
            'push(@$tuple, sub {',
            'my $value = shift;',
            $deflators->($tc), ' });' );
    }
    return (
        @map,
        '$value = do {',
        $deflators->( $constraint->parent ),
        ' };',
        'for ( my $i = 0; $i < @$value; $i++ ) {',
        '$value->[$i] = do {',
        '    my $value = $value->[$i];',
        '    $value = ($tuple->[$i] || $tuple->[-1])->($value);',
        '  };',
        '}',
        '$value',
    );
};

1;



=pod

=head1 NAME

MooseX::Attribute::Deflator::Structured - Deflators for MooseX::Types::Structured

=head1 VERSION

version 2.2.2

=head1 SYNOPSIS

  use MooseX::Attribute::Deflator::Structured;

=head1 DESCRIPTION

This module registers sane type deflators and inflators for L<MooseX::Types::Structured>.

=head1 AUTHOR

Moritz Onken

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut


__END__

