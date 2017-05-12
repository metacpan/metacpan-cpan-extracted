#
# This file is part of MooseX-Attribute-Deflator
#
# This software is Copyright (c) 2012 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package MooseX::Attribute::Deflator::Moose;
{
  $MooseX::Attribute::Deflator::Moose::VERSION = '2.2.2';
}

# ABSTRACT: Deflators for Moose type constraints

use MooseX::Attribute::Deflator;
use JSON;

if($ENV{HARNESS_ACTIVE}) {
    deflate [qw(ArrayRef HashRef)], via { JSON->new->utf8->canonical->encode($_) },
        inline_as {'JSON->new->utf8->canonical->encode($value)'};
    inflate [qw(ArrayRef HashRef)], via { JSON->new->utf8->canonical->decode($_) },
        inline_as {'JSON->new->utf8->canonical->decode($value)'};
} else {
    deflate [qw(ArrayRef HashRef)], via { JSON::encode_json($_) },
        inline_as {'JSON::encode_json($value)'};
    inflate [qw(ArrayRef HashRef)], via { JSON::decode_json($_) },
        inline_as {'JSON::decode_json($value)'};
}


deflate 'ScalarRef', via {$$_}, inline_as {'$$value'};
inflate 'ScalarRef', via { \$_ }, inline_as {'\$value'};

deflate 'Bool', via { $_ ? JSON::true : JSON::false },
    inline_as {'$value ? JSON::true : JSON::false'};
inflate 'Bool', via { $_ ? 1 : 0 }, inline_as {'$value ? 1 : 0'};

deflate 'Item', via {$_}, inline_as {'$value'};
inflate 'Item', via {$_}, inline_as {'$value'};

deflate 'HashRef[]', via {
    my ( $attr, $constraint, $deflate ) = @_;
    my $value = {%$_};
    while ( my ( $k, $v ) = each %$value ) {
        $value->{$k}
            = $deflate->( $value->{$k}, $constraint->type_parameter );
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
        $deflators->( $constraint->type_parameter ),
        '    };',
        '  };',
        '}',
        $deflators->( $constraint->parent ),
    );
};

inflate 'HashRef[]', via {
    my ( $attr, $constraint, $inflate ) = @_;
    my $value = $inflate->( $_, $constraint->parent );
    while ( my ( $k, $v ) = each %$value ) {
        $value->{$k}
            = $inflate->( $value->{$k}, $constraint->type_parameter );
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
        $deflators->( $constraint->type_parameter ),
        '    };',
        '  };',
        '}',
        '$value',
    );
};

deflate 'ArrayRef[]', via {
    my ( $attr, $constraint, $deflate ) = @_;
    my $value = [@$_];
    $_ = $deflate->( $_, $constraint->type_parameter ) for (@$value);
    return $deflate->( $value, $constraint->parent );
}, inline_as {
    my ( $attr, $constraint, $deflators ) = @_;
    return (
        '$value = [@$value];',
        'for( @$value ) {',
        '  $_ = do {',
        '    my $value = $_;',
        '    $value = do {',
        $deflators->( $constraint->type_parameter ),
        '    };',
        '  };',
        '}',
        $deflators->( $constraint->parent ),
    );
};

inflate 'ArrayRef[]', via {
    my ( $attr, $constraint, $inflate ) = @_;
    my $value = $inflate->( $_, $constraint->parent );
    $_ = $inflate->( $_, $constraint->type_parameter ) for (@$value);
    return $value;
}, inline_as {
    my ( $attr, $constraint, $deflators ) = @_;
    return (
        '$value = do {',
        $deflators->( $constraint->parent ),
        ' };',
        'for( @$value ) {',
        '  $_ = do {',
        '    my $value = $_;',
        '    $value = do {',
        $deflators->( $constraint->type_parameter ),
        '    };',
        '  };',
        '}',
        '$value',
    );
};

deflate 'Maybe[]', via {
    my ( $attr, $constraint, $deflate ) = @_;
    return $deflate->( $_, $constraint->type_parameter );
}, inline_as {
    my ( $attr, $constraint, $deflators ) = @_;
    return $deflators->( $constraint->type_parameter );
};

inflate 'Maybe[]', via {
    my ( $attr, $constraint, $inflate ) = @_;
    return $inflate->( $_, $constraint->type_parameter );
}, inline_as {
    my ( $attr, $constraint, $deflators ) = @_;
    return $deflators->( $constraint->type_parameter );
};

deflate 'ScalarRef[]', via {
    my ( $attr, $constraint, $deflate ) = @_;
    return ${ $deflate->( $_, $constraint->type_parameter ) };
}, inline_as {
    my ( $attr, $constraint, $deflators ) = @_;
    my $parameter = $deflators->( $constraint->type_parameter );
    return ( '$value = do {', $parameter, '};', '$$value' );
};

inflate 'ScalarRef[]', via {
    my ( $attr, $constraint, $inflate ) = @_;
    return \$inflate->( $_, $constraint->type_parameter );
}, inline_as {
    my ( $attr, $constraint, $deflators ) = @_;
    my $parameter = $deflators->( $constraint->type_parameter );
    return ( '$value = do {', $parameter, '};', '\$value' );
};

1;



=pod

=head1 NAME

MooseX::Attribute::Deflator::Moose - Deflators for Moose type constraints

=head1 VERSION

version 2.2.2

=head1 SYNOPSIS

  use MooseX::Attribute::Deflator::Moose;

=head1 DESCRIPTION

Using this module registers sane type deflators and inflators for Moose's built in types.

Some notes:

=over

=item * HashRef and ArrayRef deflate/inflate using JSON

=item * ScalarRef is dereferenced on deflation and returns a reference on inflation

=back

=head1 AUTHOR

Moritz Onken

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut


__END__

