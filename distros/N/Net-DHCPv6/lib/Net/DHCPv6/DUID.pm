#!/usr/bin/false
# ABSTRACT: DUID parse/emit and helper constructors
# PODNAME: Net::DHCPv6::DUID
package Net::DHCPv6::DUID;
$Net::DHCPv6::DUID::VERSION = '0.001';
use strictures 2;
use Carp qw(croak);
use Net::DHCPv6::Constants;
use Net::DHCPv6::X::BadDUID;
use namespace::clean;

sub new {
    my ( $class, %args ) = @_;
    my $type = $args{duid_type} // croak 'Net::DHCPv6::DUID->new: duid_type is required';

    my $self = { duid_type => $type };

    if ( $type == $DUID_LLT ) {
        croak 'DUID-LLT requires link_layer_type, time, and identifier'
            unless defined $args{link_layer_type}
            && defined $args{time}
            && defined $args{identifier};
        $self->{link_layer_type} = $args{link_layer_type};
        $self->{time}            = $args{time};
        $self->{identifier}      = $args{identifier};
    }
    elsif ( $type == $DUID_EN ) {
        croak 'DUID-EN requires enterprise_number and identifier'
            unless defined $args{enterprise_number}
            && defined $args{identifier};
        $self->{enterprise_number} = $args{enterprise_number};
        $self->{identifier}        = $args{identifier};
    }
    elsif ( $type == $DUID_LL ) {
        croak 'DUID-LL requires link_layer_type and identifier'
            unless defined $args{link_layer_type}
            && defined $args{identifier};
        $self->{link_layer_type} = $args{link_layer_type};
        $self->{identifier}      = $args{identifier};
    }
    elsif ( $type == $DUID_UUID ) {
        croak 'DUID-UUID requires identifier (16 bytes)'
            unless defined $args{identifier};
        croak 'DUID-UUID identifier must be 16 bytes'
            unless CORE::length( $args{identifier} ) == 16;
        $self->{identifier} = $args{identifier};
    }
    else {
        $self->{identifier} = $args{identifier} // '';
    }

    bless $self, $class;
}

sub duid_type         { shift->{duid_type} }
sub link_layer_type   { shift->{link_layer_type} }
sub time              { shift->{time} }
sub enterprise_number { shift->{enterprise_number} }
sub identifier        { shift->{identifier} }

sub length {
    my $self = shift;
    my $type = $self->{duid_type};
    my $id   = $self->{identifier} // '';
    if    ( $type == $DUID_LLT )  { return 2 + 2 + 4 + CORE::length( $id ); }
    elsif ( $type == $DUID_EN )   { return 2 + 4 + CORE::length( $id ); }
    elsif ( $type == $DUID_LL )   { return 2 + 2 + CORE::length( $id ); }
    elsif ( $type == $DUID_UUID ) { return 2 + CORE::length( $id ); }
    else                          { return 2 + CORE::length( $id ); }
}

sub as_bytes {
    my $self = shift;
    my $type = $self->{duid_type};
    my $id   = $self->{identifier} // '';
    my $buf  = pack( 'n', $type );

    if ( $type == $DUID_LLT ) {
        $buf .= pack( 'n', $self->{link_layer_type} );
        $buf .= pack( 'N', $self->{time} );
        $buf .= $id;
    }
    elsif ( $type == $DUID_EN ) {
        $buf .= pack( 'N', $self->{enterprise_number} );
        $buf .= $id;
    }
    elsif ( $type == $DUID_LL ) {
        $buf .= pack( 'n', $self->{link_layer_type} );
        $buf .= $id;
    }
    elsif ( $type == $DUID_UUID ) {
        $buf .= $id;
    }
    else {
        $buf .= $id;
    }

    return $buf;
}

sub as_string {
    my $self  = shift;
    my $bytes = $self->as_bytes;
    my $tname = $Net::DHCPv6::Constants::REV_DUID_TYPE{ $self->{duid_type} }
        || sprintf( 'TYPE%d', $self->{duid_type} );
    return sprintf( '%s:%s', $tname, unpack( 'H*', $bytes ) );
}

sub try_from_bytes {
    my ( $class, $bytes ) = @_;
    return ( undef, 'No data provided' ) unless defined $bytes;

    my $len = CORE::length( $bytes );
    return ( undef, 'Need at least 2 bytes for DUID type' ) if $len < 2;

    my $type     = unpack( 'n', substr( $bytes, 0, 2 ) );
    my $rest     = substr( $bytes, 2 );
    my $rest_len = CORE::length( $rest );

    if ( $type == $DUID_LLT ) {
        my $partial = bless( { duid_type => $DUID_LLT }, $class );
        my $error;
        if ( $rest_len >= 2 ) {
            $partial->{link_layer_type} = unpack( 'n', $rest );
            if ( $rest_len >= 6 ) {
                $partial->{time}       = unpack( 'x2 N', $rest );
                $partial->{identifier} = substr( $rest, 6 );
            }
            else {
                $error = "Need 6 bytes for DUID-LLT hwtype+time, got $rest_len";
            }
        }
        else {
            $error = "Need at least 2 bytes for DUID-LLT hwtype, got $rest_len";
        }
        return ( $partial, $error );
    }
    elsif ( $type == $DUID_EN ) {
        my $partial = bless( { duid_type => $DUID_EN }, $class );
        my $error;
        if ( $rest_len >= 4 ) {
            $partial->{enterprise_number} = unpack( 'N', $rest );
            $partial->{identifier}        = substr( $rest, 4 );
        }
        else {
            $error = "Need 4 bytes for DUID-EN enterprise_number, got $rest_len";
        }
        return ( $partial, $error );
    }
    elsif ( $type == $DUID_LL ) {
        my $partial = bless( { duid_type => $DUID_LL }, $class );
        my $error;
        if ( $rest_len >= 2 ) {
            $partial->{link_layer_type} = unpack( 'n', $rest );
            $partial->{identifier}      = substr( $rest, 2 );
        }
        else {
            $error = "Need at least 2 bytes for DUID-LL hwtype, got $rest_len";
        }
        return ( $partial, $error );
    }
    elsif ( $type == $DUID_UUID ) {
        my $partial = bless( { duid_type => $DUID_UUID }, $class );
        my $error;
        if ( $rest_len >= 16 ) {
            $partial->{identifier} = substr( $rest, 0, 16 );
        }
        else {
            $error = "Need 16 bytes for DUID-UUID, got $rest_len";
        }
        return ( $partial, $error );
    }
    else {
        return (
            bless(
                {
                    duid_type  => $type,
                    identifier => $rest,
                },
                $class
            ),
            undef
        );
    }
}

sub from_bytes {
    my ( $class, $bytes ) = @_;
    my ( $duid,  $error ) = $class->try_from_bytes( $bytes );
    Net::DHCPv6::X::BadDUID->throw( message => $error ) if $error;
    return $duid;
}

sub new_llt {
    my ( $class, $link_layer_type, $time, $mac_bytes ) = @_;
    return $class->new(
        duid_type       => $DUID_LLT,
        link_layer_type => $link_layer_type,
        time            => $time,
        identifier      => $mac_bytes,
    );
}

sub new_en {
    my ( $class, $enterprise_number, $identifier ) = @_;
    return $class->new(
        duid_type         => $DUID_EN,
        enterprise_number => $enterprise_number,
        identifier        => $identifier,
    );
}

sub new_ll {
    my ( $class, $link_layer_type, $mac_bytes ) = @_;
    return $class->new(
        duid_type       => $DUID_LL,
        link_layer_type => $link_layer_type,
        identifier      => $mac_bytes,
    );
}

sub new_uuid {
    my ( $class, $uuid_bytes ) = @_;
    return $class->new(
        duid_type  => $DUID_UUID,
        identifier => $uuid_bytes,
    );
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Net::DHCPv6::DUID - DUID parse/emit and helper constructors

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Net::DHCPv6::DUID;

  my $duid = Net::DHCPv6::DUID->new_llt(1, time, "\x00\x11\x22\x33\x44\x55");
  my $bytes = $duid->as_bytes;

  my $parsed = Net::DHCPv6::DUID->from_bytes($bytes);
  print $parsed->duid_type;  # 1

=head1 DESCRIPTION

Parses, constructs, and serializes DHCPv6 Unique Identifiers (DUIDs)
as defined in RFC 8415 §11. Supports DUID-LLT, DUID-EN, DUID-LL, and
DUID-UUID types. Unknown DUID types are stored opaquely.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 CONSTRUCTORS

=head2 new(%params)

Generic constructor. Requires C<duid_type>. Additional required fields
depend on the type:

=over

=item DUID-LLT: C<link_layer_type>, C<time>, C<identifier>

=item DUID-EN: C<enterprise_number>, C<identifier>

=item DUID-LL: C<link_layer_type>, C<identifier>

=item DUID-UUID: C<identifier> (must be exactly 16 bytes)

=item Unknown types: C<identifier> (optional)

=back

=head2 new_llt($link_layer_type, $time, $mac_bytes)

Convenience constructor for DUID-LLT (type 1).

=head2 new_en($enterprise_number, $identifier)

Convenience constructor for DUID-EN (type 2).

=head2 new_ll($link_layer_type, $mac_bytes)

Convenience constructor for DUID-LL (type 3).

=head2 new_uuid($uuid_bytes)

Convenience constructor for DUID-UUID (type 4).

=head2 from_bytes($bytes)

Parse a DUID from its wire-format representation. Reads the 2-byte
type prefix and dispatches to the appropriate parser. Falls back to
opaque storage for unknown types.

=head2 try_from_bytes($bytes)

Attempts to parse a DUID from wire bytes. Returns C<($duid, $error)>.
On truncation, C<$duid> is a partial object with whatever fields
could be decoded before the error, and C<$error> is an error string.
On success, C<$error> is C<undef>.

=head1 ACCESSORS

=over

=item B<duid_type>

=item B<link_layer_type>

=item B<time>

=item B<enterprise_number>

=item B<identifier>

=back

=head1 METHODS

=over

=item B<as_bytes>

Serialize to wire format.

=item B<as_string>

Human-readable representation: C<TYPE:hex>.

=item B<length>

Byte length of the wire-format representation.

=back

=head1 SEE ALSO

L<Net::DHCPv6>, RFC 8415 §11, RFC 6355

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
