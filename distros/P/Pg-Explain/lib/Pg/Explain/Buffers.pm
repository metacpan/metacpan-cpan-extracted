package Pg::Explain::Buffers;

# UTF8 boilerplace, per http://stackoverflow.com/questions/6162484/why-does-modern-perl-avoid-utf-8-by-default/
use v5.18;
use strict;
use warnings;
use warnings qw( FATAL utf8 );
use utf8;
use open qw( :std :utf8 );
use Unicode::Normalize qw( NFC );
use Unicode::Collate;
use Encode qw( decode );

if ( grep /\P{ASCII}/ => @ARGV ) {
    @ARGV = map { decode( 'UTF-8', $_ ) } @ARGV;
}

# UTF8 boilerplace, per http://stackoverflow.com/questions/6162484/why-does-modern-perl-avoid-utf-8-by-default/

use Carp;
use Clone qw( clone );
use autodie;

use overload
    '+'    => \&_buffers_add,
    '-'    => \&_buffers_subtract,
    'bool' => \&_buffers_bool;

=head1 NAME

Pg::Explain::Buffers - Object to store buffers information about node in PostgreSQL's explain analyze

=head1 VERSION

Version 2.2

=cut

our $VERSION = '2.2';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Pg::Explain;

    my $explain = Pg::Explain->new('source_file' => 'some_file.out');
    ...

    if ( $explain->top_node->buffers ) {
        print $explain->top_node->buffers->as_text();
    }
    ...

Alternatively you can build the object itself from either a string (conforming
to text version of EXPLAIN ANALYZE output) or a structure, containing keys like
in JSON/YAML/XML formats of the explain:

    use Pg::Explain::Buffers;

    my $from_string = Pg::Explain::Buffers->new( 'Buffers: shared hit=12101 read=73' );
    my $from_struct = Pg::Explain::Buffers->new( {
        'Shared Hit Blocks' => 12101,
        'Shared Read Blocks' => 73,
    } );

To such object you can later on add Timing information, though only with
string - if you had it in struct, make it available on creation.

    $buffers->add_timing( 'I/O Timings: read=58.316 write=1.672' );

=head1 FUNCTIONS

=head2 new

Object constructor.

Takes one argument, either a string or hashref to build data from.

=cut

sub new {
    my $class = shift;
    my $self  = bless {}, $class;
    croak( 'You have to provide base info.' )                     if 0 == scalar @_;
    croak( 'Too many arguments to Pg::Explain::Buffers->new().' ) if 1 < scalar @_;
    my $arg = shift;
    if ( 'HASH' eq ref $arg ) {
        $self->_build_from_struct( $arg );
    }
    elsif ( '' eq ref $arg ) {
        $self->_build_from_string( $arg );
    }
    else {
        croak( "Don't know how to build Pg::Explain::Buffers using " . ref( $arg ) );
    }
    return $self;
}

=head2 add_timing

Adds timing information to existing buffer info.

Takes one argument, either a string or hashref to build data from.

=cut

sub add_timing {
    my $self = shift;
    croak( 'You have to provide base info.' )                     if 0 == scalar @_;
    croak( 'Too many arguments to Pg::Explain::Buffers->new().' ) if 1 < scalar @_;
    my $arg = shift;
    croak( "Don't know how to add timing info in Pg::Explain::Buffers using " . ref( $arg ) ) unless '' eq ref( $arg );
    croak( "Invalid format of I/O Timing info: $arg" ) unless $arg =~ m{
        \A
        \s*
        I/O \s Timings:
        (
            \s+
            (?: read | write )
            =
            \d+\.\d+
        )+
        \s*
        \z
    }xms;

    my @matching = $arg =~ m{ (read|write) = (\d+\.\d+) }xg;
    return if 0 == scalar @matching;
    my %matching = @matching;
    for my $key ( qw( read write ) ) {
        next unless my $val = $matching{ $key };
        $self->{ 'data' }->{ 'timings' }->{ $key } = $val;
    }
    return;
}

=head2 as_text

Returns text representation of stored buffers info, together with timings (if available).

=cut

sub as_text {
    my $self = shift;
    return unless $self->{ 'data' };
    return if 0 == scalar keys %{ $self->{ 'data' } };
    my @parts = ();
    for my $type ( qw( shared local temp ) ) {
        next unless my $x = $self->{ 'data' }->{ $type };
        my @elements = map { $_ . '=' . $x->{ $_ } } grep { $x->{ $_ } } qw( hit read dirtied written );
        next if 0 == scalar @elements;
        push @parts, join( ' ', $type, @elements );
    }
    return if 0 == scalar @parts;
    my $ret = sprintf 'Buffers: %s', join( ', ', @parts );
    return $ret unless my $T = $self->{ 'data' }->{ 'timings' };
    my $timing = join ' ', map { $_ . '=' . $T->{ $_ } } grep { $T->{ $_ } } qw{ read write };
    return $ret unless $timing;
    return $ret . "\nI/O Timings: " . $timing;
}

=head2 get_struct

Returns hash(ref) with all data about buffers from this object. Keys in this hash:

=over

=item * shared (with subkeys: hit, read, dirtied, written)

=item * local (with subkeys: hit, read, dirtied, written)

=item * temp (with subkeys: read, written)

=item * timings (with subkeys: read, write

=back

Only elements with non-zero values are returned. If there are no elements to be returned, it returns undef.

=cut

sub get_struct {
    my $self = shift;
    my $d    = $self->{ 'data' };
    my $map  = {
        'shared'  => [ qw{ hit read dirtied written } ],
        'local'   => [ qw{ hit read dirtied written } ],
        'temp'    => [ qw{ read written } ],
        'timings' => [ qw{ read write } ],
    };
    my $ret = {};
    while ( my ( $type, $subtypes ) = each %{ $map } ) {
        next unless defined( my $t = $self->{ 'data' }->{ $type } );
        for my $subtype ( @{ $subtypes } ) {
            next unless defined( my $val = $t->{ $subtype } );
            $ret->{ $type }->{ $subtype } = $val;
        }
    }
    return if 0 == scalar keys %{ $ret };
    return $ret;
}

=head2 data

Accessor to internal data.

=cut

sub data {
    my $self = shift;
    $self->{ 'data' } = $_[ 0 ] if 0 < scalar @_;
    return $self->{ 'data' };
}

=head1 OPERATORS

To allow for easier work on buffer values + and - operators are overloaded, so you can:

    $buffers_out = $buffers1 - $buffers2;

While processing subtraction, it is important that it's not possible to get negative values,
so if any value would drop below 0, it will get auto-adjusted to 0.

=cut

=head1 INTERNAL METHODS

=head2 _build_from_struct

Gets data out of provided HASH.

=cut

sub _build_from_struct {
    my $self = shift;
    my $in   = shift;

    my $map = {
        'shared'  => [ qw{ hit read dirtied written } ],
        'local'   => [ qw{ hit read dirtied written } ],
        'temp'    => [ qw{ read written } ],
        'timings' => [ qw{ read write } ],
    };

    while ( my ( $type, $subtypes ) = each %{ $map } ) {
        my $in_type   = $type eq 'timings' ? 'I/O'  : ucfirst( $type );
        my $in_suffix = $type eq 'timings' ? 'Time' : 'Blocks';
        for my $subtype ( @{ $subtypes } ) {
            my $in_subtype = ucfirst( $subtype );
            my $in_key     = join ' ', $in_type, $in_subtype, $in_suffix;
            next unless my $val = $in->{ $in_key };
            next if 0 == $val;
            $self->{ 'data' }->{ $type }->{ $subtype } = $val;
        }
    }

    return;
}

=head2 _build_from_string

Gets data out of provided string.

=cut

sub _build_from_string {
    my $self           = shift;
    my $in             = shift;
    my $single_type_re = qr{
        (?:
                (?: shared | local )
                (?:
                    \s+
                    (?: hit | read | dirtied | written ) = [1-9]\d*
                )+
                |
                temp
                (?:
                    \s+
                    (?: read | written ) = [1-9]\d*
                )+
        )
    }xms;
    croak( 'Invalid format of string for Pg::Explain::Buffers: ' . $in ) unless $in =~ m{
        \A
        \s*
        Buffers:
        \s+
        (
            $single_type_re
            (?:
                , \s+
                $single_type_re
            )*
            )
        \s*
        \z
    }xms;
    my $plain_info = $1;
    my @parts      = split /,\s+/, $plain_info;
    $self->{ 'data' } = {};

    for my $part ( @parts ) {
        my @words = split /\s+/, $part;
        my $type  = shift @words;
        for my $word ( @words ) {
            my ( $op, $bufs ) = split /=/, $word;
            $self->{ 'data' }->{ $type }->{ $op } = $bufs;
        }
    }

    return;
}

=head2 _buffers_add

Creates new Pg::Explain::Buffers object by adding values based on two objects. To be used like:

    my $result = $buffers1 + $buffers2;

=cut

sub _buffers_add {
    my ( $left, $right ) = @_;
    return unless 'Pg::Explain::Buffers' eq ref $left;
    unless ( 'Pg::Explain::Buffers' eq ref $right ) {
        return if defined $right;
        my $res = Pg::Explain::Buffers->new( {} );
        $res->data( clone( $left->data ) );
        return $res;
    }

    my $D   = {};
    my $map = {
        'shared'  => [ qw{ hit read dirtied written } ],
        'local'   => [ qw{ hit read dirtied written } ],
        'temp'    => [ qw{ read written } ],
        'timings' => [ qw{ read write } ],
    };

    my $L = $left->data  ? clone( $left->data )  : {};
    my $R = $right->data ? clone( $right->data ) : {};
    while ( my ( $type, $subtypes ) = each %{ $map } ) {
        for my $subtype ( @{ $subtypes } ) {
            my $val = ( $L->{ $type }->{ $subtype } // 0 ) + ( $R->{ $type }->{ $subtype } // 0 );
            next if $val <= 0;
            $D->{ $type }->{ $subtype } = $val;
        }
    }
    return if 0 == scalar keys %{ $D };

    my $ret = Pg::Explain::Buffers->new( {} );
    $ret->data( $D );
    return $ret;
}

=head2 _buffers_subtract

Creates new Pg::Explain::Buffers object by subtracting values based on two objects. To be used like:

    my $result = $buffers1 - $buffers2;

=cut

sub _buffers_subtract {
    my ( $left, $right ) = @_;
    return unless 'Pg::Explain::Buffers' eq ref $left;
    return unless 'Pg::Explain::Buffers' eq ref $right;

    my $map = {
        'shared'  => [ qw{ hit read dirtied written } ],
        'local'   => [ qw{ hit read dirtied written } ],
        'temp'    => [ qw{ read written } ],
        'timings' => [ qw{ read write } ],
    };

    return unless $left->data;
    unless ( $right->data ) {
        my $res = Pg::Explain::Buffers->new( {} );
        $res->data( clone( $left->data ) );
        return $res;
    }

    my $new_data = {};
    while ( my ( $type, $subtypes ) = each %{ $map } ) {
        next unless my $L = $left->data->{ $type };
        if ( my $R = $right->data->{ $type } ) {
            for my $subtype ( @{ $subtypes } ) {
                my $val = ( $L->{ $subtype } // 0 ) - ( $R->{ $subtype } // 0 );

                # Weirdish comparison to get rid of floating point arithmetic errors, like:
                # 32.874 - 18.153 - 14.721 => 3.5527136788005e-15
                next if $val <= 0.00001;
                $new_data->{ $type }->{ $subtype } = $val;
            }
        }
        else {
            $new_data->{ $type } = clone( $L );
        }
    }
    return if 0 == scalar keys %{ $new_data };

    my $ret = Pg::Explain::Buffers->new( {} );
    $ret->data( $new_data );
    return $ret;
}

=head2 _buffers_bool

For checking if given variable is set, as in:

    $r = $buffers1 - $buffers2;
    if ( $r ) {...}

=cut

sub _buffers_bool {
    my $self = shift;
    return unless $self->data;
    return 0 < scalar keys %{ $self->data };
}

=head1 AUTHOR

hubert depesz lubaczewski, C<< <depesz at depesz.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<depesz at depesz.com>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Pg::Explain::Buffers

=head1 COPYRIGHT & LICENSE

Copyright 2008-2021 hubert depesz lubaczewski, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Pg::Explain::Buffers
