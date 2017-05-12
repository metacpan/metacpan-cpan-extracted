################################################################################
# Copyright (c) 2008 Martin Scharrer <martin@scharrer-online.de>
# This is open source software under the GPL v3 or later.
#
# $Id: Properties.pm 103 2008-10-14 21:11:21Z martin $
################################################################################
package SVN::Dumpfile::Node::Properties;
use IO::File;
use Carp;
use strict;
use warnings;
use Readonly;
Readonly my $NL => chr(10);

our $VERSION = do { '$Rev: 103 $' =~ /\$Rev: (\d+) \$/; '0.13' . ".$1" };

sub new {
    my $class = shift;
    my $self  = bless {
        order    => [],
        property => {},
        deleted  => [],
        unknown  => [],
    }, $class;

    if ( @_ == 1 && ref $_[0] eq 'HASH' ) {
        $self->{'property'} = { %{ $_[0] } };
        @{ $self->{'order'} } = keys %{ $_[0] };
    }
    elsif ( @_ == 1 && ref $_[0] eq 'ARRAY' && @{ $_[0] } % 2 == 0 ) {
        my $i = 0;
        $self->{'property'} = { @{ $_[0] } };
        @{ $self->{'order'} }
            = map { $i++ % 2 ? () : $_ } @{ $_[0] };    # even entries only
    }
    elsif ( @_ % 2 == 0 ) {
        my $i = 0;
        $self->{'property'} = {@_};
        @{ $self->{'order'} }
            = map { $i++ % 2 ? () : $_ } @_;            # even entries only
    }
    elsif ( @_ == 1 && !defined $_[0] ) {

        # Ignore single undef value
    }
    else {
        croak ${class}
            . '::new() awaits hashref or key/value pairs as arguments.';
    }

    return $self;
}

sub number {
    my $self = shift;
    return scalar keys %{ $self->{property} };
}

sub add {
    my ( $self, $prop, $value, $position ) = @_;
    my $order = $self->{order};

    if ( !defined $position || $position > @$order ) {
        $position = @$order;
    }

    my $existed = exists $self->{property}{$prop};
    $self->{property}{$prop} = $value;
    splice @$order, $position, 0, $prop
        if not $existed;
    return $self;
}

sub del {
    my $self = shift;
    my $prop = shift;

    return unless exists $self->{property}{$prop};
    delete $self->{property}{$prop};

    my $order = $self->{order};
    for my $i ( 0 .. $#$order ) {
        if ( $order->[$i] eq $prop ) {
            splice @$order, $i, 1;
            last;
        }
    }
    return $self;
}

sub mark_deleted {
    my $self = shift;
    my $prop = shift;

    $self->del($prop);
    push @{ $self->{deleted} }, $prop;
    return $self;
}

sub unmark_deleted {
    my $self = shift;
    my $prop = shift;

    my $deleted = $self->{deleted};
    for my $i ( 0 .. $#$deleted ) {
        if ( $deleted->[$i] eq $prop ) {
            splice @$deleted, $i, 1;
            last;
        }
    }
    return $self;
}

sub is_deleted {
    my $self = shift;
    my $prop = shift;
    return unless defined $prop;

    foreach my $deleted ( @{ $self->{deleted} } ) {
        return 1 if $deleted eq $prop;
    }
    return;
}

sub list_deleted {
    my $self = shift;

    return @{ $self->{deleted} };
}

sub parse {
    my $self       = shift;
    my $propstrref = shift;    # String in SVN property format to parse

    return unless defined $propstrref and defined $$propstrref;
    return unless ( $$propstrref =~ s/^([A-Z]) (\d+)$NL//o );
    my ( $ident, $length ) = ( $1, $2 );

    my $entry
        = substr( $$propstrref, 0, $length, '' ); # get key with length given by
           # above line and replace it with an null-string
    $$propstrref =~ s/^$NL//o;    # delete trailing new-line

    return ( $ident, $entry );
}

sub from_string {
    my $self      = shift;
    my $propstr   = shift;             # String in SVN property format to parse
    my $prophash  = $self->{property}; # Hash reference to store properties
    my $proporder = $self->{order};    # Array ref. to store order of properties

    return if not defined $propstr;
    my @props;

    # Parse string and save all property entries in array
    while ( my ( $ident, $entry ) = $self->parse( \$propstr ) ) {
        push @props, [ $ident, $entry ];
    }

    for ( my $i = 0; $i < $#props; $i++ ) {
        my ( $ident, $entry ) = @{ $props[$i] };
        if ( $ident eq 'K' ) {
            my ( $ident2, $value ) = @{ $props[ ++$i ] };
            if ( $ident2 eq 'V' ) {
                $self->add( $entry, $value );
            }
        }
        elsif ( $ident eq 'D' ) {
            push @{ $self->{deleted} }, $entry;
        }
        else {
            push @{ $self->{unknown} }, [ $ident, $entry ];
            print STDERR "Error: Found unknown entry in property field:\n",
                "------\n", "${ident}: $entry", "\n";
        }
    }

    if ( not $propstr =~ s/(?:PROPS-)?END$NL\Z//o ) {
        print STDERR "Error at parsing properties at input line $.:",
            "Couldn't understand '$propstr'.\n";
        return 0;
    }

    return scalar @props;
}

sub read {
    use bytes;
    my $self   = shift;
    my $fh     = shift;
    my $length = shift;
    my $str;

    my $ret = eval { $fh->read( $str, $length ) };
    return $ret unless defined $ret and $ret;

    return ( $self->from_string($str) ) ? $ret : undef;
}

sub write {
    my $self = shift;
    my $fh   = shift;

    unless ( eval { $fh->isa('IO::Handle') }
        || ref $fh  eq 'GLOB'
        || ref \$fh eq 'GLOB' )
    {
        croak "Given argument is no valid file handle.";
    }

    return $fh->print( $self->as_string );
}

# Load properties from a file
sub load {
    use bytes;
    my $self = shift;
    my $fr   = shift;    # File handle or name
    my $fh;
    my $str;

    if ( eval { $fr->isa('IO::Handle') } ) {
        $fh = $fr;
    }
    else {
        $fh = IO::File->new( $fr, '<' );
        return unless defined $fh;
    }

    $str = join '', $fh->getlines;
    return unless defined $str and $str ne '';

    return $self->from_string($str);
}

# Save properties to a file
sub save {
    use bytes;
    my $self = shift;
    my $fr   = shift;    # File handle or name
    my $fh;
    my $str;

    if ( eval { $fr->isa('IO::Handle') } ) {
        $fh = $fr;
    }
    else {
        $fh = IO::File->new( $fr, '>' );
        return unless defined $fh;
    }

    return $fh->print( $self->as_string(1) );
}

sub length {
    use bytes;
    return bytes::length shift->as_string;
}

# Returns formatted string in SVN property format
sub as_string {
    use bytes;
    my $self      = shift;
    my $forfile   = shift;             # bool
    my $prophash  = $self->{property}; # Hash reference to store properties
    my $proporder = $self->{order};    # Array ref. to store order of properties
    my $propstr   = '';                # Return string

    # Create check-hash
    my %prop_notprinted = map { $_ => 0 } ( keys %$prophash );

    # Print properties by given order
    foreach my $key (@$proporder) {
        $propstr
            .= 'K '
            . bytes::length($key)
            . $NL
            . $key
            . $NL . 'V '
            . bytes::length( $prophash->{$key} )
            . $NL
            . $prophash->{$key}
            . $NL;
        delete $prop_notprinted{$key};    # printed so delete from check-hash
    }

    # Print now all remaining properties (if any)
    foreach my $key ( sort keys %prop_notprinted ) {
        $propstr
            .= 'K '
            . bytes::length($key)
            . $NL
            . $key
            . $NL . 'V '
            . bytes::length( $prophash->{$key} )
            . $NL
            . $prophash->{$key}
            . $NL;
    }

    # Print list of deleted properties
    foreach my $entry ( @{ $self->{deleted} } ) {
        $propstr .= 'D ' . bytes::length($entry) . $NL . $entry . $NL;
    }
    foreach my $ref ( @{ $self->{unknown} } ) {
        my ( $ident, $entry ) = @$ref;
        $propstr .= "$ident " . bytes::length($entry) . $NL . $entry . $NL;
    }

    $propstr .= ($forfile) ? "END$NL" : "PROPS-END$NL";
    return $propstr;
}

# Alias:
*to_string = \&as_string;

1;
__END__

=head1 NAME

SVN::Dumpfile::Node::Properties - Represents the properties of a node in
a Subversion dumpfile.

=head1 SYNOPSIS

Objects of this class are used in SVN::Dumpfile::Node objects, but can
also be used independently for manipulating Subversion revision property
files.

    use SVN::Dumpfile::Node:Properties;
    my $prop = new SVN::Dumpfile::Node::Properties;
    $prop->load('filename');
    ...
    $prop->save('filename');

=head1 DESCRIPTION, SEE ALSO, AUTHOR, COPYRIGHT

See L<SVN::Dumpfile>.

=head1 METHODS

=over 4

=item new()

Returns a new L<SVN::Dumpfile::Node::Properties|SVN::Dumpfile::Node::Properties>
object. Properties can be given as hash reference, array reference or as a list.
Array or list must be even an hold key/value pairs and must be used if the order
of the given properties should be
maintained.


=item number()

Returns the number of properties.


=item add('property', $value)

=item add('property', $value, $position)

Adds the property with the given value at given position or at the end.
Order of properties is maintained to support the creation of identical output
files.


=item del('property')

Deletes a property from the instance. Note if the properties are written in
differential form the property will retrain its value from the last changed
revision when not written. Use mark_deleted() to mark the property as deleted in
this case.


=item mark_deleted('property')

Marks a property as deleted. This is for differential property blocks which are
only supported in dumpfile version 3 or later.
It automatically calls del() on the property. 


=item unmark_deleted('property')

Unmarks a property as deleted. This is for differential property blocks which 
are only supported in dumpfile version 3 or later.
The property is not added to the node, use add() to do this.


=item is_deleted('property')

Returns if a property is marked as deleted. See also mark_deleted().


=item list_deleted()

Returns an array of all properties currently marked as deleted.
See also L<mark_deleted>.


=item parse($stringref)

Internal method to parse single property format element from string. The
element is removed from the string and returned as (ID, value) pair.


=item from_string('string')

Reads the properties from string by repeatly calling parse().


=item read($filehandle, $length)

Reads <length> bytes from filehandle and parses them as properties by calling
from_string().


=item write($filehandle)

Writes the properties in subversion dumpfile format to the given filehandle.


=item load($filename)

=item load($filehandle)

Loads the properties from a subversion revision property file.


=item save($filename)

=item save($filehandle)

Saves the properties to a subversion revision property file.


=item length()

Returns the length of the string returned by as_string().


=item as_string()

=item as_string(1)

=item to_string()

=item to_string(1)

Returns all properties as one string formatted in the format needed for
subversion dumpfiles. If a true value is given as argument the format is that of
subversion revision property files is used ('END' instead of 'PROPS-END').

=back

